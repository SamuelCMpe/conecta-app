import 'dart:math';

import '../models/profile.dart';
import 'repository.dart';

/// Versión sin servidor: guarda todo en memoria con datos de ejemplo.
/// Sirve para probar la app antes de conectar Supabase.
class DemoRepository implements AppRepository {
  final _rand = Random();
  bool _signedIn = false;

  Profile _me = const Profile(
    id: 'demo-me',
    displayName: 'Samuel Calderón',
    username: 'tu.usuario',
    city: 'Lima, Perú',
    bio: 'Escribe aquí tu frase o bio.',
    interests: ['Música', 'Fútbol', 'Viajes'],
  );

  static final _maria = Profile(
    id: 'demo-maria',
    displayName: 'María López',
    username: 'maria.lopez',
    city: 'Arequipa',
    bio: 'Diseñadora. Me encanta el café.',
    interests: const ['Diseño', 'Café'],
    style: const ProfileStyle(background: 'oceano', font: 'divertida', buttons: 'relleno', avatarShape: 'redondeada'),
    socials: const {'wa': '+51 999 111 222', 'ig': 'maria.lopez', 'fb': 'maria.lopez'},
  );

  final List<Contact> _contacts = [
    Contact(
      profile: const Profile(id: 'demo-carlos', displayName: 'Carlos Vega', style: ProfileStyle(background: 'aurora')),
      relation: 'mutuo',
      since: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Contact(
      profile: const Profile(id: 'demo-ana', displayName: 'Ana Paredes', style: ProfileStyle(background: 'bokeh')),
      relation: 'te_escaneo',
      since: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  final List<ContactRequest> _requests = [
    ContactRequest(
      from: const Profile(id: 'demo-juan', displayName: 'Juan Ríos', style: ProfileStyle(background: 'neon', font: 'moderna')),
      at: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  @override
  bool get isDemo => true;
  @override
  bool get isSignedIn => _signedIn;
  @override
  String? get userId => _signedIn ? _me.id : null;

  @override
  Future<void> sendLoginCode(String email) async {}

  @override
  Future<void> verifyLoginCode(String email, String code) async => _signedIn = true;

  @override
  Future<void> signOut() async => _signedIn = false;

  @override
  Future<Profile> loadMyProfile() async => _me;

  @override
  Future<void> saveMyProfile(Profile profile) async => _me = profile;

  @override
  Future<String> uploadImage(String localPath, {required String kind}) async => localPath;

  @override
  Future<QrToken> createQrToken() async {
    final token = List.generate(24, (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[_rand.nextInt(32)]).join();
    return QrToken(token, DateTime.now().add(const Duration(seconds: 30)));
  }

  @override
  Future<Profile> redeemQrToken(String token) async {
    if (!_contacts.any((c) => c.profile.id == _maria.id)) {
      _contacts.insert(0, Contact(profile: _maria, relation: 'escaneaste', since: DateTime.now()));
    }
    return _maria;
  }

  @override
  Future<List<Contact>> loadContacts() async => List.of(_contacts);

  @override
  Future<List<ContactRequest>> loadRequests() async => List.of(_requests);

  @override
  Future<void> respondToRequest(String fromUserId, {required bool accept}) async {
    final i = _requests.indexWhere((r) => r.from.id == fromUserId);
    if (i < 0) return;
    final r = _requests.removeAt(i);
    if (accept) _contacts.insert(0, Contact(profile: r.from, relation: 'mutuo', since: DateTime.now()));
  }

  @override
  Future<void> setAccessRevoked(String contactUserId, bool revoked) async {
    final i = _contacts.indexWhere((c) => c.profile.id == contactUserId);
    if (i >= 0) _contacts[i] = _contacts[i].copyWith(revoked: revoked);
  }
}
