import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/networks.dart';
import '../models/profile.dart';
import '../services/links.dart';
import '../state/app_state.dart';
import '../theme/polaroid.dart';
import 'contact_screen.dart';

/// Lo que ves justo después de escanear: sus dos fotos, dónde y cuándo, y sus redes.
class ConnectedScreen extends StatefulWidget {
  final String profileId;
  const ConnectedScreen({super.key, required this.profileId});
  @override
  State<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends State<ConnectedScreen> {
  bool _busy = false;

  Future<void> _selfie(Contact c) async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1400,
      imageQuality: 85,
    );
    if (f == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().saveSelfie(c.profile.id, f.path);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me!;
    final c = state.contactById(widget.profileId);
    if (c == null) return const Scaffold(backgroundColor: Pal.bg);
    final p = c.profile;
    final first = p.displayName.split(' ').first;
    final nets = p.networks.map(networkById).where((n) => (p.socials[n.id] ?? '').isNotEmpty).toList();
    final hasWa = (p.socials['wa'] ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: Pal.bg,
      body: Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.45),
              radius: 0.9,
              colors: [Color(0x73FF3D7F), Color(0x00FF3D7F)],
            ),
          ),
        ),
        SafeArea(
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
                    ]),
                    const Spacer(),
                    SizedBox(
                      height: 210,
                      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                        Transform.translate(
                          offset: const Offset(-62, 0),
                          child: Polaroid(
                            width: 150,
                            angle: -8,
                            frame: me.style.frame,
                            caption: 'tú',
                            photo: PhotoBox(url: me.avatarUrl, name: me.displayName, id: me.id),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(62, 14),
                          child: Polaroid(
                            width: 150,
                            angle: 7,
                            frame: p.style.frame,
                            caption: first,
                            photo: PhotoBox(url: c.selfieUrl ?? p.avatarUrl, name: p.displayName, id: p.id),
                          ),
                        ),
                        const Positioned(top: -6, child: Tape(angle: 8)),
                        const Positioned(left: 0, top: -10, child: Text('✨', style: TextStyle(fontSize: 30))),
                        const Positioned(right: 0, top: -4, child: Text('🎉', style: TextStyle(fontSize: 30))),
                      ]),
                    ),
                    const SizedBox(height: 26),
                    Text('¡Conectaron!', style: display(32)),
                    const SizedBox(height: 12),
                    Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                      GestureDetector(
                        onTap: () => editPlace(context, c),
                        child: Sticker(c.place.isEmpty ? '📍 ¿Dónde fue?' : '📍 ${c.place}', angle: -3),
                      ),
                      Sticker('${shortDate(c.since)} · ${shortTime(c.since)}', color: 5, angle: 3),
                    ]),
                    const SizedBox(height: 24),
                    if (nets.isNotEmpty)
                      Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 12, children: [
                        for (final n in nets)
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            NetCircle(network: n, size: 60, onTap: () => openNetwork(context, p, n)),
                            const SizedBox(height: 6),
                            Text(n.label, style: body(12, color: const Color(0xFFBDBAC7))),
                          ]),
                      ]),
                    const SizedBox(height: 26),
                    if (hasWa) ...[
                      BigButton('Escribirle por WhatsApp 💬', onTap: () => openNetwork(context, p, networkById('wa'))),
                      const SizedBox(height: 12),
                    ],
                    BigButton(
                      c.selfieUrl == null ? '📸 Foto juntos' : '📸 Cambiar foto juntos',
                      color: Pal.glass,
                      textColor: Pal.text,
                      onTap: _busy ? null : () => _selfie(c),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => ContactScreen(contactId: p.id)),
                      ),
                      child: Text('Ver su perfil completo', style: body(14, weight: FontWeight.w700)),
                    ),
                    Text('$first también recibió tu perfil', style: body(13, color: Pal.muted)),
                    const Spacer(),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Escribir a mano dónde se conocieron (si la ubicación no funcionó).
Future<void> editPlace(BuildContext context, Contact c) async {
  final ctl = TextEditingController(text: c.place);
  final place = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Pal.card,
      title: Text('¿Dónde se conocieron?', style: body(20, weight: FontWeight.w800)),
      content: TextField(
        controller: ctl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Ej: Barranco, Máncora, la U'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text), child: const Text('Guardar')),
      ],
    ),
  );
  if (place == null || place.trim() == c.place || !context.mounted) return;
  try {
    await context.read<AppState>().savePlace(c, place);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}
