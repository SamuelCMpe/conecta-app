import 'dart:math';

import '../models/profile.dart';
import 'repository.dart';

/// Versión sin servidor: guarda todo en memoria con datos de ejemplo.
/// Sirve para probar la app antes de conectar Supabase.
class DemoRepository implements AppRepository {
  final _rand = Random();
  bool _signedIn = false;
  bool _visible = false;

  Profile _me = const Profile(
    id: 'demo-me',
    displayName: 'Samuel Calderón',
    username: 'samuel.cm',
    city: 'Lima',
    bio: 'Diseño, fútbol y buena música 🎶',
    interests: ['🎧 Música', '⚽ Fútbol', '✈️ Viajes'],
    networks: ['wa', 'ig', 'tk', 'fb'],
    style: ProfileStyle(stickers: ['aquí de paso 🌊', '📍 Lima']),
  );

  static const _maria = Profile(
    id: 'demo-maria',
    displayName: 'María López',
    username: 'maria.lopez',
    city: 'Arequipa',
    bio: 'Arquitecta, viajera y fan del ceviche 🍋',
    interests: ['🎶 Reggaetón', '☕ Café'],
    style: ProfileStyle(stickers: ['🐶 dog lover', '🎶 reggaetón'], frame: 1),
    socials: {'wa': '+51 999 111 222', 'ig': 'maria.lopez', 'fb': 'maria.lopez'},
  );

  static Contact _demo(String id, String name, int daysAgo, int hour, String place, double lat, double lng,
          {String bio = '', List<String> stickers = const []}) =>
      Contact(
        profile: Profile(
          id: id,
          displayName: name,
          bio: bio,
          style: ProfileStyle(stickers: stickers),
          socials: const {'wa': '+51 999 000 000', 'ig': 'conecta.app'},
        ),
        relation: 'mutuo',
        since: DateTime.now().subtract(Duration(days: daysAgo)).copyWith(hour: hour, minute: 20),
        place: place,
        lat: lat,
        lng: lng,
      );

  final List<Contact> _contacts = [
    _demo('demo-juan', 'Juan Ríos', 1, 23, 'Barranco', -12.1495, -77.0215, stickers: ['⚽ hincha de la U']),
    _demo('demo-ana', 'Ana Paredes', 1, 1, 'Barranco', -12.1490, -77.0230, stickers: ['🎧 techno']),
    _demo('demo-carlos', 'Carlos Vega', 3, 22, 'Miraflores', -12.1211, -77.0297, stickers: ['🎤 karaoke']),
    _demo('demo-lu', 'Lucía Torres', 3, 23, 'Miraflores', -12.1190, -77.0340),
    _demo('demo-dani', 'Daniela Vidal', 24, 21, 'Cusco', -13.5170, -71.9785, stickers: ['🏔️ mochilera']),
    _demo('demo-tomas', 'Tomás Ugarte', 24, 22, 'Cusco', -13.5160, -71.9790),
  ];

  final List<NearbyPerson> _nearby = const [
    NearbyPerson(id: 'n-valeria', firstName: 'Valeria', sticker: '🎧 techno', wavedAtMe: true),
    NearbyPerson(id: 'n-rodrigo', firstName: 'Rodrigo', sticker: '⚽ hincha de la U'),
    NearbyPerson(id: 'n-camila', firstName: 'Camila', sticker: '✈️ de paso'),
    NearbyPerson(id: 'n-diego', firstName: 'Diego', sticker: '🎓 UPC'),
  ];
  final Set<String> _waved = {};
  final Set<String> _blocked = {};

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
  Future<Profile> redeemQrToken(String token, {MeetPlace? place}) async {
    _contacts.removeWhere((c) => c.profile.id == _maria.id);
    _contacts.insert(
      0,
      Contact(
        profile: _maria,
        relation: 'mutuo',
        since: DateTime.now(),
        place: place?.name ?? '',
        lat: place?.lat,
        lng: place?.lng,
      ),
    );
    return _maria;
  }

  @override
  Future<List<Contact>> loadContacts() async => _contacts.where((c) => !_blocked.contains(c.profile.id)).toList();

  void _update(String id, Contact Function(Contact) f) {
    final i = _contacts.indexWhere((c) => c.profile.id == id);
    if (i >= 0) _contacts[i] = f(_contacts[i]);
  }

  @override
  Future<void> setAccessRevoked(String contactUserId, bool revoked) async =>
      _update(contactUserId, (c) => c.copyWith(revoked: revoked));

  @override
  Future<void> saveNote(String contactUserId, String note) async =>
      _update(contactUserId, (c) => c.copyWith(note: note));

  @override
  Future<void> saveSelfie(String contactUserId, String url) async =>
      _update(contactUserId, (c) => c.copyWith(selfieUrl: url));

  @override
  Future<void> savePlace(String contactUserId, String place) async =>
      _update(contactUserId, (c) => c.copyWith(place: place));

  @override
  Future<void> setVisible(MeetPlace? place) async => _visible = place != null;

  @override
  Future<List<NearbyPerson>> loadNearby(MeetPlace place) async {
    if (!_visible) return const [];
    return [
      for (final p in _nearby)
        if (!_blocked.contains(p.id)) p.copyWith(iWaved: _waved.contains(p.id)),
    ];
  }

  @override
  Future<void> sendWave(String userId) async => _waved.add(userId);

  @override
  Future<void> block(String userId) async => _blocked.add(userId);

  @override
  Future<void> report(String userId, String reason) async {}

  // ---------- Modo grupo (demo) ----------
  static const _groupPeople = [
    Profile(id: 'demo-sofi', displayName: 'Sofía Ramos', style: ProfileStyle(stickers: ['💃 salsera']),
        socials: {'ig': 'sofi.ramos'}),
    Profile(id: 'demo-mateo', displayName: 'Mateo Díaz', style: ProfileStyle(stickers: ['🎸 rockero']),
        socials: {'wa': '+51 999 333 444'}),
    Profile(id: 'demo-vale', displayName: 'Valeria Soto', style: ProfileStyle(stickers: ['🎧 techno']),
        socials: {'ig': 'vale.soto'}),
  ];
  int _groupJoined = 0;
  DateTime? _groupStart;

  @override
  Future<QrToken> createGroup({MeetPlace? place}) async {
    _groupStart = DateTime.now();
    final token = List.generate(24, (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[_rand.nextInt(32)]).join();
    return QrToken(token, DateTime.now().add(const Duration(hours: 3)), group: true);
  }

  /// En la demo se va sumando una persona cada pocos segundos.
  @override
  Future<int> groupSize(String token) async {
    final start = _groupStart;
    if (start == null) return 1;
    return 1 + min(4, DateTime.now().difference(start).inSeconds ~/ 4);
  }

  @override
  Future<void> endGroup(String token) async => _groupStart = null;

  @override
  Future<List<Profile>> joinGroup(String token, {MeetPlace? place}) async {
    _groupJoined++;
    final now = DateTime.now();
    for (final p in _groupPeople) {
      _contacts.removeWhere((c) => c.profile.id == p.id);
      _contacts.insert(
          0,
          Contact(
              profile: p, relation: 'mutuo', since: now, place: place?.name ?? '', lat: place?.lat, lng: place?.lng));
    }
    return _groupPeople;
  }

  int get groupJoins => _groupJoined;

  @override
  Future<List<ActivityItem>> loadActivity(int afterId) async => const [];
}
