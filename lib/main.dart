import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/demo_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';

/// Se pasan al ejecutar:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
/// Sin ellas la app arranca en modo demo (sin servidor).
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppRepository repo;
  if (_supabaseUrl.isNotEmpty && _supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
    repo = SupabaseRepository();
  } else {
    repo = DemoRepository();
  }
  final state = AppState(repo);
  await state.loadAll();
  runApp(QrConectaApp(state: state));
}

class QrConectaApp extends StatelessWidget {
  final AppState state;
  const QrConectaApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        title: 'QR Conecta',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B3BEF)),
          textTheme: GoogleFonts.interTextTheme(),
          useMaterial3: true,
        ),
        home: Consumer<AppState>(
          builder: (context, s, _) => s.signedIn ? const HomeShell() : const WelcomeScreen(),
        ),
      ),
    );
  }
}
