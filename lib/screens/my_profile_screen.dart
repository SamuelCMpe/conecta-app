import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/profile_look.dart';
import '../widgets/profile_view.dart';

/// Mi perfil tal como lo ven los demás. Para cambiarlo se usa la pestaña Configuración.
class MyProfileScreen extends StatelessWidget {
  final VoidCallback onShowQr;
  const MyProfileScreen({super.key, required this.onShowQr});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me;
    if (me == null) return const Center(child: CircularProgressIndicator());
    final look = ProfileLook(me.style);

    return ProfileView(
      profile: me,
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
