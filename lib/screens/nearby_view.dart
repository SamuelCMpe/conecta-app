import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../state/app_state.dart';
import '../theme/polaroid.dart';

/// "Cerca de ti": quién más tiene Conecta en el mismo lugar.
/// Solo aparece quien activó "Visible" (2 horas). Se ve nombre, foto y un sticker; nunca sus redes.
class NearbyView extends StatefulWidget {
  const NearbyView({super.key});
  @override
  State<NearbyView> createState() => _NearbyViewState();
}

class _NearbyViewState extends State<NearbyView> {
  bool _busy = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Actualiza el tiempo que queda y la lista cada minuto.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final s = context.read<AppState>();
      if (s.isVisible) s.refreshNearby();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    try {
      final ok = await context.read<AppState>().setVisible(on);
      if (!ok && mounted) {
        showError(context, 'Para usar Cerca de ti, activa la ubicación del teléfono y dale permiso a Conecta.');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _left(DateTime until) {
    final d = until.difference(DateTime.now());
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')} h' : '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isVisible) return _off();
    final people = state.nearby;
    return RefreshIndicator(
      onRefresh: state.refreshNearby,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 110), children: [
        Row(children: [
          Expanded(
            child: Text(
              '📍 ${state.visiblePlace?.name.isNotEmpty == true ? state.visiblePlace!.name : 'Aquí'} · '
              '${people.length} ${people.length == 1 ? 'persona visible' : 'personas visibles'}',
              style: body(14, color: const Color(0xFFBDBAC7)),
            ),
          ),
          _VisibleSwitch(label: 'Visible · ${_left(state.visibleUntil!)}', busy: _busy, onOff: () => _toggle(false)),
        ]),
        const SizedBox(height: 16),
        if (people.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(children: [
              const Text('👀', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text('Por ahora nadie más está visible aquí.',
                  textAlign: TextAlign.center, style: body(16, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Desliza hacia abajo para buscar de nuevo.',
                  textAlign: TextAlign.center, style: body(14, color: Pal.muted)),
            ]),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.62,
            children: [for (final p in people) _PersonCard(person: p)],
          ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_outline, size: 14, color: Pal.muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Sus redes se ven solo cuando escaneas su QR',
                textAlign: TextAlign.center, style: body(12.5, color: Pal.muted)),
          ),
        ]),
      ]),
    );
  }

  Widget _off() {
    Widget point(String emoji, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: body(15, color: const Color(0xFFE8E6EE), height: 1.35))),
          ]),
        );
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (box.maxHeight - 126).clamp(0, double.infinity)),
          child: IntrinsicHeight(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Spacer(),
              SizedBox(
                height: 170,
                child: Stack(alignment: Alignment.center, children: [
                  Transform.translate(
                      offset: const Offset(-70, 0),
                      child: const PersonPolaroid(id: 'valeria', name: 'Valeria', width: 110, angle: -9)),
                  Transform.translate(
                      offset: const Offset(70, 6),
                      child: const PersonPolaroid(id: 'rodrigo', name: 'Rodrigo', width: 110, angle: 8)),
                  const Positioned(bottom: 0, child: Sticker('👋 hola', angle: -4)),
                ]),
              ),
              const SizedBox(height: 26),
              Text('¿Quién más está aquí?', textAlign: TextAlign.center, style: display(24)),
              const SizedBox(height: 10),
              Text('Activa Visible y mira quién más tiene Conecta en este lugar. Puedes saludar y luego pasarse el QR.',
                  textAlign: TextAlign.center, style: body(15.5, color: Pal.muted, height: 1.4)),
              const SizedBox(height: 22),
              point('⏱', 'Se apaga solo en 2 horas.'),
              point('📍', 'Nadie ve dónde estás exactamente, solo que están en el mismo lugar.'),
              point('🔒', 'Solo se ve tu foto, tu nombre y un sticker. Tus redes, solo con tu QR.'),
              point('🚫', 'Puedes bloquear o reportar a cualquiera.'),
              const SizedBox(height: 10),
              BigButton(_busy ? 'Buscando dónde estás…' : 'Activar Visible por 2 horas',
                  onTap: _busy ? null : () => _toggle(true)),
              const Spacer(),
            ]),
          ),
        ),
      ),
    );
  }
}

class _VisibleSwitch extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onOff;
  const _VisibleSwitch({required this.label, required this.busy, required this.onOff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
      decoration: BoxDecoration(
        color: Pal.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Pal.green),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: body(13, color: Pal.green, weight: FontWeight.w700)),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: true,
            activeTrackColor: Pal.green,
            activeThumbColor: Colors.white,
            onChanged: busy ? null : (_) => onOff(),
          ),
        ),
      ]),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final NearbyPerson person;
  const _PersonCard({required this.person});

  Future<void> _menu(BuildContext context) async {
    final state = context.read<AppState>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Pal.card,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.block, color: Pal.pink),
            title: Text('Bloquear a ${person.firstName}', style: body(16, weight: FontWeight.w700)),
            subtitle: Text('Ya no te verá ni podrá saludarte', style: body(13, color: Pal.muted)),
            onTap: () => Navigator.pop(context, 'block'),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Pal.yellow),
            title: Text('Reportar', style: body(16, weight: FontWeight.w700)),
            subtitle: Text('Lo revisamos y lo bloqueamos para ti', style: body(13, color: Pal.muted)),
            onTap: () => Navigator.pop(context, 'report'),
          ),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'report') await state.report(person.id, 'Reportado desde Cerca de ti');
    await state.block(person.id);
    if (context.mounted) {
      showError(
          context,
          choice == 'report'
              ? 'Gracias. Reportaste y bloqueaste a ${person.firstName}.'
              : 'Bloqueaste a ${person.firstName}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Pal.line),
      ),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          PersonPolaroid(
              id: person.id,
              name: person.firstName,
              photoUrl: person.avatarUrl,
              width: 112,
              angle: tiltFor(person.id, max: 3)),
          if (person.wavedAtMe)
            const Positioned(left: -10, top: -10, child: Sticker('👋 te saludó', angle: -8, size: 11)),
          Positioned(
            right: -14,
            top: -14,
            child: IconButton(
              tooltip: 'Más opciones',
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onPressed: () => _menu(context),
            ),
          ),
        ]),
        const Spacer(),
        if (person.sticker.isNotEmpty) Pill(person.sticker),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: person.iWaved ? Pal.glass : Pal.yellow,
              foregroundColor: person.iWaved ? Pal.text : Pal.ink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: person.iWaved ? null : () => context.read<AppState>().wave(person),
            child: Text(person.iWaved ? 'Saludaste ✓' : '👋 Saludar', style: body(14, weight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
