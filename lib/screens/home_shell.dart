import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

import '../theme/polaroid.dart';
import 'my_profile_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';
import 'wall_screen.dart';

/// Pantalla principal con la barra flotante de abajo.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = context.read<AppState>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _state.startActivity();
      if (_state.me == null || _state.offline) _retry();
    });
  }

  Future<void> _retry() => _state.loadAll().catchError((_) {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.stopActivity();
    super.dispose();
  }

  /// Al volver a la app se revisan avisos y se recarga; al salir se deja de revisar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _state.startActivity();
      if (_state.me == null || _state.offline) _retry();
    } else if (s == AppLifecycleState.paused) {
      _state.stopActivity();
    }
  }

  void goTo(int tab) => setState(() => _tab = tab);

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Perfil'),
    (Icons.qr_code_scanner, Icons.qr_code_scanner, 'Escanear'),
    (Icons.photo_library_outlined, Icons.photo_library_rounded, 'Mi muro'),
    (Icons.tune, Icons.tune, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.me == null) {
      // Sin internet la primera vez: no hay nada guardado todavía.
      return Scaffold(
        backgroundColor: Pal.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: state.loading
                ? const CircularProgressIndicator(color: Pal.yellow)
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('📡', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('Sin conexión', style: display(22)),
                    const SizedBox(height: 8),
                    Text('Revisa tu internet para cargar tu perfil.',
                        textAlign: TextAlign.center, style: body(15, color: Pal.muted)),
                    const SizedBox(height: 20),
                    BigButton('Reintentar', onTap: _retry),
                  ]),
          ),
        ),
      );
    }
    final pages = [
      const MyProfileScreen(),
      ScannerScreen(active: _tab == 1),
      const WallScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      backgroundColor: Pal.bg,
      extendBody: true,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xB31E1B23),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Pal.line),
              ),
              child: Row(children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == _tab,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => goTo(i),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(i == _tab ? _items[i].$2 : _items[i].$1,
                              color: i == _tab ? Pal.yellow : Pal.muted, size: 24),
                          const SizedBox(height: 3),
                          Text(_items[i].$3,
                              style: body(11, color: i == _tab ? Pal.yellow : Pal.muted, weight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
