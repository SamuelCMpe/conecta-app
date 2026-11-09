import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/networks.dart';

/// Colores del estilo "Polaroid y stickers".
class Pal {
  static const bg = Color(0xFF141217);
  static const card = Color(0xFF1E1B23);
  static const yellow = Color(0xFFFFD60A);
  static const pink = Color(0xFFFF3D7F);
  static const green = Color(0xFF3DDC97);
  static const text = Color(0xFFF5F2FA);
  static const muted = Color(0xFF9F9BAB);
  static const ink = Color(0xFF111111);
  static const glass = Color(0x1AFFFFFF);
  static const line = Color(0x14FFFFFF);
}

/// Letras: títulos (Unbounded), texto (Outfit) y escrito a mano (Permanent Marker).
TextStyle display(double size, {Color color = Pal.text}) =>
    GoogleFonts.unbounded(fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5, height: 1.1);
TextStyle body(double size, {Color color = Pal.text, FontWeight weight = FontWeight.w400, double? height}) =>
    GoogleFonts.outfit(fontSize: size, color: color, fontWeight: weight, height: height);
TextStyle hand(double size, {Color color = Pal.ink}) =>
    GoogleFonts.permanentMarker(fontSize: size, color: color, height: 1.15);

/// Colores del marco de la polaroid.
const kFrameColors = <Color>[
  Colors.white,
  Color(0xFFFFE8F0),
  Color(0xFFFFF6C9),
  Color(0xFFDFF7EC),
  Color(0xFF1B1B1F),
];
Color frameColor(int i) => kFrameColors[i.clamp(0, kFrameColors.length - 1)];
Color captionColor(int i) => i == 4 ? Colors.white : Pal.ink;

/// Colores de los stickers (fondo, texto); se van turnando.
const kStickerColors = <(Color, Color)>[
  (Pal.yellow, Pal.ink),
  (Pal.pink, Colors.white),
  (Pal.green, Pal.ink),
  (Color(0xFFC4B5FD), Pal.ink),
  (Color(0xFFFED7AA), Pal.ink),
  (Color(0xFF67E8F9), Pal.ink),
];

const kSuggestedStickers = [
  '🪩 de toque',
  'aquí de paso 🌊',
  '✈️ viajando',
  '🎧 techno',
  '🎶 reggaetón',
  '⚽ hincha de la U',
  '🎓 universitario',
  '☕ coffee lover',
  '🐶 dog lover',
  '🍹 solo por hoy',
  '🎤 karaoke',
  '🏄 surf',
];

/// Degradado fijo para cada persona (cuando no tiene foto).
const _gradients = [
  [Color(0xFF7B2FF7), Color(0xFF00E0FF)],
  [Color(0xFF00F5A0), Color(0xFF00B3FF)],
  [Color(0xFFFFE53B), Color(0xFFFF2525)],
  [Color(0xFFFF2E93), Color(0xFFFF8A00)],
  [Color(0xFF8B5CF6), Color(0xFFEC4899)],
];
LinearGradient gradientFor(String id) {
  final c = _gradients[id.codeUnits.fold<int>(0, (a, b) => a + b) % _gradients.length];
  return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c);
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

ImageProvider? imageFor(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return NetworkImage(url);
  if (url.startsWith('assets/')) return AssetImage(url);
  return FileImage(File(url));
}

/// La foto de una persona: su imagen o un degradado con sus iniciales.
class PhotoBox extends StatelessWidget {
  final String? url;
  final String name;
  final String id;
  final double radius;
  const PhotoBox({super.key, this.url, required this.name, required this.id, this.radius = 2});

  @override
  Widget build(BuildContext context) {
    final img = imageFor(url);
    return LayoutBuilder(
      builder: (context, box) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: img == null ? gradientFor(id) : null,
          image: img == null ? null : DecorationImage(image: img, fit: BoxFit.cover),
        ),
        alignment: Alignment.center,
        child: img == null
            ? Text(initialsOf(name),
                style: body(box.maxWidth.isFinite ? box.maxWidth * 0.28 : 32, weight: FontWeight.w800))
            : null,
      ),
    );
  }
}

/// Foto instantánea: marco claro, foto cuadrada y texto escrito a mano abajo.
class Polaroid extends StatelessWidget {
  final double width;
  final Widget photo;
  final String caption;
  final double angle; // grados
  final int frame;
  final double? photoHeight;
  const Polaroid({
    super.key,
    required this.width,
    required this.photo,
    this.caption = '',
    this.angle = 0,
    this.frame = 0,
    this.photoHeight,
  });

  @override
  Widget build(BuildContext context) {
    final pad = width * 0.06;
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        width: width,
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.6),
        decoration: BoxDecoration(
          color: frameColor(frame),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 30, offset: Offset(0, 14))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: photoHeight ?? width - pad * 2, width: double.infinity, child: photo),
          SizedBox(height: pad * 0.5),
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: hand(math.max(13, width * 0.11), color: captionColor(frame))),
        ]),
      ),
    );
  }
}

/// Polaroid pequeña de una persona (muro, cerca, hoy).
class PersonPolaroid extends StatelessWidget {
  final String id;
  final String name;
  final String? photoUrl;
  final double width;
  final double angle;
  final int frame;
  const PersonPolaroid({
    super.key,
    required this.id,
    required this.name,
    this.photoUrl,
    this.width = 100,
    this.angle = 0,
    this.frame = 0,
  });

  @override
  Widget build(BuildContext context) => Polaroid(
        width: width,
        angle: angle,
        frame: frame,
        caption: name.split(' ').first,
        photo: PhotoBox(url: photoUrl, name: name, id: id),
      );
}

