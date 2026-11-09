import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../models/nights.dart';
import '../theme/polaroid.dart';

/// Resumen de una noche, listo para subirlo a tus historias.
class RecapScreen extends StatefulWidget {
  final Night night;
  const RecapScreen({super.key, required this.night});
  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // 300 x 534 a 3.6x = 1080 x 1920, el tamaño de una historia.
      final image = await boundary.toImage(pixelRatio: 3.6);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('No se pudo crear la imagen.');
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: 'conecta-mi-noche.png'),
        ],
        fileNameOverrides: ['conecta-mi-noche.png'],
        text: 'Mi noche en Conecta 📸',
      ));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.night;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D12),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (box.maxHeight - 32).clamp(0, double.infinity)),
              child: IntrinsicHeight(
                child: Column(children: [
                  Row(children: [
                    RoundIconButton(Icons.close, tooltip: 'Cerrar', onTap: () => Navigator.of(context).maybePop()),
                    Expanded(child: Text('Tu noche', textAlign: TextAlign.center, style: body(15, color: Pal.muted))),
                    const SizedBox(width: 44),
                  ]),
                  const Spacer(),
                  const SizedBox(height: 16),
                  RepaintBoundary(key: _key, child: _StoryCard(night: n)),
                  const SizedBox(height: 22),
                  BigButton(
                    _busy ? 'Preparando…' : 'Subir a mis historias',
                    textColor: Colors.white,
                    gradient: const LinearGradient(colors: [Color(0xFFF9A23A), Color(0xFFE1306C), Color(0xFF833AB4)]),
                    onTap: _busy ? null : _share,
                  ),
                  const SizedBox(height: 10),
                  Text('Se comparte la imagen; sus redes no aparecen.', style: body(13, color: Pal.muted)),
                  const Spacer(),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Night night;
  const _StoryCard({required this.night});

  @override
  Widget build(BuildContext context) {
    final people = night.people.take(4).toList();
    final first = night.people.map((c) => c.since).reduce((a, b) => a.isBefore(b) ? a : b);
    final last = night.people.map((c) => c.since).reduce((a, b) => a.isAfter(b) ? a : b);
    const spots = [(18.0, 120.0, -8.0), (150.0, 108.0, 7.0), (40.0, 244.0, 5.0), (166.0, 236.0, -6.0)];
    final title = night.place.isEmpty ? shortDate(night.day) : night.place;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 300,
        height: 534,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0E3D), Color(0xFF7A1F4F), Color(0xFFFF7A3D)],
          ),
        ),
        child: Stack(children: [
          Positioned(
            left: 20,
            top: 22,
            right: 20,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(night.when == 'Anoche' ? 'anoche en' : '${night.when.toLowerCase()} en',
                  style: hand(16, color: Pal.yellow)),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(32)),
              const SizedBox(height: 4),
              Text('${shortDate(night.day)} · ${shortTime(first)} – ${shortTime(last)}',
                  style: body(13, color: const Color(0xFFF4D9E6))),
            ]),
          ),
          for (var i = 0; i < people.length; i++)
            Positioned(
              left: spots[i].$1,
              top: spots[i].$2,
              child: PersonPolaroid(
                id: people[i].profile.id,
                name: people[i].profile.displayName,
                photoUrl: people[i].selfieUrl ?? people[i].profile.avatarUrl,
                width: 110,
                angle: spots[i].$3,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Column(children: [
              Text('+${night.people.length}', style: display(46)),
              Text(night.people.length == 1 ? 'persona nueva 🔥' : 'personas nuevas 🔥',
                  style: body(16, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('conecta', style: display(14, color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
        ]),
      ),
    );
  }
}
