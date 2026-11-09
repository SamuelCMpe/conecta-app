import 'dart:ui';

import 'package:flutter/material.dart';

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

class HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void goTo(int tab) => setState(() => _tab = tab);

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Perfil'),
    (Icons.qr_code_scanner, Icons.qr_code_scanner, 'Escanear'),
    (Icons.photo_library_outlined, Icons.photo_library_rounded, 'Mi muro'),
    (Icons.tune, Icons.tune, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
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
