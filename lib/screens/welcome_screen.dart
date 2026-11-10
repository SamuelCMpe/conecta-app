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
                  const SizedBox(height: 372, child: _Collage()),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Transform.rotate(
                          angle: -0.07,
                          child: Image.asset('assets/logo/logo.png', width: 48, height: 48),
                        ),
                        const SizedBox(width: 12),
                        Text('conecta', style: display(40)),
                      ]),
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
            left: w * 0.04, top: 18, child: const PersonPolaroid(id: 'maria', name: 'María', width: 140, angle: -10)),
        Positioned(
            right: w * 0.04, top: 8, child: const PersonPolaroid(id: 'juan', name: 'Juan', width: 134, angle: 8)),
        Positioned(
          left: w / 2 - 80,
          top: 168,
          child: const Polaroid(
            width: 160,
            angle: -2,
            caption: 'yo ✌️',
            photo: PhotoBox(url: 'assets/backgrounds/oceano.jpg', name: 'yo', id: 'yo'),
          ),
        ),
        Positioned(left: w * 0.03, top: 286, child: const Sticker('📍 Barranco', angle: -8)),
        Positioned(right: w * 0.03, top: 236, child: const Sticker('¡nos vemos! 🎉', color: 1, angle: 10)),
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
  String? _error;

  @override
  void initState() {
    super.initState();
    // Si ya se mandó el enlace y la hoja se cerró sin querer, se vuelve a la pantalla de "Revisa tu correo".
    final state = context.read<AppState>();
    final pending = state.pendingLoginEmail;
    if (pending != null && state.repo.usesEmailLink) {
      _email.text = pending;
      _codeSent = true;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f();
    } catch (e) {
      // El error se muestra dentro de la hoja (un aviso abajo quedaría tapado por ella).
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final demo = state.repo.isDemo;
    final link = state.repo.usesEmailLink;

    // Al tocar el enlace del correo la sesión entra sola: se cierra esta hoja.
    if (state.signedIn && state.me != null && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }

    if (link && _codeSent) {
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 26, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('📬', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text('Revisa tu correo', style: display(22)),
          const SizedBox(height: 8),
          Text(
            'Te enviamos un enlace a ${_email.text.trim()}. Ábrelo en este celular y toca "Sign in": la app se abre sola y ya entras.',
            style: body(15, color: Pal.muted, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text('Si no llega en un minuto, mira en Spam o Promociones.', style: body(13, color: Pal.muted)),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Text(_error!, style: body(14, color: Pal.pink, height: 1.35)),
            const SizedBox(height: 12),
          ],
          if (state.loading)
            const Center(child: CircularProgressIndicator(color: Pal.yellow))
          else
            BigButton(
              _busy ? 'Un momento…' : 'Reenviar enlace',
              color: const Color(0x24FFFFFF),
              textColor: Pal.text,
              onTap: _busy ? null : () => _run(() => state.repo.sendLoginCode(_email.text.trim())),
            ),
          TextButton(
            onPressed: () {
              context.read<AppState>().pendingLoginEmail = null;
              setState(() => _codeSent = false);
            },
            child: Text('Usar otro correo', style: body(14, color: Pal.muted)),
          ),
        ]),
      );
    }

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
                  : (link
                      ? 'Te enviamos un enlace para entrar. Sin contraseñas.'
                      : 'Te enviamos un código para entrar. Sin contraseñas.'),
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
        if (_error != null) ...[
          Text(_error!, style: body(14, color: Pal.pink, height: 1.35)),
          const SizedBox(height: 12),
        ],
        BigButton(
          _busy ? 'Un momento…' : (_codeSent ? 'Entrar' : (link ? 'Enviar enlace' : 'Enviar código')),
          onTap: _busy
              ? null
              : () => _run(() async {
                    if (!_codeSent) {
                      final email = _email.text.trim();
                      if (!email.contains('@')) throw Exception('Escribe un correo válido.');
                      await state.repo.sendLoginCode(email);
                      state.pendingLoginEmail = email;
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
