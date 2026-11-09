import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/repository.dart';
import '../state/app_state.dart';
import '../theme/profile_look.dart';
import '../widgets/common.dart';

class _QrStyle {
  final String label;
  final Color color;
  final bool dots;
  const _QrStyle(this.label, this.color, this.dots);
}

const _qrStyles = [
  _QrStyle('Clásico', Color(0xFF12131A), false),
  _QrStyle('Morado', Color(0xFF4A1E5C), true),
  _QrStyle('Azul', Color(0xFF0B4A7A), false),
  _QrStyle('Coral', Color(0xFFB2402A), true),
];

/// Muestra mi QR. Cada 30 s pide un código nuevo, así una captura deja de servir.
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
  int _style = 1;
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
    final st = _qrStyles[_style];

    return ProfileBackground(
      style: me.style,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          children: [
            Text('Mi QR', textAlign: TextAlign.center, style: look.titleFont(size: 30)),
            const SizedBox(height: 4),
            Text('Muéstralo en persona para compartir tu perfil',
                textAlign: TextAlign.center, style: TextStyle(color: look.subtext)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Column(children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: _token == null
                      ? Center(child: _error != null ? Text(_error!, textAlign: TextAlign.center) : const CircularProgressIndicator())
                      : Stack(alignment: Alignment.center, children: [
                          QrImageView(
                            data: _token!.payload,
                            size: 250,
                            padding: EdgeInsets.zero,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: st.color),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: st.dots ? QrDataModuleShape.circle : QrDataModuleShape.square,
                              color: st.color,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
                            padding: const EdgeInsets.all(3),
                            child: Avatar(profile: me, size: 48),
                          ),
                        ]),
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
                  Text('Nuevo código en $_secs s · las capturas no sirven',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF5B5E6B))),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            Glass(
              color: look.glass,
              border: Border.all(color: look.glassBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Expanded(child: Text('Estilo del QR', style: TextStyle(color: look.text, fontWeight: FontWeight.w600))),
                for (var i = 0; i < _qrStyles.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Semantics(
                      button: true,
                      selected: i == _style,
                      label: _qrStyles[i].label,
                      child: GestureDetector(
                        onTap: () => setState(() => _style = i),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _qrStyles[i].color,
                            shape: _qrStyles[i].dots ? BoxShape.circle : BoxShape.rectangle,
                            borderRadius: _qrStyles[i].dots ? null : BorderRadius.circular(8),
                            border: Border.all(color: i == _style ? look.accent : Colors.white, width: i == _style ? 3 : 2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
