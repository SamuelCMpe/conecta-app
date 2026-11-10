import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository.dart';
import '../models/nights.dart';
import '../models/profile.dart';
import '../services/location_service.dart';
import '../services/notifier.dart';

/// Lo que pasó al escanear: una persona o un grupo entero.
class ScanResult {
  final List<Profile> people;
  final bool group;
  const ScanResult(this.people, {this.group = false});
}

class AppState extends ChangeNotifier {
  final AppRepository repo;
  final LocationService location;
  final Notifier notifier;
  AppState(this.repo, {LocationService? location, Notifier? notifier})
      : location = location ?? (repo.isDemo ? const FakeLocationService() : DeviceLocationService()),
        notifier = notifier ?? DeviceNotifier();

  Profile? me;
  List<Contact> contacts = [];
  bool loading = false;

  /// true si no hay internet y se muestra lo guardado en el celular.
  bool offline = false;

  /// Correo al que se mandó el enlace para entrar (para no perderlo si se cierra la hoja).
  String? pendingLoginEmail;

  /// "Cerca de ti": hasta cuándo estoy visible (null = apagado) y dónde.
  DateTime? visibleUntil;
  MeetPlace? visiblePlace;
  List<NearbyPerson> nearby = [];

  bool get signedIn => repo.isSignedIn;
  bool get isVisible => visibleUntil != null && visibleUntil!.isAfter(DateTime.now());

