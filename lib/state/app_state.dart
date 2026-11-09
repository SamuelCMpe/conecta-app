import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../models/profile.dart';

class AppState extends ChangeNotifier {
  final AppRepository repo;
  AppState(this.repo);

  Profile? me;
  List<Contact> contacts = [];
  List<ContactRequest> requests = [];
  bool loading = false;

  bool get signedIn => repo.isSignedIn;

  Future<void> loadAll() async {
    if (!repo.isSignedIn) return;
    loading = true;
    notifyListeners();
    try {
      me = await repo.loadMyProfile();
      contacts = await repo.loadContacts();
      requests = await repo.loadRequests();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshContacts() async {
    contacts = await repo.loadContacts();
    requests = await repo.loadRequests();
    notifyListeners();
  }

  /// Guarda el perfil; sube primero las fotos que todavía son archivos locales.
  Future<void> saveProfile(Profile p) async {
    var profile = p;
    final avatar = profile.avatarUrl;
    if (avatar != null && !avatar.startsWith('http')) {
      profile = profile.copyWith(avatarUrl: await repo.uploadImage(avatar, kind: 'avatar'));
    }
    final bg = profile.style.customBackgroundUrl;
    if (profile.style.background == 'custom' && bg != null && !bg.startsWith('http')) {
      profile = profile.copyWith(
        style: profile.style.copyWith(customBackgroundUrl: await repo.uploadImage(bg, kind: 'fondo')),
      );
    }
    await repo.saveMyProfile(profile);
    me = profile;
    notifyListeners();
  }

  Future<Profile> scan(String token) async {
    final p = await repo.redeemQrToken(token);
    await refreshContacts();
    return p;
  }

  Future<void> respond(ContactRequest r, bool accept) async {
    await repo.respondToRequest(r.from.id, accept: accept);
    await refreshContacts();
  }

  Future<void> toggleRevoked(Contact c) async {
    await repo.setAccessRevoked(c.profile.id, !c.revoked);
    await refreshContacts();
  }

  Future<void> signOut() async {
    await repo.signOut();
    me = null;
    contacts = [];
    requests = [];
    notifyListeners();
  }
}
