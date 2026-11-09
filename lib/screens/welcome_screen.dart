import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title =
        GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white, height: 1.05);
    Widget feature(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [
            Icon(icon, color: const Color(0xFFC1B8FF)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFE4E5EC), fontSize: 15))),
          ]),
        );

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/backgrounds/bokeh.jpg', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x8C0A0619), Color(0xE00A0619)],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration:
                            BoxDecoration(color: const Color(0xFF4B3BEF), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.qr_code_2, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text('Conecta',
                          style:
                              GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                    const Spacer(),
                    Text('Tus redes, solo para quien conoces en persona.', style: title),
                    const SizedBox(height: 14),
                    const Text(
                      'Muestra tu QR y comparte tu WhatsApp, Instagram y Facebook al instante. Escanea el de la otra persona y listo.',
                      style: TextStyle(color: Color(0xFFCFD0DA), fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    feature(Icons.lock_outline, 'Tu QR cambia cada 30 segundos'),
                    feature(Icons.brush_outlined, 'Foto, fondo y colores a tu gusto'),
                    feature(Icons.swap_horiz, 'Al escanear, los dos se ven al instante'),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4B3BEF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const _LoginSheet(),
                        ),
                        child: const Text('Entrar con mi correo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LoginSheet extends StatefulWidget {
  const _LoginSheet();
  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final demo = state.repo.isDemo;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_codeSent ? 'Revisa tu correo' : 'Entra o crea tu cuenta',
            style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          demo
              ? 'Modo demo (sin servidor): escribe cualquier correo y cualquier código.'
              : _codeSent
                  ? 'Te enviamos un código de 6 dígitos a ${_email.text}.'
                  : 'Te enviaremos un código para entrar. Sin contraseñas.',
          style: const TextStyle(color: Color(0xFF5B5E6B)),
        ),
        const SizedBox(height: 16),
        if (!_codeSent)
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
          )
        else
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Código', border: OutlineInputBorder()),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      if (!_codeSent) {
                        await state.repo.sendLoginCode(_email.text.trim());
                        setState(() => _codeSent = true);
                      } else {
                        await state.repo.verifyLoginCode(_email.text.trim(), _code.text.trim());
                        await state.loadAll();
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    }),
            child: Text(_codeSent ? 'Entrar' : 'Enviar código'),
          ),
        ),
      ]),
    );
  }
}
