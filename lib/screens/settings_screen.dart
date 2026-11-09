import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/polaroid.dart';
import 'polaroid_editor_screen.dart';

/// Ajustes: diseñar mi polaroid, mis datos, mis redes, privacidad y cuenta.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;
    if (me == null) return const SizedBox();

    void edit(int tab) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PolaroidEditorScreen(initial: me, initialTab: tab)));

    Widget group(String title, List<Widget> tiles) => Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(title, style: hand(18, color: Pal.yellow)),
            ),
            Container(
              decoration: BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 64, color: Pal.line),
                  tiles[i],
                ],
              ]),
            ),
          ]),
        );

    Widget tile(String emoji, String title, String subtitle, VoidCallback onTap) => ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Pal.glass, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 19)),
          ),
          title: Text(title, style: body(16, weight: FontWeight.w700)),
          subtitle: Text(subtitle, style: body(13, color: Pal.muted)),
          trailing: const Icon(Icons.chevron_right, color: Pal.muted),
          onTap: onTap,
        );

    return ColoredBox(
      color: Pal.bg,
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 110), children: [
          Text('Ajustes', style: display(26)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => edit(0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                Polaroid(
                  width: 82,
                  angle: -4,
                  frame: me.style.frame,
                  caption: me.displayName.split(' ').first,
                  photo: PhotoBox(url: me.avatarUrl, name: me.displayName, id: me.id),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(me.displayName.isEmpty ? 'Tu nombre' : me.displayName,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: body(19, weight: FontWeight.w800)),
                    if (me.username.isNotEmpty) Text('@${me.username}', style: body(14, color: Pal.muted)),
                    const SizedBox(height: 10),
                    const Sticker('✏️ Diseñar mi polaroid', size: 12.5),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          group('Mi polaroid', [
            tile('✨', 'Stickers', 'Hasta 3 sobre tu foto', () => edit(0)),
            tile('🖼️', 'Marco', 'Blanco, rosa, crema, menta o negro', () => edit(1)),
            tile('📷', 'Foto', 'De tu galería o una nueva', () => edit(2)),
          ]),
          group('Mi perfil', [
            tile('🪪', 'Mis datos', 'Nombre, usuario, frase y gustos', () => edit(3)),
            tile('💬', 'Mis redes', 'WhatsApp, Instagram, TikTok y más', () => edit(4)),
          ]),
          group('Privacidad', [
            tile('🔒', 'Cómo funciona', 'Quién ve tus redes y tu ubicación', () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Pal.card,
                isScrollControlled: true,
                builder: (_) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                    child: Text(
                      '• Tus redes solo las ve quien escanea tu QR en persona. Mostrar tu QR es dar tu permiso.\n\n'
                      '• Tu QR cambia cada 30 segundos: una foto o captura deja de servir.\n\n'
                      '• Al escanear se guarda el barrio donde se conocieron (nunca tu dirección exacta) y lo ven solo ustedes dos.\n\n'
                      '• En Cerca de ti solo apareces si activas Visible, y se apaga solo en 2 horas. Ahí se ve tu foto, tu nombre y un sticker, nunca tus redes.\n\n'
                      '• Tus notas sobre otras personas solo las ves tú.\n\n'
                      '• Desde el perfil de cualquiera puedes quitarle el acceso, bloquearlo o reportarlo.',
                      style: body(15, height: 1.4),
                    ),
                  ),
                ),
              );
            }),
          ]),
          group('Cuenta', [
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFFF8FB1)),
              title: Text('Cerrar sesión', style: body(16, color: const Color(0xFFFF8FB1), weight: FontWeight.w700)),
              onTap: state.signOut,
            ),
          ]),
        ]),
      ),
    );
  }
}
