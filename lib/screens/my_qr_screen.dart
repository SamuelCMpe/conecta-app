import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/repository.dart';
import '../state/app_state.dart';
import '../theme/polaroid.dart';
import 'scanner_screen.dart' show SegmentPills;

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

  /// Modo grupo: un QR que dura 3 horas y conecta a todos los que lo escaneen.
  bool _group = false;
  QrToken? _groupToken;
  int _groupSize = 1;
  int _tick = 0;

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
      if (_group) {
        if (++_tick % 5 == 0) _refreshGroupSize();
        return;
      }
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

  Future<void> _setGroup(bool on) async {
    if (on == _group) return;
    setState(() {
      _group = on;
      _error = null;
    });
    if (on && _groupToken == null) {
      try {
        final t = await context.read<AppState>().createGroup();
        if (!mounted) return;
        setState(() => _groupToken = t);
      } catch (e) {
        if (mounted) setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _refreshGroupSize() async {
    final t = _groupToken;
    if (t == null) return;
    try {
      final n = await context.read<AppState>().repo.groupSize(t.token);
      if (mounted && n != _groupSize) setState(() => _groupSize = n);
    } catch (_) {}
  }

  Future<void> _endGroup() async {
    final t = _groupToken;
    if (t != null) {
      try {
        await context.read<AppState>().repo.endGroup(t.token);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _groupToken = null;
      _groupSize = 1;
      _group = false;
    });
    await context.read<AppState>().refreshContacts().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me;
    if (me == null) return const SizedBox();

    final qr = SizedBox(
      width: 262,
      height: 262,
      child: (_group ? _groupToken : _token) == null
          ? Center(
              child: _error != null
                  ? Text(_error!, textAlign: TextAlign.center, style: body(14, color: Pal.ink))
                  : const CircularProgressIndicator(color: Pal.ink))
          : QrImageView(
              data: (_group ? _groupToken : _token)!.payload,
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
                    const Spacer(),
                    SegmentPills(
                        options: const ['Solo yo', 'Grupo'], selected: _group ? 1 : 0, onChanged: (i) => _setGroup(i == 1)),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ]),
                  const Spacer(),
                  Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                    Polaroid(
                      width: 310,
                      angle: -2,
                      photoHeight: 262,
                      caption: _group ? 'en grupo 👯' : 'escanéame 👀',
                      photo: Center(child: qr),
                    ),
                    const Positioned(top: -12, child: Tape()),
                    Positioned(
                      right: -12,
                      bottom: 34,
                      child: _group
                          ? Sticker('👥 $_groupSize ${_groupSize == 1 ? 'persona' : 'personas'}', color: 1, angle: 10)
                          : Sticker('⏱ $_secs s', color: 2, angle: 10),
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
                      Text(_group ? 'QR de grupo · dura 3 horas' : 'Las capturas no sirven 🔒',
                          style: body(13, color: Pal.muted)),
                    ]),
                  ]),
                  const SizedBox(height: 26),
                  Text(
                      _group
                          ? 'Todos los que lo escaneen quedan conectados entre sí, y contigo. Ideal para una mesa o una fiesta 🎉'
                          : 'Muéstralo en persona. Cuando te escaneen, los dos quedan en su muro 📸',
                      textAlign: TextAlign.center,
                      style: body(15, color: const Color(0xFFE8E6EE), height: 1.4)),
                  if (_group && _groupToken != null) ...[
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _endGroup,
                      child: Text('Terminar grupo', style: body(14, color: Pal.pink, weight: FontWeight.w700)),
                    ),
                  ],
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
