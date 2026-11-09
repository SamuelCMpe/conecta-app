import 'package:flutter/material.dart';

/// Una red social o forma de contacto que se puede compartir.
class Network {
  final String id;
  final String label;
  final String abbr;
  final IconData? icon;
  final Color color;
  final Gradient? gradient;
  final Color foreground;
  final String fieldLabel;
  final String hint;
  final TextInputType keyboard;
  final String Function(String value) _build;

  const Network({
    required this.id,
    required this.label,
    required this.abbr,
    this.icon,
    required this.color,
    this.gradient,
    required this.foreground,
    required this.fieldLabel,
    required this.hint,
    this.keyboard = TextInputType.text,
    required String Function(String value) build,
  }) : _build = build;

  /// Arma el enlace a partir de lo que escribió la persona
  /// (acepta número, usuario con o sin @, o el enlace completo).
  String? linkFor(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    return _build(v);
  }
}

String _stripTo(String v, String domain) {
  final i = v.indexOf(domain);
  var out = i >= 0 ? v.substring(i + domain.length) : v;
  out = out.replaceFirst(RegExp(r'^/+'), '').replaceFirst(RegExp(r'^@'), '');
  return out.split('?').first.replaceAll(RegExp(r'/+$'), '');
}

final List<Network> kNetworks = [
  Network(
    id: 'wa',
    label: 'WhatsApp',
    abbr: 'WA',
    icon: Icons.chat_bubble_outline,
    color: const Color(0xFF25D366),
    foreground: const Color(0xFF08311A),
    fieldLabel: 'Número de WhatsApp (con código de país)',
    hint: '+51 999 999 999',
    keyboard: TextInputType.phone,
    build: (v) => 'https://wa.me/${v.replaceAll(RegExp(r'[^0-9]'), '')}',
  ),
  Network(
    id: 'ig',
    label: 'Instagram',
    abbr: 'IG',
    icon: Icons.camera_alt_outlined,
    color: const Color(0xFFDD2A7B),
    gradient: const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
    ),
    foreground: Colors.white,
    fieldLabel: 'Usuario de Instagram',
    hint: '@tu.usuario',
    build: (v) => 'https://instagram.com/${_stripTo(v, 'instagram.com')}',
  ),
  Network(
    id: 'fb',
    label: 'Facebook',
    abbr: 'f',
    icon: Icons.facebook,
    color: const Color(0xFF1877F2),
    foreground: Colors.white,
    fieldLabel: 'Enlace o usuario de Facebook',
    hint: 'facebook.com/tu.perfil',
    build: (v) => 'https://facebook.com/${_stripTo(v, 'facebook.com')}',
  ),
  Network(
    id: 'tk',
    label: 'TikTok',
    abbr: 'TT',
    icon: Icons.music_note,
    color: const Color(0xFF111111),
    foreground: Colors.white,
    fieldLabel: 'Usuario de TikTok',
    hint: '@tu.usuario',
    build: (v) => 'https://tiktok.com/@${_stripTo(v, 'tiktok.com')}',
  ),
  Network(
    id: 'li',
    label: 'LinkedIn',
    abbr: 'in',
    color: const Color(0xFF0A66C2),
    foreground: Colors.white,
    fieldLabel: 'Enlace de LinkedIn',
    hint: 'linkedin.com/in/tu-nombre',
    build: (v) => 'https://linkedin.com/in/${_stripTo(v, 'linkedin.com/in')}',
  ),
  Network(
    id: 'x',
    label: 'X',
    abbr: 'X',
    color: const Color(0xFF000000),
    foreground: Colors.white,
    fieldLabel: 'Usuario de X',
    hint: '@tu.usuario',
    build: (v) => 'https://x.com/${_stripTo(v, 'x.com')}',
  ),
  Network(
    id: 'yt',
    label: 'YouTube',
    abbr: 'YT',
    icon: Icons.play_arrow_rounded,
    color: const Color(0xFFE62117),
    foreground: Colors.white,
    fieldLabel: 'Canal de YouTube',
    hint: '@tucanal',
    build: (v) => 'https://youtube.com/@${_stripTo(v, 'youtube.com')}',
  ),
  Network(
    id: 'mail',
    label: 'Correo',
    abbr: '@',
    icon: Icons.mail_outline,
    color: const Color(0xFF6B7280),
    foreground: Colors.white,
    fieldLabel: 'Correo',
    hint: 'tu@correo.com',
    keyboard: TextInputType.emailAddress,
    build: (v) => 'mailto:$v',
  ),
  Network(
    id: 'tel',
    label: 'Teléfono',
    abbr: 'Tel',
    icon: Icons.call_outlined,
    color: const Color(0xFF34C759),
    foreground: const Color(0xFF08311A),
    fieldLabel: 'Teléfono',
    hint: '+51 999 999 999',
    keyboard: TextInputType.phone,
    build: (v) => 'tel:${v.replaceAll(RegExp(r'[^0-9+]'), '')}',
  ),
];

Network networkById(String id) => kNetworks.firstWhere((n) => n.id == id, orElse: () => kNetworks.first);
