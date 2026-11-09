import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/profile.dart';

class BackgroundPreset {
  final String id;
  final String label;
  final String? asset;
  final bool dark;
  final Color accent;
  const BackgroundPreset(this.id, this.label, {this.asset, required this.dark, required this.accent});
}

const kImagePresets = [
  BackgroundPreset('montanas', 'Montañas', asset: 'assets/backgrounds/montanas.jpg', dark: true, accent: Color(0xFFFFB27A)),
  BackgroundPreset('bokeh', 'Luces', asset: 'assets/backgrounds/bokeh.jpg', dark: true, accent: Color(0xFFFF9BC2)),
  BackgroundPreset('oceano', 'Océano', asset: 'assets/backgrounds/oceano.jpg', dark: true, accent: Color(0xFF8BE9F5)),
];

const kPatternPresets = [
  BackgroundPreset('aurora', 'Aurora', dark: true, accent: Color(0xFFC1B8FF)),
  BackgroundPreset('neon', 'Neón', dark: true, accent: Color(0xFF39FF88)),
  BackgroundPreset('papel', 'Papel', dark: false, accent: Color(0xFFC2410C)),
];

const kCustomPreset = BackgroundPreset('custom', 'Tu imagen', dark: true, accent: Colors.white);

BackgroundPreset presetById(String id) {
  for (final p in [...kImagePresets, ...kPatternPresets, kCustomPreset]) {
    if (p.id == id) return p;
  }
  return kImagePresets.first;
}

const kAccentChoices = <Color>[Colors.white, Color(0xFFF2C14E), Color(0xFF4B3BEF), Color(0xFFD92D20)];

class RingOption {
  final String label;
  final Gradient? gradient;
  final Color? color;
  const RingOption(this.label, {this.gradient, this.color});
}

List<RingOption> ringOptions(Color accent) => [
      RingOption('Degradado', gradient: LinearGradient(colors: [accent, const Color(0xFFFF4F9A)])),
      const RingOption('Blanco', color: Colors.white),
      const RingOption('Dorado', gradient: LinearGradient(colors: [Color(0xFFF7D774), Color(0xFFB8862B)])),
      const RingOption('Arcoíris',
          gradient: SweepGradient(colors: [
            Color(0xFFFF4F4F),
            Color(0xFFFFB23F),
            Color(0xFFF7E04F),
            Color(0xFF3FD07A),
            Color(0xFF3FA9FF),
            Color(0xFF9B5CFF),
            Color(0xFFFF4F4F),
          ])),
      const RingOption('Sin aro', color: Colors.transparent),
    ];

/// Todo lo que hace falta para pintar un perfil con su estilo.
class ProfileLook {
  final ProfileStyle style;
  ProfileLook(this.style);

  BackgroundPreset get preset => presetById(style.background);
  bool get dark => preset.dark;
  Color get accent => style.accent != null ? Color(style.accent!) : preset.accent;
  Color get onAccent => accent.computeLuminance() > 0.45 ? const Color(0xFF12131A) : Colors.white;
  Color get text => dark ? Colors.white : const Color(0xFF1E1A14);
  Color get subtext => dark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF5E5547);
  Color get glass => dark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.8);
  Color get glassBorder => dark ? Colors.white.withValues(alpha: 0.25) : const Color(0x1F1E1A14);

  double get avatarRadiusFactor => switch (style.avatarShape) {
        'redondeada' => 0.28,
        'cuadrada' => 0.12,
        _ => 0.5,
      };

  TextStyle titleFont({double size = 30, Color? color}) {
    final c = color ?? text;
    switch (style.font) {
      case 'moderna':
        return GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: c);
      case 'divertida':
        return GoogleFonts.fredoka(fontSize: size, fontWeight: FontWeight.w700, color: c);
      default:
        return GoogleFonts.playfairDisplay(fontSize: size, fontWeight: FontWeight.w700, color: c);
    }
  }

  /// Fondo, borde y color de texto de los botones según el estilo elegido.
  ({Color bg, Border? border, Color fg, bool blur}) get button {
    switch (style.buttons) {
      case 'relleno':
        return (bg: dark ? Colors.white : const Color(0xFF1E1A14), border: null, fg: dark ? const Color(0xFF12131A) : Colors.white, blur: false);
      case 'contorno':
        return (bg: Colors.transparent, border: Border.all(color: text, width: 2), fg: text, blur: false);
      default:
        return (bg: glass, border: Border.all(color: glassBorder), fg: text, blur: true);
    }
  }

  LinearGradient get overlay {
    final level = [0.1, 0.4, 0.7][style.dim.clamp(0, 2)];
    if (!dark) {
      return LinearGradient(colors: [Colors.white.withValues(alpha: level * 0.5), Colors.white.withValues(alpha: level * 0.5)]);
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A0814).withValues(alpha: level * 0.6),
        const Color(0xFF0A0814).withValues(alpha: (level + 0.2).clamp(0, 0.9)),
      ],
    );
  }
}

