import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/profile_look.dart';
import '../widgets/common.dart';
import '../widgets/profile_view.dart';
import 'my_qr_screen.dart';

/// Mi perfil tal como lo ven los demás. Arriba, un botón pequeño abre mi QR.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me;
    if (me == null) return const Center(child: CircularProgressIndicator());
    final look = ProfileLook(me.style);

    return ProfileView(
      profile: me,
      topBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Semantics(
          button: true,
          label: 'Mostrar mi QR',
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(fullscreenDialog: true, builder: (_) => const MyQrScreen(active: true)),
            ),
            child: Glass(
              color: look.glass,
              border: Border.all(color: look.glassBorder),
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.qr_code_2, size: 20, color: look.text),
                const SizedBox(width: 6),
                Text('Mi QR', style: TextStyle(color: look.text, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ]),
      footer: const [SizedBox(height: 80)],
    );
  }
}
