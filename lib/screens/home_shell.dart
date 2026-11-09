import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'contacts_screen.dart';
import 'my_profile_screen.dart';
import 'my_qr_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

/// Pantalla principal con la barra de abajo.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void goTo(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<AppState>().requests.length;
    final pages = [
      MyProfileScreen(onShowQr: () => goTo(1)),
      MyQrScreen(active: _tab == 1),
      ScannerScreen(active: _tab == 2),
      const ContactsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: goTo,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          const NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'Mi QR'),
          const NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          NavigationDestination(
            icon: Badge(isLabelVisible: requests > 0, label: Text('$requests'), child: const Icon(Icons.people_outline)),
            selectedIcon: const Icon(Icons.people),
            label: 'Contactos',
          ),
          const NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
        ],
      ),
    );
  }
}
