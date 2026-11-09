import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/profile_look.dart';
import '../widgets/common.dart';
import 'editor_screen.dart';
import 'qr_design_screen.dart';

/// Configuración: aquí se cambia todo (datos, diseño del perfil, redes, QR y cuenta).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;
    if (me == null) return const SizedBox();

    void openEditor(int tab) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditorScreen(initial: me, initialTab: tab)));

    Widget group(String title, List<Widget> tiles) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B5E6B), letterSpacing: 0.6)),
            ),
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE6E7EE))),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 60),
                  tiles[i],
                ],
              ]),
            ),
          ]),
        );

    Widget tile(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) => ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    return ColoredBox(
      color: const Color(0xFFF6F7FB),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text('Configuración', style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // Tarjeta con mi perfil en miniatura
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 120,
                child: ProfileBackground(
                  style: me.style,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Avatar(profile: me, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(me.displayName.isEmpty ? 'Tu nombre' : me.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ProfileLook(me.style).titleFont(size: 22)),
                              if (me.username.isNotEmpty)
                                Text('@${me.username}', style: TextStyle(color: ProfileLook(me.style).subtext)),
                            ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            group('Mi perfil', [
              tile(Icons.badge_outlined, const Color(0xFF4B3BEF), 'Mis datos', 'Nombre, usuario, descripción, gustos',
                  () => openEditor(0)),
              tile(Icons.share_outlined, const Color(0xFF25A36A), 'Mis redes', 'WhatsApp, Instagram, Facebook y más',
                  () => openEditor(4)),
            ]),
            group('Diseño', [
              tile(Icons.wallpaper_outlined, const Color(0xFFE5733D), 'Fondo', 'Tu imagen, degradados y patrones',
                  () => openEditor(1)),
              tile(Icons.account_circle_outlined, const Color(0xFFDD2A7B), 'Foto de perfil', 'Foto, forma y aro',
                  () => openEditor(2)),
              tile(Icons.palette_outlined, const Color(0xFF8134AF), 'Estilo', 'Letra, botones y color',
                  () => openEditor(3)),
              tile(Icons.qr_code_2, const Color(0xFF12131A), 'Diseño del QR', 'Colores y forma de tu código',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QrDesignScreen(initial: me)))),
            ]),
            group('Privacidad', [
              tile(Icons.lock_outline, const Color(0xFF0B4A7A), 'Cómo funciona', 'Quién puede ver tus redes', () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Text(
                      '• Solo ve tus redes quien escanea tu QR en persona. Mostrar tu QR es dar tu permiso.\n\n'
                      '• Tu QR cambia cada 30 segundos, así una foto o captura deja de servir.\n\n'
                      '• Al escanear, los dos ven el perfil del otro al instante y quedan en sus contactos.\n\n'
                      '• En Contactos puedes quitarle el acceso a cualquiera cuando quieras.',
                      style: TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
                );
              }),
            ]),
            group('Cuenta', [
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFB42318)),
                title: const Text('Cerrar sesión',
                    style: TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w600)),
                onTap: state.signOut,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
