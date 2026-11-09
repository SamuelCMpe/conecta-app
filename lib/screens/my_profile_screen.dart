import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/polaroid.dart';
import '../widgets/profile_card.dart';
import 'my_qr_screen.dart';
import 'polaroid_editor_screen.dart';

/// Mi perfil tal como lo ven los demás: mi polaroid con stickers y mis redes.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me;
    if (me == null) return const Center(child: CircularProgressIndicator());

    return BlurredPhotoBackground(
      url: me.avatarUrl,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (box.maxHeight - 108).clamp(0, double.infinity)),
              child: IntrinsicHeight(
                child: Column(children: [
                  Row(children: [
                    Text('conecta', style: display(18)),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: 'Mostrar mi QR',
                      child: Material(
                        color: Pal.yellow,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(fullscreenDialog: true, builder: (_) => const MyQrScreen()),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.qr_code_2, color: Pal.ink, size: 20),
                              const SizedBox(width: 6),
                              Text('Mi QR', style: body(14, color: Pal.ink, weight: FontWeight.w800)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const Spacer(),
                  const SizedBox(height: 28),
                  ProfilePolaroid(
                    profile: me,
                    width: 270,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PolaroidEditorScreen(initial: me)),
                    ),
                  ),
                  const SizedBox(height: 26),
                  ProfileDetails(profile: me),
                  const Spacer(),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
