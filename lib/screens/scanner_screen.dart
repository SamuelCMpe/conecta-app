import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'other_profile_screen.dart';

/// Escanea el QR de otra persona con la cámara.
class ScannerScreen extends StatefulWidget {
  final bool active;
  const ScannerScreen({super.key, required this.active});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(autoStart: false, formats: const [BarcodeFormat.qrCode]);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.start();
  }

  @override
  void didUpdateWidget(covariant ScannerScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _controller.start();
    if (!widget.active && old.active) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handle(String raw) async {
    if (_busy) return;
    final token = tokenFromPayload(raw);
    if (token == null) {
      showError(context, 'Ese código no es de Conecta.');
      return;
    }
    await _redeem(token);
  }

  Future<void> _redeem(String token) async {
    setState(() => _busy = true);
    await _controller.stop();
    try {
      if (!mounted) return;
      final profile = await context.read<AppState>().scan(token);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OtherProfileScreen(profile: profile, justScanned: true)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (widget.active) _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = context.read<AppState>().repo.isDemo;
    return ColoredBox(
      color: const Color(0xFF0B0C10),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 100),
          child: Column(children: [
            Text('Escanear', style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Apunta la cámara al QR de la otra persona', style: TextStyle(color: Color(0xFFB9BBC7))),
            const SizedBox(height: 28),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(fit: StackFit.expand, children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final v = capture.barcodes.firstOrNull?.rawValue;
                      if (v != null) _handle(v);
                    },
                    errorBuilder: (context, error, child) => const ColoredBox(
                      color: Color(0xFF1A1C24),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No se pudo abrir la cámara. Revisa el permiso en los ajustes del teléfono.',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 4),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  if (_busy) const ColoredBox(color: Color(0x88000000), child: Center(child: CircularProgressIndicator())),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Al escanear, los dos verán el perfil del otro al instante.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB9BBC7))),
            const Spacer(),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x55FFFFFF)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _controller.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on_outlined),
                  label: const Text('Linterna'),
                ),
              ),
              if (demo) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: _busy ? null : () => _redeem('demo'),
                    child: const Text('Simular escaneo'),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
