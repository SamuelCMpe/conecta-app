import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/repository.dart';
import '../state/app_state.dart';
import '../theme/polaroid.dart';

/// Mi QR impreso en una polaroid. Cada 30 s pide un código nuevo, así una captura deja de servir.
class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});
  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  static const _visibleSeconds = 30;
  QrToken? _token;
  int _secs = _visibleSeconds;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    await _refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secs <= 1) {
        _refresh();
      } else {
        setState(() => _secs--);
      }
    });
  }

  Future<void> _refresh() async {
    try {
      final t = await context.read<AppState>().repo.createQrToken();
      if (!mounted) return;
      setState(() {
        _token = t;
        _secs = _visibleSeconds;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo crear el código. Revisa tu conexión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me;
    if (me == null) return const SizedBox();

    final qr = SizedBox(
      width: 262,
      height: 262,
      child: _token == null
          ? Center(
              child: _error != null
                  ? Text(_error!, textAlign: TextAlign.center, style: body(14, color: Pal.ink))
                  : const CircularProgressIndicator(color: Pal.ink))
          : QrImageView(
              data: _token!.payload,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Pal.ink),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Pal.ink),
            ),
    );

    return Scaffold(
      backgroundColor: Pal.bg,
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
                    Expanded(child: Text('Mi código', textAlign: TextAlign.center, style: body(15, color: Pal.muted))),
                    const SizedBox(width: 44),
                  ]),
                  const Spacer(),
                  Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                    Polaroid(
                      width: 310,
                      angle: -2,
                      photoHeight: 262,
                      caption: 'escanéame 👀',
                      photo: Center(child: qr),
                    ),
                    const Positioned(top: -12, child: Tape()),
                    Positioned(
                      right: -12,
                      bottom: 34,
                      child: Sticker('⏱ $_secs s', color: 2, angle: 10),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: ClipOval(child: PhotoBox(url: me.avatarUrl, name: me.displayName, id: me.id)),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(me.displayName, style: body(16, weight: FontWeight.w800)),
                      Text('Las capturas no sirven 🔒', style: body(13, color: Pal.muted)),
                    ]),
                  ]),
                  const SizedBox(height: 26),
                  Text('Muéstralo en persona. Cuando te escaneen, los dos quedan en su muro 📸',
                      textAlign: TextAlign.center, style: body(15, color: const Color(0xFFE8E6EE), height: 1.4)),
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
