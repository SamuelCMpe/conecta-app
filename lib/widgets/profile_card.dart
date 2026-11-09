import 'package:flutter/material.dart';

import '../models/networks.dart';
import '../models/profile.dart';
import '../services/links.dart';
import '../theme/polaroid.dart';

/// La polaroid grande de un perfil con sus stickers alrededor.
class ProfilePolaroid extends StatelessWidget {
  final Profile profile;
  final double width;
  final String? photoUrl;
  final String? caption;
  final VoidCallback? onTap;
  const ProfilePolaroid({super.key, required this.profile, this.width = 260, this.photoUrl, this.caption, this.onTap});

  /// Dónde va cada sticker (esquina, corrimiento y giro).
  static const _spots = [
    (Alignment.topRight, Offset(-4, -14), 12.0),
    (Alignment.bottomLeft, Offset(0, -64), -11.0),
    (Alignment.centerRight, Offset(0, 40), 8.0),
  ];

  @override
  Widget build(BuildContext context) {
    final first = profile.displayName.trim().split(' ').first;
    final stickers = profile.style.stickers.take(3).toList();
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width + 40,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Polaroid(
            width: width,
            angle: -3,
            frame: profile.style.frame,
            caption: caption ?? (first.isEmpty ? 'Tu nombre' : '$first ✌️'),
            photo: PhotoBox(url: photoUrl ?? profile.avatarUrl, name: profile.displayName, id: profile.id),
          ),
          for (var i = 0; i < stickers.length; i++)
            Positioned.fill(
              child: Align(
                alignment: _spots[i].$1,
                child: Transform.translate(
                  offset: _spots[i].$2,
                  child: Sticker(stickers[i], color: [1, 0, 2][i], angle: _spots[i].$3),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Bio, gustos y botones redondos de las redes.
class ProfileDetails extends StatelessWidget {
  final Profile profile;
  const ProfileDetails({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final nets = profile.networks.map(networkById).toList();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (profile.bio.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(profile.bio,
              textAlign: TextAlign.center, style: body(15.5, color: const Color(0xFFE8E6EE), height: 1.4)),
        ),
      if (profile.interests.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final g in profile.interests) Pill(g),
        ]),
      ],
      if (nets.isNotEmpty) ...[
        const SizedBox(height: 20),
        Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 14, children: [
          for (final n in nets)
            NetCircle(network: n, angle: tiltFor(n.id, max: 7), onTap: () => openNetwork(context, profile, n)),
        ]),
      ],
    ]);
  }
}
