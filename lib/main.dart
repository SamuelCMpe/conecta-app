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
import 'theme/polaroid.dart';

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
  if (!repo.isDemo) {
    // Al tocar el enlace del correo, la app se abre y la sesión llega por aquí.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && state.me == null) {
        state.loadAll().catchError((_) {});
      }
    });
  }
  try {
    await state.loadAll();
  } catch (e) {
    // Sin internet y sin nada guardado: la app abre igual y se reintenta luego.
    debugPrint('No se pudo cargar: $e');
  }
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
        title: 'Conecta',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Pal.bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Pal.yellow,
            brightness: Brightness.dark,
            primary: Pal.yellow,
            onPrimary: Pal.ink,
            surface: Pal.card,
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0x14FFFFFF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
          useMaterial3: true,
        ),
        home: Consumer<AppState>(
          builder: (context, s, _) => s.signedIn ? const HomeShell() : const WelcomeScreen(),
        ),
      ),
    );
  }
}
