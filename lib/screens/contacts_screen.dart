import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'other_profile_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  String _when(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'hoy';
    if (diff.inDays == 1) return 'ayer';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _relation(Contact c) {
    if (c.revoked) return 'Ya no puede ver tu perfil';
    final r = switch (c.relation) {
      'mutuo' => 'Se conocieron',
      'te_escaneo' => 'Te escaneó',
      _ => 'Lo escaneaste',
    };
    return '$r · ${_when(c.since)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ColoredBox(
      color: const Color(0xFFF6F7FB),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: state.refreshContacts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Text('Contactos', style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              for (final r in state.requests) _RequestCard(request: r),
              if (state.contacts.isEmpty && state.requests.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text('Todavía no tienes contactos. Escanea el QR de alguien para empezar.',
                      textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5B5E6B))),
                ),
              if (state.contacts.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10, top: 6),
                  child: Text('RECIENTES',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B5E6B), letterSpacing: 0.6)),
                ),
              for (final c in state.contacts)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE6E7EE)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Avatar(profile: c.profile, size: 40),
                    title: Text(c.profile.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_relation(c), style: const TextStyle(fontSize: 12)),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => OtherProfileScreen(profile: c.profile))),
                    trailing: c.relation == 'escaneaste'
                        ? null
                        : TextButton(
                            onPressed: () => state.toggleRevoked(c),
                            style: TextButton.styleFrom(
                              foregroundColor: c.revoked ? const Color(0xFF4B3BEF) : const Color(0xFFB42318),
                            ),
                            child: Text(c.revoked ? 'Devolver acceso' : 'Quitar acceso', style: const TextStyle(fontSize: 12)),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ContactRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9D4FF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Avatar(profile: request.from, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${request.from.displayName} te envió su perfil', style: const TextStyle(fontWeight: FontWeight.w600)),
              const Text('Escaneó tu QR', style: TextStyle(fontSize: 13, color: Color(0xFF5B5E6B))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () => state.respond(request, true), child: const Text('Aceptar'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: () => state.respond(request, false), child: const Text('Rechazar'))),
        ]),
      ]),
    );
  }
}
