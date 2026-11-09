import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_conecta/data/demo_repository.dart';
import 'package:qr_conecta/data/repository.dart';
import 'package:qr_conecta/main.dart';
import 'package:qr_conecta/models/networks.dart';
import 'package:qr_conecta/models/nights.dart';
import 'package:qr_conecta/models/profile.dart';
import 'package:qr_conecta/screens/polaroid_editor_screen.dart';
import 'package:qr_conecta/state/app_state.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 15; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('enlaces de redes', () {
    test('WhatsApp usa solo los dígitos', () {
      expect(networkById('wa').linkFor('+51 999 111 222'), 'https://wa.me/51999111222');
    });
    test('Instagram acepta @usuario o el enlace completo', () {
      expect(networkById('ig').linkFor('@maria.lopez'), 'https://instagram.com/maria.lopez');
      expect(networkById('ig').linkFor('https://www.instagram.com/maria.lopez/?hl=es'),
          'https://instagram.com/maria.lopez');
    });
    test('vacío no genera enlace', () {
      expect(networkById('fb').linkFor('  '), isNull);
    });
  });

  test('el QR solo acepta códigos de la app', () {
    expect(tokenFromPayload('qrconecta:abc123'), 'abc123');
    expect(tokenFromPayload('https://otra-cosa.com'), isNull);
  });

  test('lo de la madrugada cuenta como la noche anterior', () {
    final p = const Profile(id: 'x', displayName: 'X');
    final noche = [
      Contact(profile: p, relation: 'mutuo', since: DateTime(2026, 11, 7, 23, 30), place: 'Barranco'),
      Contact(profile: p, relation: 'mutuo', since: DateTime(2026, 11, 8, 2, 10), place: 'barranco'),
      Contact(profile: p, relation: 'mutuo', since: DateTime(2026, 11, 8, 22, 0), place: 'Miraflores'),
    ];
    final nights = Night.group(noche);
    expect(nights.length, 2);
    expect(nights.first.place, 'Miraflores');
    expect(nights.last.people.length, 2);
    expect(nights.last.day, DateTime(2026, 11, 7));
  });

  testWidgets('modo demo: entrar, diseñar la polaroid, escanear, nota y cerca de ti', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    FlutterError.onError = (d) {
      // Las fuentes de Google no se descargan en pruebas; ignoramos solo ese aviso.
      if (d.exceptionAsString().contains('GoogleFonts') || d.exceptionAsString().contains('google_fonts')) return;
      FlutterError.presentError(d);
    };

    final state = AppState(DemoRepository());
    await tester.pumpWidget(QrConectaApp(state: state));
    expect(find.text('Empezar'), findsOneWidget);

    // Entrar
    await tester.tap(find.text('Empezar'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'yo@correo.com');
    await tester.tap(find.text('Enviar código'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Entrar'));
    await settle(tester);

    expect(find.text('Samuel ✌️'), findsOneWidget);
    expect(find.text('Mi QR'), findsOneWidget);

    // Ajustes > Mis datos: cambiar el nombre
    await tester.tap(find.text('Ajustes'));
    await settle(tester);
    await tester.tap(find.text('Mis datos'));
    await settle(tester);
    expect(find.byType(PolaroidEditorScreen), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Tu nombre'), 'Samu Calderón');
    await tester.pump();
    // Stickers: agregar uno (ya tiene 2, máximo 3)
    await tester.tap(find.text('Stickers'));
    await settle(tester);
    await tester.tap(find.text('🪩 de toque'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await settle(tester);
    expect(state.me!.displayName, 'Samu Calderón');
    expect(state.me!.style.stickers, contains('🪩 de toque'));
    expect(state.me!.style.stickers.length, 3);

    // Escanear: se guarda el lugar y salen sus redes
    await tester.tap(find.text('Escanear'));
    await settle(tester);
    await tester.tap(find.text('Simular escaneo'));
    await settle(tester);
    expect(find.text('¡Conectaron!'), findsOneWidget);
    expect(find.text('📍 Barranco'), findsOneWidget);
    expect(find.text('María también recibió tu perfil'), findsOneWidget);
    expect(state.contacts.first.profile.displayName, 'María López');
    expect(state.contacts.first.place, 'Barranco');

    // Su perfil: escribir una nota privada
    await tester.tap(find.text('Ver su perfil completo'));
    await settle(tester);
    await tester.tap(find.text('🔄 Mi nota'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'amiga de Juan');
    await tester.tap(find.text('Guardar nota'));
    await settle(tester);
    expect(state.contactById('demo-maria')!.note, 'amiga de Juan');
    await tester.tap(find.byTooltip('Atrás'));
    await settle(tester);

    // Cerca de ti: activar visible y saludar
    await tester.tap(find.text('Cerca de ti'));
    await settle(tester);
    await tester.ensureVisible(find.text('Activar Visible por 2 horas'));
    await settle(tester);
    await tester.tap(find.text('Activar Visible por 2 horas'));
    await settle(tester);
    expect(state.isVisible, isTrue);
    expect(find.text('Valeria'), findsOneWidget);
    await tester.ensureVisible(find.text('👋 Saludar').first);
    await settle(tester);
    await tester.tap(find.text('👋 Saludar').first);
    await settle(tester);
    expect(find.text('Saludaste ✓'), findsOneWidget);

    // Mi muro: agrupado por noche y lugar
    await tester.tap(find.text('Mi muro'));
    await settle(tester);
    expect(find.textContaining('Barranco'), findsWidgets);
    expect(find.textContaining('Miraflores'), findsWidgets);

    // Apagar Visible (detiene su temporizador) antes de terminar
    await state.setVisible(false);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