  Future<void> loadAll() async {
    if (!repo.isSignedIn) return;
    loading = true;
    notifyListeners();
    try {
      me = await repo.loadMyProfile();
      contacts = await repo.loadContacts();
      offline = false;
      pendingLoginEmail = null;
      await _saveCache();
    } catch (e) {
      // Sin conexión: se muestra lo último guardado.
      if (!await _loadCache()) rethrow;
      offline = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshContacts() async {
    try {
      contacts = await repo.loadContacts();
      offline = false;
      await _saveCache();
    } catch (e) {
      if (contacts.isEmpty && !await _loadCache()) rethrow;
      offline = true;
    }
    notifyListeners();
  }

  // ---------- Guardado en el celular ----------
  static const _cacheKey = 'conecta_cache_v1';

  Future<void> _saveCache() async {
    final uid = repo.userId;
    if (uid == null || me == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _cacheKey,
          jsonEncode({
            'uid': uid,
            'me': me!.toRow(),
            'contacts': [for (final c in contacts) c.toJson()],
          }));
    } catch (e) {
      debugPrint('No se pudo guardar el muro: $e');
    }
  }

  Future<bool> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return false;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['uid'] != repo.userId) return false;
      me = Profile.fromRow((j['me'] as Map).cast<String, dynamic>());
      contacts = [for (final c in j['contacts'] as List) Contact.fromJson((c as Map).cast<String, dynamic>())];
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_activityKey);
    } catch (_) {}
  }

  Contact? contactById(String id) {
    for (final c in contacts) {
      if (c.profile.id == id) return c;
    }
    return null;
  }

  /// Guarda el perfil; sube primero la foto si todavía es un archivo local.
  Future<void> saveProfile(Profile p) async {
    var profile = p;
    final avatar = profile.avatarUrl;
    if (avatar != null && avatar.isNotEmpty && !avatar.startsWith('http')) {
      profile = profile.copyWith(avatarUrl: await repo.uploadImage(avatar, kind: 'avatar'));
    }
    await repo.saveMyProfile(profile);
    me = profile;
    notifyListeners();
  }

  /// Escanea: toma el barrio en ese momento y lo guarda para los dos.
  /// Si es un QR de grupo, te conecta con todos los del grupo.
  Future<ScanResult> scan(String token) async {
    final place = await location.currentPlace();
    final ScanResult result;
    if (token.startsWith(kGroupPrefix)) {
      final people = await repo.joinGroup(token.substring(kGroupPrefix.length), place: place);
      result = ScanResult(people, group: true);
    } else {
      result = ScanResult([await repo.redeemQrToken(token, place: place)]);
    }
    await refreshContacts();
    await _scheduleRecap();
    return result;
  }

  // ---------- Modo grupo ----------
  Future<QrToken> createGroup() async {
    final place = await location.currentPlace();
    return repo.createGroup(place: place);
  }

  // ---------- Avisos ----------
  static const _activityKey = 'conecta_last_activity';
  Timer? _activityTimer;
  bool _notifierReady = false;

  /// Revisa avisos nuevos cada 30 s mientras la app está abierta.
  Future<void> startActivity() async {
    if (!repo.isSignedIn) return;
    if (!_notifierReady) {
      _notifierReady = true;
      await notifier.init();
    }
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(seconds: 30), (_) => checkActivity());
    await checkActivity();
  }

  void stopActivity() {
    _activityTimer?.cancel();
    _activityTimer = null;
  }

  Future<void> checkActivity() async {
    if (!repo.isSignedIn) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_activityKey);
      final items = await repo.loadActivity(last ?? 0);
      if (items.isEmpty) return;
      await prefs.setInt(_activityKey, items.last.id);
      // La primera vez solo se marca lo viejo como visto.
      if (last == null) return;
      for (final a in items.take(3)) {
        await notifier.show('Conecta', a.message);
      }
      if (items.any((a) => a.kind != 'wave')) await refreshContacts();
      if (items.any((a) => a.kind == 'wave') && isVisible) await refreshNearby();
    } catch (e) {
      debugPrint('No se pudieron revisar los avisos: $e');
    }
  }

  /// Al día siguiente a mediodía: "Anoche conociste a N personas en …".
  Future<void> _scheduleRecap() async {
    final now = DateTime.now();
    final night = Night.nightOf(now);
    final tonight = Night.group(contacts).where((n) => n.day == night).toList();
    if (tonight.isEmpty) return;
    final count = tonight.fold<int>(0, (s, n) => s + n.people.length);
    final place = tonight.first.place;
    final at = DateTime(night.year, night.month, night.day + 1, 12);
    if (!at.isAfter(now)) return;
    final who = count == 1 ? 'a 1 persona' : 'a $count personas';
    await notifier.scheduleRecap(
      at,
      'Tu noche en Conecta 📸',
      'Anoche conociste $who${place.isEmpty ? '' : ' en $place'}. Mira el resumen y súbelo a tus historias.',
    );
  }

  Future<void> toggleRevoked(Contact c) async {
    await repo.setAccessRevoked(c.profile.id, !c.revoked);
    await refreshContacts();
  }

  Future<void> saveNote(Contact c, String note) async {
    await repo.saveNote(c.profile.id, note.trim());
    await refreshContacts();
  }

  Future<void> savePlace(Contact c, String place) async {
    await repo.savePlace(c.profile.id, place.trim());
    await refreshContacts();
  }

  Future<void> saveSelfie(String contactId, String localPath) async {
    final url = await repo.uploadImage(localPath, kind: 'selfie');
    await repo.saveSelfie(contactId, url);
    await refreshContacts();
  }

  // ---------- Cerca de ti ----------

  /// Devuelve false si no se pudo saber dónde estás.
  Future<bool> setVisible(bool on) async {
    if (!on) {
      await repo.setVisible(null);
      visibleUntil = null;
      nearby = [];
      notifyListeners();
      return true;
    }
    final place = await location.currentPlace();
    if (place == null || !place.hasCoords) return false;
    await repo.setVisible(place);
    visiblePlace = place;
    visibleUntil = DateTime.now().add(const Duration(hours: 2));
    await refreshNearby();
    return true;
  }

  Future<void> refreshNearby() async {
    final place = visiblePlace;
    if (!isVisible || place == null) {
      nearby = [];
    } else {
      nearby = await repo.loadNearby(place);
    }
    notifyListeners();
  }

  Future<void> wave(NearbyPerson p) async {
    await repo.sendWave(p.id);
    nearby = [for (final n in nearby) n.id == p.id ? n.copyWith(iWaved: true) : n];
    notifyListeners();
  }

  Future<void> block(String userId) async {
    await repo.block(userId);
    nearby = nearby.where((n) => n.id != userId).toList();
    await refreshContacts();
  }

  Future<void> report(String userId, String reason) => repo.report(userId, reason);

  Future<void> signOut() async {
    stopActivity();
    if (isVisible) await repo.setVisible(null);
    await repo.signOut();
    await _clearCache();
    offline = false;
    me = null;
    contacts = [];
    nearby = [];
    visibleUntil = null;
    notifyListeners();
  }
}
