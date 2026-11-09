import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/networks.dart';
import '../models/profile.dart';
import '../theme/profile_look.dart';

/// Caja translúcida con desenfoque detrás ("vidrio").
class Glass extends StatelessWidget {
  final Widget child;
  final Color color;
  final Border? border;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool blur;
  const Glass({
    super.key,
    required this.child,
    required this.color,
    this.border,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(color: color, border: border, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
    if (!blur) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: box),
    );
  }
}

/// Foto de perfil con su forma y aro.
class Avatar extends StatelessWidget {
  final Profile profile;
  final double size;
  final ProfileStyle? styleOverride;
  const Avatar({super.key, required this.profile, this.size = 108, this.styleOverride});

  @override
  Widget build(BuildContext context) {
    final style = styleOverride ?? profile.style;
    final look = ProfileLook(style);
    final ring = ringOptions(look.accent)[style.ring.clamp(0, 4)];
    final r = size * look.avatarRadiusFactor;
    final url = profile.avatarUrl;
    ImageProvider? img;
    if (url != null && url.isNotEmpty) {
      img = url.startsWith('http') ? NetworkImage(url) : FileImage(File(url)) as ImageProvider;
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: ring.gradient,
        color: ring.color,
        borderRadius: BorderRadius.circular(r + 4),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A24),
          borderRadius: BorderRadius.circular(r),
          image: img == null ? null : DecorationImage(image: img, fit: BoxFit.cover),
        ),
        alignment: Alignment.center,
        child:
            img == null ? Text(profile.initials, style: look.titleFont(size: size * 0.36, color: Colors.white)) : null,
      ),
    );
  }
}

/// Cuadrito de color con el ícono o las iniciales de la red.
class NetworkBadge extends StatelessWidget {
  final Network network;
  final double size;
  const NetworkBadge({super.key, required this.network, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: network.gradient == null ? network.color : null,
        gradient: network.gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: network.icon != null
          ? Icon(network.icon, color: network.foreground, size: size * 0.55)
          : Text(network.abbr,
              style: TextStyle(color: network.foreground, fontWeight: FontWeight.w800, fontSize: size * 0.32)),
    );
  }
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
}
