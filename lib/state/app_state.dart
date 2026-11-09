import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../models/profile.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  final AppRepository repo;
  final LocationService location;
  AppState(this.repo, {LocationService? location})
      : location = location ?? (repo.isDemo ? const FakeLocationService() : DeviceLocationService());

  Profile? me;
  List<Contact> contacts = [];
  bool loading = false;

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
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshContacts() async {
    contacts = await repo.loadContacts();
    notifyListeners();
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
  Future<Profile> scan(String token) async {
    final place = await location.currentPlace();
    final p = await repo.redeemQrToken(token, place: place);
    await refreshContacts();
    return p;
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
    if (isVisible) await repo.setVisible(null);
    await repo.signOut();
    me = null;
    contacts = [];
    nearby = [];
    visibleUntil = null;
    notifyListeners();
  }
}
