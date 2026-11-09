import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../state/app_state.dart';
import '../theme/polaroid.dart';
import '../widgets/profile_card.dart';
import 'connected_screen.dart';

/// Perfil de alguien de mi muro. Se le puede dar la vuelta a la foto para escribir una nota.
class ContactScreen extends StatefulWidget {
  final String contactId;
  const ContactScreen({super.key, required this.contactId});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool _back = false;
  final _note = TextEditingController();
  bool _noteLoaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _saveNote(Contact c) async {
    setState(() => _saving = true);
    try {
      await context.read<AppState>().saveNote(c, _note.text);
      if (mounted) {
        FocusScope.of(context).unfocus();
        showError(context, 'Nota guardada. Solo tú la ves.');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _menu(Contact c) async {
    final state = context.read<AppState>();
    final first = c.profile.displayName.split(' ').first;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Pal.card,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.block, color: Pal.pink),
            title: Text('Bloquear a $first', style: body(16, weight: FontWeight.w700)),
            subtitle: Text('Pierde el acceso a tus redes y sale de tu muro', style: body(13, color: Pal.muted)),
            onTap: () => Navigator.pop(ctx, 'block'),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Pal.yellow),
            title: Text('Reportar', style: body(16, weight: FontWeight.w700)),
            subtitle: Text('Lo revisamos y lo bloqueamos para ti', style: body(13, color: Pal.muted)),
            onTap: () => Navigator.pop(ctx, 'report'),
          ),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    try {
      if (choice == 'report') await state.report(c.profile.id, 'Reportado desde su perfil');
      await state.block(c.profile.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = state.contactById(widget.contactId);
    if (c == null) return const Scaffold(backgroundColor: Pal.bg);
    if (!_noteLoaded) {
      _note.text = c.note;
      _noteLoaded = true;
    }
    final p = c.profile;
    final first = p.displayName.split(' ').first;

    return Scaffold(
      backgroundColor: Pal.bg,
      body: Stack(fit: StackFit.expand, children: [
        Opacity(
          opacity: 0.3,
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradientFor(p.id))),
        ),
        const ColoredBox(color: Color(0x66141217)),
        SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
            Row(children: [
              RoundIconButton(Icons.arrow_back, tooltip: 'Atrás', onTap: () => Navigator.of(context).maybePop()),
              const Spacer(),
              Material(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _back = !_back),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Text(_back ? '🔄 Ver foto' : '🔄 Mi nota', style: body(14, weight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(Icons.more_horiz, tooltip: 'Más opciones', onTap: () => _menu(c)),
            ]),
            const SizedBox(height: 24),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, anim) => AnimatedBuilder(
                  animation: anim,
                  child: child,
                  builder: (context, child) {
                    final angle = (1 - anim.value) * math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: child,
                    );
                  },
                ),
                child: _back
                    ? _NoteCard(key: const ValueKey('back'), controller: _note, contact: c)
                    : ProfilePolaroid(
                        key: const ValueKey('front'),
                        profile: p,
                        width: 250,
                        photoUrl: c.selfieUrl ?? p.avatarUrl,
                        caption: '$first ✨',
                        onTap: () => setState(() => _back = true),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            if (_back) ...[
              BigButton(_saving ? 'Guardando…' : 'Guardar nota', onTap: _saving ? null : () => _saveNote(c)),
              const SizedBox(height: 10),
              Center(child: Text('Solo tú ves esta nota 🔒', style: body(13, color: Pal.muted))),
            ] else ...[
              Center(
                child: GestureDetector(
                  onTap: () => editPlace(context, c),
                  child: Pill(
                    c.place.isEmpty
                        ? 'Se conocieron el ${shortDate(c.since)} · toca para poner el lugar'
                        : 'Se conocieron en 📍 ${c.place} · ${shortDate(c.since)}',
                    bg: const Color(0x1FFFFFFF),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ProfileDetails(profile: p),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: () => context.read<AppState>().toggleRevoked(c),
                  child: Text(
                    c.revoked ? 'Devolverle el acceso a mis redes' : 'Quitarle el acceso a mis redes',
                    style: body(14, color: c.revoked ? Pal.green : const Color(0xFFFF8FB1), weight: FontWeight.w700),
                  ),
                ),
              ),
              if (c.revoked) Center(child: Text('$first ya no puede ver tus redes', style: body(13, color: Pal.muted))),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// El reverso de la polaroid: papel con líneas para escribir.
class _NoteCard extends StatelessWidget {
  final TextEditingController controller;
  final Contact contact;
  const _NoteCard({super.key, required this.controller, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 2 * math.pi / 180,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        Container(
          width: 290,
          height: 360,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF7EC),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 14))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${contact.profile.displayName} · ${shortDate(contact.since)}',
                style: hand(14, color: const Color(0xFFA08B78))),
            const SizedBox(height: 8),
            Expanded(
              child: CustomPaint(
                painter: _Lines(),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  maxLength: 300,
                  style: hand(21, color: const Color(0xFF1F3A93)).copyWith(height: 1.62),
                  cursorColor: const Color(0xFF1F3A93),
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'amiga de Juan, la del polo rojo…',
                    hintStyle: hand(19, color: const Color(0x661F3A93)),
                    contentPadding: const EdgeInsets.only(top: 4),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const Positioned(top: -12, child: Tape(angle: 3)),
      ]),
    );
  }
}

class _Lines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE6DCC6)
      ..strokeWidth = 1;
    for (double y = 36; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
