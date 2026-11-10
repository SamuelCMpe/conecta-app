-- Esquema de la base de datos para QR Conecta.
-- Pégalo completo en Supabase > SQL Editor > New query > Run.

-- ============ Perfiles ============
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text not null default '',
  username text unique,
  city text not null default '',
  bio text not null default '' check (char_length(bio) <= 120),
  interests text[] not null default '{}',
  avatar_url text,
  style jsonb not null default '{}',
  networks text[] not null default '{wa,ig,fb}',
  socials jsonb not null default '{}',
  featured_enabled boolean not null default false,
  featured_title text not null default '',
  featured_url text not null default '',
  updated_at timestamptz not null default now()
);

-- ============ Quién puede ver a quién ============
-- viewer_id puede ver el perfil de owner_id cuando status = 'active'.
create table if not exists public.access (
  viewer_id uuid not null references auth.users on delete cascade,
  owner_id uuid not null references auth.users on delete cascade,
  status text not null check (status in ('active', 'pending', 'revoked', 'rejected')),
  created_at timestamptz not null default now(),
  -- Dónde se conocieron y la foto juntos (iguales en las dos filas de la pareja)
  place text not null default '',
  lat double precision,
  lng double precision,
  selfie_url text,
  primary key (viewer_id, owner_id)
);
alter table public.access add column if not exists place text not null default '';
alter table public.access add column if not exists lat double precision;
alter table public.access add column if not exists lng double precision;
alter table public.access add column if not exists selfie_url text;

-- ============ Notas privadas (solo las ve quien las escribe) ============
create table if not exists public.contact_notes (
  author_id uuid not null references auth.users on delete cascade,
  about_id uuid not null references auth.users on delete cascade,
  note text not null default '' check (char_length(note) <= 300),
  primary key (author_id, about_id)
);

-- ============ Cerca de ti ============
-- Quién tiene "Visible" activado, dónde y hasta cuándo (2 horas).
create table if not exists public.presence (
  user_id uuid primary key references auth.users on delete cascade,
  place text not null default '',
  lat double precision not null,
  lng double precision not null,
  visible_until timestamptz not null
);
create table if not exists public.waves (
  from_id uuid not null references auth.users on delete cascade,
  to_id uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  primary key (from_id, to_id)
);
create table if not exists public.blocks (
  blocker_id uuid not null references auth.users on delete cascade,
  blocked_id uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);
create table if not exists public.reports (
  id bigint generated always as identity primary key,
  reporter_id uuid not null references auth.users on delete cascade,
  reported_id uuid not null references auth.users on delete cascade,
  reason text not null default '',
  created_at timestamptz not null default now()
);

-- ============ Límites contra abuso ============
create table if not exists public.rate_events (
  user_id uuid not null references auth.users on delete cascade,
  kind text not null,
  at timestamptz not null default now()
);
create index if not exists rate_events_idx on public.rate_events (user_id, kind, at);

-- ============ Avisos (te saludaron, te escanearon, se unieron a tu grupo) ============
create table if not exists public.activity (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users on delete cascade,  -- quien recibe el aviso
  actor_id uuid not null references auth.users on delete cascade,
  kind text not null check (kind in ('wave', 'connect', 'group')),
  created_at timestamptz not null default now()
);
create index if not exists activity_user_idx on public.activity (user_id, id);