/// Pinta el fondo elegido (imagen, degradado o patrón) con su capa para oscurecer.
class ProfileBackground extends StatelessWidget {
  final ProfileStyle style;
  final Widget child;
  const ProfileBackground({super.key, required this.style, required this.child});

  @override
  Widget build(BuildContext context) {
    final look = ProfileLook(style);
    return Stack(
      fit: StackFit.expand,
      children: [
        _base(look),
        DecoratedBox(decoration: BoxDecoration(gradient: look.overlay)),
        child,
      ],
    );
  }

  Widget _base(ProfileLook look) {
    final p = look.preset;
    if (p.asset != null) return Image.asset(p.asset!, fit: BoxFit.cover);
    switch (p.id) {
      case 'custom':
        final url = style.customBackgroundUrl;
        if (url == null) return Image.asset(kImagePresets.first.asset!, fit: BoxFit.cover);
        final img = url.startsWith('http')
            ? Image.network(url, fit: BoxFit.cover)
            : Image.file(File(url), fit: BoxFit.cover);
        if (!style.blur) return img;
        return ClipRect(
          child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Transform.scale(scale: 1.1, child: img)),
        );
      case 'aurora':
        return const _Aurora();
      case 'neon':
        return CustomPaint(painter: _GridPainter(), child: const SizedBox.expand());
      case 'papel':
        return CustomPaint(painter: _DotsPainter(), child: const SizedBox.expand());
    }
    return const ColoredBox(color: Color(0xFF12131A));
  }
}

/// Miniatura de un fondo, para los selectores del editor.
class BackgroundThumb extends StatelessWidget {
  final String presetId;
  const BackgroundThumb({super.key, required this.presetId});

  @override
  Widget build(BuildContext context) {
    final p = presetById(presetId);
    if (p.asset != null) return Image.asset(p.asset!, fit: BoxFit.cover);
    return ProfileBackground(style: ProfileStyle(background: presetId, dim: 0), child: const SizedBox());
  }
}

class _Aurora extends StatelessWidget {
  const _Aurora();
  @override
  Widget build(BuildContext context) {
    Widget blob(Alignment a, Color c, double r) => DecoratedBox(
          decoration: BoxDecoration(gradient: RadialGradient(center: a, radius: r, colors: [c, c.withValues(alpha: 0)])),
        );
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Color(0xFF0E0B24)),
      blob(const Alignment(-0.7, -0.8), const Color(0xFF7C5CFF), 0.9),
      blob(const Alignment(0.8, -0.3), const Color(0xFF00C2B8), 0.8),
      blob(const Alignment(-0.2, 0.9), const Color(0xFFFF4F9A), 0.9),
    ]);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF07070C));
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [const Color(0xFF39FF88).withValues(alpha: 0.35), const Color(0x0039FF88)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
    final line = Paint()
      ..color = const Color(0xFF39FF88).withValues(alpha: 0.09)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF4EFE6));
    final dot = Paint()..color = const Color(0xFFD6CCBA);
    for (double y = 9; y < size.height; y += 18) {
      for (double x = 9; x < size.width; x += 18) {
        canvas.drawCircle(Offset(x, y), 1.3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
