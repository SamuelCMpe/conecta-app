import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../theme/profile_look.dart';
import '../widgets/common.dart';
import '../widgets/profile_view.dart';

/// El perfil de otra persona, con el diseño que ella eligió.
class OtherProfileScreen extends StatelessWidget {
  final Profile profile;
  final bool justScanned;
  const OtherProfileScreen({super.key, required this.profile, this.justScanned = false});

  @override
  Widget build(BuildContext context) {
    final look = ProfileLook(profile.style);
    return Scaffold(
      body: ProfileView(
        profile: profile,
        topBar: Row(children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Glass(
              color: look.glass,
              border: Border.all(color: look.glassBorder),
              radius: 22,
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.arrow_back, color: look.text, semanticLabel: 'Volver'),
            ),
          ),
        ]),
        footer: [
          if (justScanned)
            Glass(
              color: look.glass,
              border: Border.all(color: look.glassBorder),
              radius: 16,
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.swap_horiz, color: Color(0xFF8FE3B4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Le enviaste tu perfil. Lo verá cuando lo acepte.',
                      style: TextStyle(color: look.text, fontSize: 13)),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
