import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../state/app_state.dart';
import '../theme/profile_look.dart';
import '../widgets/styled_qr.dart';

/// Muestra mi QR. Cada 30 s pide un código nuevo, así una captura deja de servir.
/// El estilo del QR se cambia en Configuración.
class MyQrScreen extends StatefulWidget {
  final bool active;
  const MyQrScreen({super.key, required this.active});
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
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(covariant MyQrScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _start();
    if (!widget.active && old.active) _stop();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _start() async {
    await _refresh();
    _timer?.cancel();
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
    final look = ProfileLook(me.style);
    final st = qrStyleAt(me.style.qrStyle);

    return ProfileBackground(
      style: me.style,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            child: Column(children: [
              Text('Mi QR', textAlign: TextAlign.center, style: look.titleFont(size: 30)),
              const SizedBox(height: 4),
              Text('Muéstralo en persona para compartir tu perfil',
                  textAlign: TextAlign.center, style: TextStyle(color: look.subtext)),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Column(children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: _token == null
                        ? Center(
                            child: _error != null
                                ? Text(_error!, textAlign: TextAlign.center)
                                : const CircularProgressIndicator())
                        : StyledQr(data: _token!.payload, profile: me, styleIndex: me.style.qrStyle),
                  ),
                  const SizedBox(height: 14),
                  Text(me.displayName, style: look.titleFont(size: 20, color: const Color(0xFF12131A))),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _secs / _visibleSeconds,
                      minHeight: 6,
                      color: st.color,
                      backgroundColor: const Color(0xFFECEDF2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_outline, size: 16, color: Color(0xFF5B5E6B)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('Nuevo código en $_secs s · las capturas no sirven',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF5B5E6B))),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
