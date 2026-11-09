import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/nights.dart';
import '../state/app_state.dart';
import '../theme/polaroid.dart';
import 'connected_screen.dart';
import 'contact_screen.dart';
import 'nearby_view.dart';

/// Escanear el QR de otra persona, o ver quién está cerca.
class ScannerScreen extends StatefulWidget {
  final bool active;
  const ScannerScreen({super.key, required this.active});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(autoStart: false, formats: const [BarcodeFormat.qrCode]);
  bool _busy = false;
  bool _nearby = false;

  bool get _cameraOn => widget.active && !_nearby;

  @override
  void initState() {
    super.initState();
    if (_cameraOn) _controller.start();
  }

  @override
  void didUpdateWidget(covariant ScannerScreen old) {
    super.didUpdateWidget(old);
    _syncCamera(old.active && !_nearby);
  }

  void _syncCamera(bool wasOn) {
    if (_cameraOn && !wasOn) _controller.start();
    if (!_cameraOn && wasOn) _controller.stop();
  }

  void _setMode(bool nearby) {
    final wasOn = _cameraOn;
    setState(() => _nearby = nearby);
    _syncCamera(wasOn);
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
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConnectedScreen(profileId: profile.id)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_cameraOn) _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Pal.bg,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              SegmentPills(
                options: const ['Escanear', 'Cerca de ti'],
                selected: _nearby ? 1 : 0,
                onChanged: (i) => _setMode(i == 1),
              ),
              const Spacer(),
              if (!_nearby)
                RoundIconButton(Icons.flashlight_on_outlined,
                    tooltip: 'Linterna', onTap: () => _controller.toggleTorch()),
            ]),
          ),
          Expanded(child: _nearby ? const NearbyView() : _scanner(context)),
        ]),
      ),
    );
  }

  Widget _scanner(BuildContext context) {
    final state = context.watch<AppState>();
    final tonight = Night.nightOf(DateTime.now());
    final today = state.contacts.where((c) => Night.nightOf(c.since) == tonight).toList();
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (box.maxHeight - 100).clamp(0, double.infinity)),
          child: IntrinsicHeight(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Spacer(),
              Text('Apunta al QR de la otra persona',
                  textAlign: TextAlign.center, style: body(16, color: const Color(0xFFE8E6EE))),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Pal.green, width: 4),
                    boxShadow: [BoxShadow(color: Pal.green.withValues(alpha: 0.55), blurRadius: 30)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Stack(fit: StackFit.expand, children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: (capture) {
                          final v = capture.barcodes.firstOrNull?.rawValue;
                          if (v != null) _handle(v);
                        },
                        errorBuilder: (context, error, child) => ColoredBox(
                          color: Pal.card,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('No se pudo abrir la cámara. Revisa el permiso en los ajustes del teléfono.',
                                  textAlign: TextAlign.center, style: body(14)),
                            ),
                          ),
                        ),
                      ),
                      if (_busy)
                        const ColoredBox(color: Color(0x88000000), child: Center(child: CircularProgressIndicator())),
                    ]),
                  ),
                ),
              ),
              if (state.repo.isDemo) ...[
                const SizedBox(height: 18),
                Center(
                  child: TextButton.icon(
                    onPressed: _busy ? null : () => _redeem('demo'),
                    icon: const Icon(Icons.bolt, color: Pal.yellow),
                    label: Text('Simular escaneo', style: body(15, weight: FontWeight.w700)),
                  ),
                ),
              ],
              const Spacer(),
              if (today.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(today.length == 1 ? 'Hoy conociste a 1 persona 🔥' : 'Hoy conociste a ${today.length} personas 🔥',
                    style: body(15, weight: FontWeight.w800)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: today.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final c = today[i];
                      return GestureDetector(
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ContactScreen(contactId: c.profile.id))),
                        child: PersonPolaroid(
                          id: c.profile.id,
                          name: c.profile.displayName,
                          photoUrl: c.selfieUrl ?? c.profile.avatarUrl,
                          width: 92,
                          angle: tiltFor(c.profile.id, max: 4),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Selector de opciones en forma de pastillas.
class SegmentPills extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const SegmentPills({super.key, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Pal.glass, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < options.length; i++)
          Semantics(
            button: true,
            selected: i == selected,
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: i == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(options[i],
                    style: body(14, color: i == selected ? Pal.ink : Pal.muted, weight: FontWeight.w800)),
              ),
            ),
          ),
      ]),
    );
  }
}
