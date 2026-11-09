import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_conecta/data/demo_repository.dart';
import 'package:qr_conecta/data/repository.dart';
import 'package:qr_conecta/main.dart';
import 'package:qr_conecta/models/networks.dart';
import 'package:qr_conecta/screens/editor_screen.dart';
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
      expect(networkById('ig').linkFor('https://www.instagram.com/maria.lopez/?hl=es'), 'https://instagram.com/maria.lopez');
    });
    test('vacío no genera enlace', () {
      expect(networkById('fb').linkFor('  '), isNull);
    });
  });

  test('el QR solo acepta códigos de la app', () {
    expect(tokenFromPayload('qrconecta:abc123'), 'abc123');
    expect(tokenFromPayload('https://otra-cosa.com'), isNull);
  });

  testWidgets('modo demo: entrar, ver perfil, editar el nombre y ver contactos', (tester) async {
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
    expect(find.text('Entrar con mi correo'), findsOneWidget);

    await tester.tap(find.text('Entrar con mi correo'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'yo@correo.com');
    await tester.tap(find.text('Enviar código'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Entrar'));
    await settle(tester);

    expect(find.text('Samuel Calderón'), findsOneWidget);
    expect(find.text('Personalizar'), findsOneWidget);

    await tester.tap(find.text('Personalizar'));
    await settle(tester);
    expect(find.byType(EditorScreen), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nombre que se muestra'), 'Samuel C.');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await settle(tester);
    expect(state.me!.displayName, 'Samuel C.');

    await tester.tap(find.text('Contactos'));
    await settle(tester);
    expect(find.text('Juan Ríos te envió su perfil'), findsOneWidget);
    await tester.tap(find.text('Aceptar'));
    await settle(tester);
    expect(find.text('Juan Ríos'), findsOneWidget);
  });
}
