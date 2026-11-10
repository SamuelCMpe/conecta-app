import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../theme/polaroid.dart';
import 'contact_screen.dart';

/// Después de escanear un QR de grupo: todos los del grupo, ya conectados contigo.
class GroupJoinedScreen extends StatelessWidget {
  final List<Profile> people;
  const GroupJoinedScreen({super.key, required this.people});

  @override
  Widget build(BuildContext context) {
    final n = people.length;
    return Scaffold(
      backgroundColor: Pal.bg,
      body: Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.5),
              radius: 0.9,
              colors: [Color(0x663DDC97), Color(0x003DDC97)],
            ),
          ),
        ),
        SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
            Row(children: [
              RoundIconButton(Icons.close, tooltip: 'Cerrar', onTap: () => Navigator.of(context).maybePop()),
              const Spacer(),
            ]),
            const SizedBox(height: 14),
            const Center(child: Sticker('👯 modo grupo', color: 2, angle: -4)),
            const SizedBox(height: 14),
            Text('¡Te uniste al grupo!', textAlign: TextAlign.center, style: display(28)),
            const SizedBox(height: 8),
            Text(
              n == 0
                  ? 'Eres el primero en escanear. Los que se unan después aparecerán en tu muro.'
                  : 'Quedaste conectado con ${n == 1 ? '1 persona' : '$n personas'}. Ellos también ven tu perfil.',
              textAlign: TextAlign.center,
              style: body(15, color: Pal.muted, height: 1.4),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(builder: (context, box) {
              final w = ((box.maxWidth - 24) / 3).clamp(84.0, 120.0);
              return Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 16, children: [
                for (final p in people)
                  Semantics(
                    button: true,
                    label: p.displayName,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => ContactScreen(contactId: p.id))),
                      child: PersonPolaroid(
                        id: p.id,
                        name: p.displayName.split(' ').first,
                        photoUrl: p.avatarUrl,
                        width: w,
                        frame: p.style.frame,
                        angle: tiltFor(p.id, max: 5),
                      ),
                    ),
                  ),
              ]);
            }),
            const SizedBox(height: 30),
            BigButton('Listo 🙌', onTap: () => Navigator.of(context).maybePop()),
          ]),
        ),
      ]),
    );
  }
}
