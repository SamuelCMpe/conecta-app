import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nights.dart';
import '../state/app_state.dart';
import '../theme/polaroid.dart';
import 'contact_screen.dart';
import 'recap_screen.dart';
import 'scanner_screen.dart';
import 'wall_map.dart';

/// "Mi muro": la gente que conociste, agrupada por noche y lugar. También en mapa.
class WallScreen extends StatefulWidget {
  const WallScreen({super.key});
  @override
  State<WallScreen> createState() => _WallScreenState();
}

class _WallScreenState extends State<WallScreen> {
  bool _map = false;

  static const _titleColors = [Pal.yellow, Pal.pink, Pal.green, Color(0xFFC4B5FD)];

  Future<void> _chooseWall() async {
    final state = context.read<AppState>();
    final me = state.me!;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Pal.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fondo de tu muro', style: body(18, weight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (final w in kWalls)
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, w.$1),
                  child: Column(children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: me.style.wall == w.$1 ? Pal.yellow : Pal.line, width: me.style.wall == w.$1 ? 3 : 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: WallBackground(wall: w.$1),
                    ),
                    const SizedBox(height: 8),
                    Text(w.$2, style: body(13, weight: FontWeight.w600)),
                  ]),
                ),
            ]),
          ]),
        ),
      ),
    );
    if (picked == null || picked == me.style.wall) return;
    try {
      await state.saveProfile(me.copyWith(style: me.style.copyWith(wall: picked)));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wall = state.me?.style.wall ?? 'liso';
    final ink = _map ? Pal.text : WallBackground.inkOn(wall);
    final nights = Night.group(state.contacts);

    return Stack(fit: StackFit.expand, children: [
      if (_map) WallMap(contacts: state.contacts) else WallBackground(wall: wall),
      // Sobre el mapa, una franja oscura arriba para que el título se lea.
      if (_map)
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 150,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xF0141217), Color(0xB3141217), Color(0x00141217)],
                ),
              ),
            ),
          ),
        ),
      SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(children: [
              Text('Mi muro', style: display(22, color: ink)),
              const Spacer(),
              SegmentPills(
                  options: const ['Fotos', 'Mapa'],
                  selected: _map ? 1 : 0,
                  onChanged: (i) => setState(() => _map = i == 1)),
            ]),
          ),
          if (state.offline)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Pill('📡 Sin conexión · mostrando lo guardado', bg: const Color(0xCC1E1B23), fg: Colors.white),
            ),
          if (!_map)
            Expanded(
              child: RefreshIndicator(
                onRefresh: state.refreshContacts,
                child: nights.isEmpty
                    ? ListView(padding: const EdgeInsets.fromLTRB(28, 80, 28, 100), children: [
                        const Center(child: Text('📸', style: TextStyle(fontSize: 48))),
                        const SizedBox(height: 12),
                        Text('Tu muro está vacío', textAlign: TextAlign.center, style: display(20, color: ink)),
                        const SizedBox(height: 8),
                        Text('Escanea el QR de alguien y su foto aparece aquí, con el lugar y la noche.',
                            textAlign: TextAlign.center, style: body(15, color: ink.withValues(alpha: 0.75))),
                      ])
                    : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 110), children: [
                        Row(children: [
                          Pill('${state.contacts.length} ${state.contacts.length == 1 ? 'persona' : 'personas'}',
                              bg: const Color(0x33000000), fg: Colors.white),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _chooseWall,
                            icon: Icon(Icons.palette_outlined, color: ink, size: 18),
                            label: Text('Fondo', style: body(14, color: ink, weight: FontWeight.w700)),
                          ),
                        ]),
                        for (var i = 0; i < nights.length; i++) _night(nights[i], _titleColors[i % 4], wall),
                      ]),
              ),
            ),
        ]),
      ),
    ]);
  }

  Widget _night(Night n, Color color, String wall) {
    final titleColor = wall == 'corcho' ? WallBackground.inkOn(wall) : color;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(n.title, style: hand(22, color: titleColor))),
          if (n.people.length >= 2)
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecapScreen(night: n))),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x33000000),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
              ),
              child: Text('📸 Resumen', style: body(13, color: Colors.white, weight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, box) {
          final w = ((box.maxWidth - 24) / 3).clamp(80.0, 120.0);
          return Wrap(spacing: 12, runSpacing: 14, children: [
            for (final c in n.people)
              Semantics(
                button: true,
                label: c.profile.displayName,
                child: GestureDetector(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ContactScreen(contactId: c.profile.id))),
                  child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                    PersonPolaroid(
                      id: c.profile.id,
                      name: c.profile.displayName,
                      photoUrl: c.selfieUrl ?? c.profile.avatarUrl,
                      width: w,
                      frame: c.profile.style.frame,
                      angle: tiltFor(c.profile.id, max: 4),
                    ),
                    if (wall == 'corcho' || wall == 'ladrillo')
                      Positioned(
                        top: -6,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: [Pal.pink, Pal.green, Pal.yellow][c.profile.id.length % 3],
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
                          ),
                        ),
                      ),
                    if (c.note.isNotEmpty)
                      const Positioned(right: -6, bottom: 8, child: Text('📝', style: TextStyle(fontSize: 18))),
                  ]),
                ),
              ),
          ]);
        }),
      ]),
    );
  }
}
