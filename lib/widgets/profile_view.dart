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
    final btn = look.button;
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
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                for (final n in nets)
                  GestureDetector(
                    onTap: () => _open(context, n.linkFor(profile.socials[n.id])),
                    child: Glass(
                      color: btn.bg,
                      border: btn.border,
                      blur: btn.blur,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NetworkBadge(network: n),
                          const SizedBox(height: 8),
                          Text(n.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: btn.fg, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (profile.featuredEnabled && profile.featuredUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  final u = profile.featuredUrl;
                  _open(context, u.startsWith('http') ? u : 'https://$u');
                },
                child: Glass(
                  color: btn.bg,
                  border: btn.border,
                  blur: btn.blur,
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: look.accent, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.link, color: look.onAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(profile.featuredTitle.isEmpty ? 'Mi enlace' : profile.featuredTitle,
                          style: TextStyle(color: btn.fg, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right, color: btn.fg),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ...footer,
          ],
        ),
      ),
    );
  }
}
