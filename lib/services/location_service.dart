import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/profile.dart';

/// Averigua el barrio donde estás, solo cuando se escanea o se activa "Visible".
/// Pide ubicación aproximada y solo mientras se usa la app.
abstract class LocationService {
  /// null si la persona dijo que no o no se pudo (entonces se escribe a mano).
  Future<MeetPlace?> currentPlace();
}

class DeviceLocationService implements LocationService {
  @override
  Future<MeetPlace?> currentPlace() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 8)),
      );
      return MeetPlace(await _placeName(pos.latitude, pos.longitude), lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      debugPrint('Ubicación no disponible: $e');
      return null;
    }
  }

  /// Barrio o distrito; si no hay, la ciudad.
  Future<String> _placeName(double lat, double lng) async {
    try {
      final marks = await Geocoding(locale: const Locale('es')).placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return '';
      final m = marks.first;
      for (final v in [m.subLocality, m.locality, m.subAdministrativeArea, m.administrativeArea]) {
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
    } catch (_) {}
    return '';
  }
}

/// Para el modo demo y las pruebas: siempre "Barranco".
class FakeLocationService implements LocationService {
  final MeetPlace? place;
  const FakeLocationService([this.place = const MeetPlace('Barranco', lat: -12.1493, lng: -77.0222)]);
  @override
  Future<MeetPlace?> currentPlace() async => place;
}