-- ============ Modo grupo: un QR para que todo el grupo se conecte ============
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  token text not null unique,
  owner_id uuid not null references auth.users on delete cascade,
  place text not null default '',
  lat double precision,
  lng double precision,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create table if not exists public.group_members (
  group_id uuid not null references public.groups on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- ============ Códigos QR que caducan ============
create table if not exists public.qr_tokens (
  token text primary key,
  owner_id uuid not null references auth.users on delete cascade,
  expires_at timestamptz not null
);
create index if not exists qr_tokens_owner_idx on public.qr_tokens (owner_id);

-- ============ Seguridad (RLS) ============
alter table public.profiles enable row level security;
alter table public.access enable row level security;
alter table public.qr_tokens enable row level security; -- sin políticas: solo se usa desde funciones
alter table public.contact_notes enable row level security; -- solo desde funciones
alter table public.presence enable row level security;      -- solo desde funciones (nadie lee ubicaciones directo)
alter table public.waves enable row level security;         -- solo desde funciones
alter table public.blocks enable row level security;        -- solo desde funciones
alter table public.reports enable row level security;       -- solo desde funciones
alter table public.rate_events enable row level security;   -- solo desde funciones
alter table public.activity enable row level security;      -- solo desde funciones
alter table public.groups enable row level security;        -- solo desde funciones
alter table public.group_members enable row level security; -- solo desde funciones

drop policy if exists "ver mi perfil o los que me compartieron" on public.profiles;
create policy "ver mi perfil o los que me compartieron" on public.profiles
  for select using (
    id = auth.uid()
    or exists (
      select 1 from public.access a
      where a.viewer_id = auth.uid() and a.owner_id = profiles.id and a.status = 'active'
    )
  );

drop policy if exists "crear mi perfil" on public.profiles;
create policy "crear mi perfil" on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists "editar mi perfil" on public.profiles;
create policy "editar mi perfil" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "ver mis accesos" on public.access;
create policy "ver mis accesos" on public.access
  for select using (viewer_id = auth.uid() or owner_id = auth.uid());

-- ============ Funciones ============

-- Corta si alguien hace demasiadas veces lo mismo en poco tiempo.
create or replace function public._rate(p_kind text, p_max int, p_window interval)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if (select count(*) from rate_events r
      where r.user_id = auth.uid() and r.kind = p_kind and r.at > now() - p_window) >= p_max then
    raise exception 'too many';
  end if;
  insert into rate_events (user_id, kind) values (auth.uid(), p_kind);
  delete from rate_events r where r.user_id = auth.uid() and r.at < now() - interval '2 days';
end $$;
revoke all on function public._rate(text, int, interval) from public, anon, authenticated;

-- Crea un aviso para otra persona (se borran solos a los 7 días).
create or replace function public._notify(p_to uuid, p_kind text)
returns void language sql security definer set search_path = public as $$
  delete from activity a where a.user_id = p_to and a.created_at < now() - interval '7 days';
  insert into activity (user_id, actor_id, kind)
  select p_to, auth.uid(), p_kind
  where p_to <> auth.uid()
    and not exists (select 1 from blocks b where b.blocker_id = p_to and b.blocked_id = auth.uid());
$$;
revoke all on function public._notify(uuid, text) from public, anon, authenticated;

-- Crea un código QR nuevo para mí (dura 40 s: 30 visibles + 10 de margen).
create or replace function public.create_qr_token()
returns table (token text, expires_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare
  v_token text := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  v_exp timestamptz := now() + interval '40 seconds';
begin
  perform _rate('qr', 200, interval '1 hour');
  delete from qr_tokens q where q.owner_id = auth.uid() and q.expires_at < now();
  insert into qr_tokens (token, owner_id, expires_at) values (v_token, auth.uid(), v_exp);
  return query select v_token, v_exp;
end $$;

-- Escaneo el QR de otra persona: los dos pasamos a ver el perfil del otro al instante
-- y queda guardado dónde se conocieron.
-- (Mostrar el QR es el permiso de quien lo muestra; escanearlo es el permiso de quien escanea.)
drop function if exists public.redeem_qr_token(text);
create or replace function public.redeem_qr_token(
  p_token text, p_place text default '', p_lat double precision default null, p_lng double precision default null)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_profile jsonb;
begin
  perform _rate('scan', 40, interval '1 hour');
  select q.owner_id into v_owner from qr_tokens q where q.token = p_token and q.expires_at > now();
  if v_owner is null then raise exception 'qr expired'; end if;
  if v_owner = auth.uid() then raise exception 'own qr'; end if;
  if exists (select 1 from blocks b where (b.blocker_id = v_owner and b.blocked_id = auth.uid())
                                       or (b.blocker_id = auth.uid() and b.blocked_id = v_owner)) then
    raise exception 'blocked';
  end if;

  insert into access (viewer_id, owner_id, status, place, lat, lng)
  values (auth.uid(), v_owner, 'active', coalesce(p_place, ''), p_lat, p_lng)
  on conflict (viewer_id, owner_id) do update
    set status = 'active', created_at = now(), place = excluded.place, lat = excluded.lat, lng = excluded.lng;

  insert into access (viewer_id, owner_id, status, place, lat, lng)
  values (v_owner, auth.uid(), 'active', coalesce(p_place, ''), p_lat, p_lng)
  on conflict (viewer_id, owner_id) do update
    set status = 'active', created_at = now(), place = excluded.place, lat = excluded.lat, lng = excluded.lng;

  perform _notify(v_owner, 'connect');

  select to_jsonb(p) into v_profile from profiles p where p.id = v_owner;
  return coalesce(v_profile, jsonb_build_object('id', v_owner));
end $$;

-- Mi muro: las personas cuyo perfil puedo ver, con dónde nos conocimos, la foto juntos y mi nota.
drop function if exists public.my_contacts();
create or replace function public.my_contacts()
returns table (profile jsonb, relation text, since timestamptz, revoked boolean,
               place text, lat double precision, lng double precision, selfie_url text, note text)
language sql security definer set search_path = public stable as $$
  select
    to_jsonb(p),
    case when back.status in ('active', 'revoked') then 'mutuo' else 'escaneaste' end,
    a.created_at,
    coalesce(back.status = 'revoked', false),
    a.place, a.lat, a.lng, a.selfie_url,
    coalesce(n.note, '')
  from access a
  join profiles p on p.id = a.owner_id
  left join access back on back.viewer_id = a.owner_id and back.owner_id = a.viewer_id
  left join contact_notes n on n.author_id = auth.uid() and n.about_id = a.owner_id
  where a.viewer_id = auth.uid() and a.status = 'active'
    and not exists (select 1 from blocks b where b.blocker_id = auth.uid() and b.blocked_id = a.owner_id)
  order by a.created_at desc;
$$;

-- Quitar (o devolver) a alguien el acceso a mi perfil.
create or replace function public.set_access_revoked(p_viewer uuid, p_revoked boolean)
returns void
language sql security definer set search_path = public as $$
  update access set status = case when p_revoked then 'revoked' else 'active' end
  where owner_id = auth.uid() and viewer_id = p_viewer and status in ('active', 'revoked');
$$;

-- Solo si ya nos conocimos (hay acceso en algún sentido).
create or replace function public._we_met(p_other uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (select 1 from access a
                 where (a.viewer_id = auth.uid() and a.owner_id = p_other)
                    or (a.viewer_id = p_other and a.owner_id = auth.uid()));
$$;

create or replace function public.save_note(p_about uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not _we_met(p_about) then raise exception 'not a contact'; end if;
  insert into contact_notes (author_id, about_id, note) values (auth.uid(), p_about, coalesce(p_note, ''))
  on conflict (author_id, about_id) do update set note = excluded.note;
end $$;

-- Foto juntos y lugar: se guardan en las dos filas, así los dos lo ven igual.
create or replace function public.save_meet(p_other uuid, p_selfie_url text default null, p_place text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not _we_met(p_other) then raise exception 'not a contact'; end if;
  update access set
    selfie_url = coalesce(p_selfie_url, selfie_url),
    place = coalesce(p_place, place)
  where (viewer_id = auth.uid() and owner_id = p_other) or (viewer_id = p_other and owner_id = auth.uid());
end $$;

-- "Visible" por 2 horas (p_lat null = apagar).
create or replace function public.set_visible(p_place text, p_lat double precision, p_lng double precision)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if p_lat is null or p_lng is null then
    delete from presence where user_id = auth.uid();
    delete from waves where from_id = auth.uid() or to_id = auth.uid();
    return;
  end if;
  perform _rate('visible', 30, interval '1 hour');
  insert into presence (user_id, place, lat, lng, visible_until)
  values (auth.uid(), coalesce(p_place, ''), p_lat, p_lng, now() + interval '2 hours')
  on conflict (user_id) do update
    set place = excluded.place, lat = excluded.lat, lng = excluded.lng, visible_until = excluded.visible_until;
end $$;

-- Gente visible a menos de ~300 m. Solo puede verla quien también está visible.
-- Devuelve solo nombre, foto y un sticker: nunca redes ni ubicación.
create or replace function public.nearby(p_lat double precision, p_lng double precision)
returns table (id uuid, first_name text, avatar_url text, sticker text, waved_at_me boolean, i_waved boolean)
language sql security definer set search_path = public stable as $$
  select
    p.id,
    split_part(p.display_name, ' ', 1),
    p.avatar_url,
    coalesce(p.style -> 'stickers' ->> 0, ''),
    exists (select 1 from waves w where w.from_id = p.id and w.to_id = auth.uid()),
    exists (select 1 from waves w where w.from_id = auth.uid() and w.to_id = p.id)
  from presence pr
  join profiles p on p.id = pr.user_id
  where exists (select 1 from presence me where me.user_id = auth.uid() and me.visible_until > now())
    and pr.user_id <> auth.uid()
    and pr.visible_until > now()
    and 6371000 * sqrt(power(radians(pr.lat - p_lat), 2)
          + power(radians(pr.lng - p_lng) * cos(radians(p_lat)), 2)) < 300
    and not exists (select 1 from blocks b where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                                              or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
  limit 50;
$$;

create or replace function public.send_wave(p_to uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from presence where user_id = auth.uid() and visible_until > now()) then
    raise exception 'not visible';
  end if;
  perform _rate('wave', 30, interval '1 hour');
  if exists (select 1 from blocks b where b.blocker_id = p_to and b.blocked_id = auth.uid()) then return; end if;
  -- Solo a gente que de verdad está visible ahora.
  if not exists (select 1 from presence where user_id = p_to and visible_until > now()) then return; end if;
  if exists (select 1 from waves w where w.from_id = auth.uid() and w.to_id = p_to) then return; end if;
  insert into waves (from_id, to_id) values (auth.uid(), p_to);
  perform _notify(p_to, 'wave');
end $$;

-- Bloquear: pierde el acceso a mi perfil, desaparece de mi muro y de Cerca de ti.
create or replace function public.block_user(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into blocks (blocker_id, blocked_id) values (auth.uid(), p_id) on conflict do nothing;
  update access set status = 'revoked' where owner_id = auth.uid() and viewer_id = p_id;
  delete from waves where (from_id = p_id and to_id = auth.uid()) or (from_id = auth.uid() and to_id = p_id);
end $$;

drop function if exists public.report_user(uuid, text);
create or replace function public.report_user(p_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform _rate('report', 10, interval '1 day');
  insert into reports (reporter_id, reported_id, reason) values (auth.uid(), p_id, left(coalesce(p_reason, ''), 500));
end $$;

-- Mis avisos nuevos (después del último que ya vi).
create or replace function public.my_activity(p_after bigint default 0)
returns table (id bigint, kind text, actor_id uuid, first_name text, avatar_url text, created_at timestamptz)
language sql security definer set search_path = public stable as $$
  select a.id, a.kind, a.actor_id, split_part(coalesce(p.display_name, ''), ' ', 1), p.avatar_url, a.created_at
  from activity a left join profiles p on p.id = a.actor_id
  where a.user_id = auth.uid() and a.id > coalesce(p_after, 0)
    and not exists (select 1 from blocks b where b.blocker_id = auth.uid() and b.blocked_id = a.actor_id)
  order by a.id
  limit 30;
$$;

-- ---------- Modo grupo ----------
-- Creo un QR de grupo (dura 3 horas). Todos los que lo escaneen quedan conectados entre sí.
create or replace function public.create_group(
  p_place text default '', p_lat double precision default null, p_lng double precision default null)
returns table (token text, expires_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_token text := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  v_exp timestamptz := now() + interval '3 hours';
begin
  perform _rate('group', 10, interval '1 day');
  update groups g set expires_at = now() where g.owner_id = auth.uid() and g.expires_at > now();
  insert into groups (token, owner_id, place, lat, lng, expires_at)
  values (v_token, auth.uid(), coalesce(p_place, ''), p_lat, p_lng, v_exp) returning id into v_id;
  insert into group_members (group_id, user_id) values (v_id, auth.uid());
  return query select v_token, v_exp;
end $$;

-- Cuántos hay en mi grupo (solo lo ve quien es parte).
create or replace function public.group_size(p_token text)
returns int language sql security definer set search_path = public stable as $$
  select count(*)::int from group_members m join groups g on g.id = m.group_id
  where g.token = p_token
    and exists (select 1 from group_members me where me.group_id = g.id and me.user_id = auth.uid());
$$;

create or replace function public.end_group(p_token text)
returns void language sql security definer set search_path = public as $$
  update groups set expires_at = least(expires_at, now()) where token = p_token and owner_id = auth.uid();
$$;

-- Me uno: quedo conectado con todos los que ya están (y ellos conmigo). Máximo 50 personas.
create or replace function public.join_group(
  p_token text, p_place text default '', p_lat double precision default null, p_lng double precision default null)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  g groups%rowtype;
  m record;
  v_place text;
begin
  perform _rate('join', 10, interval '1 hour');
  select * into g from groups where token = p_token and expires_at > now();
  if g.id is null then raise exception 'qr expired'; end if;
  if g.owner_id = auth.uid() then raise exception 'own qr'; end if;
  if (select count(*) from group_members where group_id = g.id) >= 50 then raise exception 'group full'; end if;
  v_place := coalesce(nullif(p_place, ''), g.place);

  insert into group_members (group_id, user_id) values (g.id, auth.uid()) on conflict do nothing;

  for m in
    select gm.user_id from group_members gm
    where gm.group_id = g.id and gm.user_id <> auth.uid()
      and not exists (select 1 from blocks b where (b.blocker_id = gm.user_id and b.blocked_id = auth.uid())
                                                or (b.blocker_id = auth.uid() and b.blocked_id = gm.user_id))
  loop
    insert into access (viewer_id, owner_id, status, place, lat, lng)
    values (auth.uid(), m.user_id, 'active', v_place, coalesce(p_lat, g.lat), coalesce(p_lng, g.lng))
    on conflict (viewer_id, owner_id) do update
      set status = 'active', place = excluded.place, lat = excluded.lat, lng = excluded.lng;
    insert into access (viewer_id, owner_id, status, place, lat, lng)
    values (m.user_id, auth.uid(), 'active', v_place, coalesce(p_lat, g.lat), coalesce(p_lng, g.lng))
    on conflict (viewer_id, owner_id) do update
      set status = 'active', place = excluded.place, lat = excluded.lat, lng = excluded.lng;
    perform _notify(m.user_id, 'group');
  end loop;

  return coalesce((
    select jsonb_agg(to_jsonb(p))
    from group_members gm join profiles p on p.id = gm.user_id
    where gm.group_id = g.id and gm.user_id <> auth.uid()
      and not exists (select 1 from blocks b where (b.blocker_id = gm.user_id and b.blocked_id = auth.uid())
                                                or (b.blocker_id = auth.uid() and b.blocked_id = gm.user_id))
  ), '[]'::jsonb);
end $$;

-- ============ Fotos (perfil y selfies) ============
insert into storage.buckets (id, name, public) values ('media', 'media', true)
on conflict (id) do nothing;

drop policy if exists "subir a mi carpeta" on storage.objects;
create policy "subir a mi carpeta" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "borrar de mi carpeta" on storage.objects;
create policy "borrar de mi carpeta" on storage.objects
  for delete to authenticated
  using (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);
