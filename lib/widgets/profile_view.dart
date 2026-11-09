import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/networks.dart';
import '../models/profile.dart';
import '../theme/profile_look.dart';
import 'common.dart';

/// Muestra un perfil completo con su diseño. Se usa para "Mi perfil" y para
/// el perfil de otra persona después de escanear su QR.
class ProfileView extends StatelessWidget {
  final Profile profile;
  final Widget? topBar;
  final List<Widget> footer;
  const ProfileView({super.key, required this.profile, this.topBar, this.footer = const []});

  Future<void> _open(BuildContext context, String? link) async {
    if (link == null) return;
    final ok = await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showError(context, 'No se pudo abrir $link');
  }

  @override
  Widget build(BuildContext context) {
    final look = ProfileLook(profile.style);
    final nets = profile.networks.map(networkById).toList();
    final handle = [
      if (profile.username.isNotEmpty) '@${profile.username.replaceFirst('@', '')}',
      if (profile.city.isNotEmpty) profile.city,
    ].join(' · ');

    return ProfileBackground(
      style: profile.style,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (topBar != null) topBar!,
            const SizedBox(height: 20),
            Center(child: Avatar(profile: profile)),
            const SizedBox(height: 12),
            Text(profile.displayName.isEmpty ? 'Tu nombre' : profile.displayName,
                textAlign: TextAlign.center, style: look.titleFont(size: 30)),
            if (handle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(handle, textAlign: TextAlign.center, style: TextStyle(color: look.subtext, fontSize: 14)),
            ],
            if (profile.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(profile.bio,
                  textAlign: TextAlign.center, style: TextStyle(color: look.text, fontSize: 15, height: 1.45)),
            ],
            if (profile.interests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in profile.interests)
                    Glass(
                      color: look.glass,
                      border: Border.all(color: look.glassBorder),
                      radius: 999,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(g, style: TextStyle(color: look.text, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            for (final n in nets) ...[
              _LinkRow(
                look: look,
                leading: NetworkBadge(network: n, size: 40),
                title: n.label,
                subtitle: _pretty(profile.socials[n.id]),
                onTap: () => _open(context, n.linkFor(profile.socials[n.id])),
              ),
              const SizedBox(height: 10),
            ],
            if (profile.featuredEnabled && profile.featuredUrl.isNotEmpty)
              _LinkRow(
                look: look,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: look.accent, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.link, color: look.onAccent),
                ),
                title: profile.featuredTitle.isEmpty ? 'Mi enlace' : profile.featuredTitle,
                subtitle: _pretty(profile.featuredUrl),
                onTap: () {
                  final u = profile.featuredUrl;
                  _open(context, u.startsWith('http') ? u : 'https://$u');
                },
              ),
            const SizedBox(height: 20),
            ...footer,
          ],
        ),
      ),
    );
  }
}

/// Quita "https://" y "www." para mostrar el enlace o usuario más limpio.
String _pretty(String? raw) {
  var v = (raw ?? '').trim();
  v = v.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'^www\.'), '');
  return v.replaceAll(RegExp(r'/+$'), '');
}

/// Botón largo de una red: ícono, nombre, usuario y flecha.
class _LinkRow extends StatelessWidget {
  final ProfileLook look;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.look, required this.leading, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final btn = look.button;
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          color: btn.bg,
          border: btn.border,
          blur: btn.blur,
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: btn.fg, fontSize: 15, fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: btn.fg.withValues(alpha: 0.75), fontSize: 12)),
              ]),
            ),
            Icon(Icons.chevron_right, color: btn.fg),
          ]),
        ),
      ),
    );
  }
}