/// Ángulo "al azar" pero fijo para cada persona, para que el muro se vea natural.
double tiltFor(String id, {double max = 5}) {
  final h = id.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0xffff);
  return (h % 100) / 100 * max * 2 - max;
}

class Sticker extends StatelessWidget {
  final String text;
  final int color;
  final double angle;
  final double size;
  const Sticker(this.text, {super.key, this.color = 0, this.angle = 0, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = kStickerColors[color % kStickerColors.length];
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.85, vertical: size * 0.42),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Text(text, style: body(size, color: fg, weight: FontWeight.w800)),
      ),
    );
  }
}

/// Cinta adhesiva sobre una foto.
class Tape extends StatelessWidget {
  final double angle;
  const Tape({super.key, this.angle = -4});
  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(width: 80, height: 24, color: const Color(0xC0FFECAA)),
      );
}

/// Botón redondo de una red social.
class NetCircle extends StatelessWidget {
  final Network network;
  final double size;
  final VoidCallback? onTap;
  final double angle;
  const NetCircle({super.key, required this.network, this.size = 58, this.onTap, this.angle = 0});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: network.label,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: angle * math.pi / 180,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: network.gradient == null ? network.color : null,
              gradient: network.gradient,
              border: Border.all(color: Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: network.icon != null
                ? Icon(network.icon, color: network.foreground, size: size * 0.45)
                : Text(network.abbr, style: body(size * 0.3, color: network.foreground, weight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final Gradient? gradient;
  final IconData? icon;
  const BigButton(this.label,
      {super.key, this.onTap, this.color = Pal.yellow, this.textColor = Pal.ink, this.gradient, this.icon});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                color: gradient == null ? color : null,
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, color: textColor, size: 20), const SizedBox(width: 8)],
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis, style: body(16, color: textColor, weight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón redondo translúcido (cerrar, atrás, linterna…).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  const RoundIconButton(this.icon, {super.key, this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: const Color(0x26FFFFFF),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 22)),
          ),
        ),
      );
}

/// Pastilla (chip) de texto.
class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Pill(this.text, {super.key, this.bg = const Color(0x24FFFFFF), this.fg = Pal.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: body(13, color: fg, weight: FontWeight.w600)),
      );
}

/// Fondo de una pantalla: tu foto desenfocada u oscuro liso.
class BlurredPhotoBackground extends StatelessWidget {
  final String? url;
  final Widget child;
  const BlurredPhotoBackground({super.key, this.url, required this.child});

  @override
  Widget build(BuildContext context) {
    final img = imageFor(url) ?? const AssetImage('assets/backgrounds/oceano.jpg');
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Pal.bg),
      ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Image(image: img, fit: BoxFit.cover),
      ),
      const ColoredBox(color: Color(0x99141217)),
      child,
    ]);
  }
}

/// Fondos de "Mi muro".
const kWalls = [('liso', 'Liso'), ('corcho', 'Corcho'), ('ladrillo', 'Ladrillo'), ('neon', 'Neón')];

/// Pinta el fondo del muro elegido.
class WallBackground extends StatelessWidget {
  final String wall;
  const WallBackground({super.key, required this.wall});

  /// Color del texto escrito sobre ese fondo.
  static Color inkOn(String wall) => wall == 'corcho' ? const Color(0xFF2B1A0C) : Pal.text;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _WallPainter(wall), child: const SizedBox.expand());
}

class _WallPainter extends CustomPainter {
  final String wall;
  _WallPainter(this.wall);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    switch (wall) {
      case 'corcho':
        canvas.drawRect(r, Paint()..color = const Color(0xFFB98A57));
        final dot = Paint()..color = const Color(0x55503214);
        final rnd = math.Random(3);
        for (var i = 0; i < size.width * size.height / 70; i++) {
          canvas.drawCircle(
              Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), 0.6 + rnd.nextDouble() * 1.1, dot);
        }
      case 'ladrillo':
        canvas.drawRect(r, Paint()..color = const Color(0xFF7E3427));
        final mortar = Paint()
          ..color = const Color(0xFF5E2219)
          ..strokeWidth = 3;
        const h = 26.0, w = 64.0;
        for (double y = 0, row = 0; y < size.height; y += h, row++) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), mortar);
          for (double x = row % 2 == 0 ? 0 : w / 2; x < size.width; x += w) {
            canvas.drawLine(Offset(x, y), Offset(x, y + h), mortar);
          }
        }
        canvas.drawRect(r, Paint()..color = const Color(0x40000000));
      case 'neon':
        canvas.drawRect(r, Paint()..color = Pal.bg);
        void glow(Offset c, Color col) => canvas.drawRect(
            r,
            Paint()
              ..shader = RadialGradient(
                center: Alignment(c.dx, c.dy),
                radius: 0.9,
                colors: [col.withValues(alpha: 0.35), col.withValues(alpha: 0)],
              ).createShader(r));
        glow(const Offset(-0.8, -0.7), Pal.pink);
        glow(const Offset(0.9, 0.2), Pal.green);
        glow(const Offset(-0.4, 1), const Color(0xFF7B2FF7));
      default:
        canvas.drawRect(r, Paint()..color = Pal.bg);
    }
  }

  @override
  bool shouldRepaint(covariant _WallPainter old) => old.wall != wall;
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
}

/// Fecha corta en español: "sáb 9 nov".
String shortDate(DateTime d) {
  const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'set', 'oct', 'nov', 'dic'];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

String shortTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
}
