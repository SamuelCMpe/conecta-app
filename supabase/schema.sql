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
  primary key (viewer_id, owner_id)
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

-- Crea un código QR nuevo para mí (dura 40 s: 30 visibles + 10 de margen).
create or replace function public.create_qr_token()
returns table (token text, expires_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare
  v_token text := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  v_exp timestamptz := now() + interval '40 seconds';
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  delete from qr_tokens q where q.owner_id = auth.uid() and q.expires_at < now();
  insert into qr_tokens (token, owner_id, expires_at) values (v_token, auth.uid(), v_exp);
  return query select v_token, v_exp;
end $$;

-- Escaneo el QR de otra persona: los dos pasamos a ver el perfil del otro al instante.
-- (Mostrar el QR es el permiso de quien lo muestra; escanearlo es el permiso de quien escanea.)
create or replace function public.redeem_qr_token(p_token text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_profile jsonb;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select q.owner_id into v_owner from qr_tokens q where q.token = p_token and q.expires_at > now();
  if v_owner is null then raise exception 'qr expired'; end if;
  if v_owner = auth.uid() then raise exception 'own qr'; end if;

  insert into access (viewer_id, owner_id, status) values (auth.uid(), v_owner, 'active')
  on conflict (viewer_id, owner_id) do update set status = 'active', created_at = now();

  insert into access (viewer_id, owner_id, status) values (v_owner, auth.uid(), 'active')
  on conflict (viewer_id, owner_id) do update set status = 'active', created_at = now();

  select to_jsonb(p) into v_profile from profiles p where p.id = v_owner;
  return coalesce(v_profile, jsonb_build_object('id', v_owner));
end $$;

-- Mis contactos: las personas cuyo perfil puedo ver.
create or replace function public.my_contacts()
returns table (profile jsonb, relation text, since timestamptz, revoked boolean)
language sql security definer set search_path = public stable as $$
  select
    to_jsonb(p),
    case when back.status in ('active', 'revoked') then 'mutuo' else 'escaneaste' end,
    a.created_at,
    coalesce(back.status = 'revoked', false)
  from access a
  join profiles p on p.id = a.owner_id
  left join access back on back.viewer_id = a.owner_id and back.owner_id = a.viewer_id
  where a.viewer_id = auth.uid() and a.status = 'active'
  order by a.created_at desc;
$$;

-- Personas que escanearon mi QR y me enviaron su perfil (vista previa: nombre, foto y estilo).
create or replace function public.my_requests()
returns table (profile jsonb, at timestamptz)
language sql security definer set search_path = public stable as $$
  select
    jsonb_build_object('id', p.id, 'display_name', p.display_name, 'avatar_url', p.avatar_url, 'style', p.style),
    a.created_at
  from access a
  join profiles p on p.id = a.owner_id
  where a.viewer_id = auth.uid() and a.status = 'pending'
  order by a.created_at desc;
$$;

create or replace function public.respond_request(p_from uuid, p_accept boolean)
returns void
language sql security definer set search_path = public as $$
  update access set status = case when p_accept then 'active' else 'rejected' end
  where viewer_id = auth.uid() and owner_id = p_from and status = 'pending';
$$;

-- Quitar (o devolver) a alguien el acceso a mi perfil.
create or replace function public.set_access_revoked(p_viewer uuid, p_revoked boolean)
returns void
language sql security definer set search_path = public as $$
  update access set status = case when p_revoked then 'revoked' else 'active' end
  where owner_id = auth.uid() and viewer_id = p_viewer and status in ('active', 'revoked');
$$;

-- ============ Fotos (perfil y fondo) ============
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
