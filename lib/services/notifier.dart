import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Avisos en el celular: saludos, escaneos y el recordatorio del día siguiente.
abstract class Notifier {
  Future<void> init();

  /// Muestra un aviso ahora.
  Future<void> show(String title, String body);

  /// Programa (o reemplaza) el recordatorio "Anoche conociste a…".
  Future<void> scheduleRecap(DateTime at, String title, String body);
}

/// No muestra nada (pruebas).
class SilentNotifier implements Notifier {
  final List<String> shown = [];
  final List<(DateTime, String)> scheduled = [];
  @override
  Future<void> init() async {}
  @override
  Future<void> show(String title, String body) async => shown.add(body);
  @override
  Future<void> scheduleRecap(DateTime at, String title, String body) async => scheduled.add((at, body));
}

class DeviceNotifier implements Notifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _nextId = 100;

  static const _recapId = 1;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails('conecta', 'Conecta',
        channelDescription: 'Saludos, escaneos y el resumen de tu noche',
        importance: Importance.high,
        priority: Priority.high),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      _ready = true;
    } catch (e) {
      debugPrint('Avisos no disponibles: $e');
    }
  }

  @override
  Future<void> show(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(id: _nextId++, title: title, body: body, notificationDetails: _details);
    } catch (e) {
      debugPrint('No se pudo mostrar el aviso: $e');
    }
  }

  @override
  Future<void> scheduleRecap(DateTime at, String title, String body) async {
    if (!_ready || kIsWeb) return;
    try {
      await _plugin.zonedSchedule(
        id: _recapId,
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('No se pudo programar el recordatorio: $e');
    }
  }
}
