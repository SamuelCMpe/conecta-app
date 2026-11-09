import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/profile_look.dart';
import '../widgets/common.dart';
import '../widgets/profile_view.dart';
import 'editor_screen.dart';

class MyProfileScreen extends StatelessWidget {
  final VoidCallback onShowQr;
  const MyProfileScreen({super.key, required this.onShowQr});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;
    if (me == null) return const Center(child: CircularProgressIndicator());
    final look = ProfileLook(me.style);

    return ProfileView(
      profile: me,
      topBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_horiz, color: look.text),
          onSelected: (v) {
            if (v == 'salir') state.signOut();
          },
          itemBuilder: (_) => const [PopupMenuItem(value: 'salir', child: Text('Cerrar sesión'))],
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditorScreen(initial: me))),
          child: Glass(
            color: look.glass,
            border: Border.all(color: look.glassBorder),
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit_outlined, size: 18, color: look.text),
              const SizedBox(width: 8),
              Text('Personalizar', style: TextStyle(color: look.text, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
      footer: [
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: look.accent,
              foregroundColor: look.onAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: onShowQr,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Mostrar mi QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
