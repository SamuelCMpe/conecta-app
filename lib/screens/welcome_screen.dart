import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/polaroid.dart';

/// Bienvenida: polaroids de gente conectando y el botón para entrar.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _login(BuildContext context, {required bool newAccount}) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Pal.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => _LoginSheet(newAccount: newAccount),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 360, child: _Collage()),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('conecta', style: display(40)),
                      const SizedBox(height: 10),
                      Text('Pasa tu QR, conoce gente y guarda el recuerdo de cada noche.',
                          style: body(19, color: const Color(0xFFE5E2EC), height: 1.35)),
                      const SizedBox(height: 28),
                      BigButton('Empezar', onTap: () => _login(context, newAccount: true)),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => _login(context, newAccount: false),
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: 'Ya tengo cuenta · ', style: body(14, color: Pal.muted)),
                            TextSpan(text: 'Entrar', style: body(14, weight: FontWeight.w800)),
                          ])),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Collage extends StatelessWidget {
  const _Collage();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      return Stack(clipBehavior: Clip.none, children: [
        Positioned(
            left: w * 0.06, top: 30, child: const PersonPolaroid(id: 'maria', name: 'María', width: 150, angle: -10)),
        Positioned(
            right: w * 0.06, top: 14, child: const PersonPolaroid(id: 'juan', name: 'Juan', width: 140, angle: 8)),
        Positioned(
          left: w / 2 - 80,
          top: 150,
          child: const Polaroid(
            width: 160,
            angle: -2,
            caption: 'yo ✌️',
            photo: PhotoBox(url: 'assets/backgrounds/oceano.jpg', name: 'yo', id: 'yo'),
          ),
        ),
        Positioned(left: w * 0.08, top: 250, child: const Sticker('📍 Barranco', angle: -8)),
        Positioned(right: w * 0.07, top: 220, child: const Sticker('¡nos vemos! 🎉', color: 1, angle: 10)),
      ]);
    });
  }
}

class _LoginSheet extends StatefulWidget {
  final bool newAccount;
  const _LoginSheet({required this.newAccount});
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
      padding: EdgeInsets.fromLTRB(24, 26, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_codeSent ? 'Revisa tu correo' : (widget.newAccount ? 'Crea tu cuenta' : 'Entra a tu cuenta'),
            style: display(22)),
        const SizedBox(height: 8),
        Text(
          demo
              ? 'Modo demo (sin servidor): escribe cualquier correo y cualquier código.'
              : _codeSent
                  ? 'Te enviamos un código de 6 dígitos a ${_email.text}.'
                  : 'Te enviamos un código para entrar. Sin contraseñas.',
          style: body(15, color: Pal.muted),
        ),
        const SizedBox(height: 18),
        if (!_codeSent)
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Correo'),
          )
        else
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Código'),
          ),
        const SizedBox(height: 18),
        BigButton(
          _busy ? 'Un momento…' : (_codeSent ? 'Entrar' : 'Enviar código'),
          onTap: _busy
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
        ),
      ]),
    );
  }
}
