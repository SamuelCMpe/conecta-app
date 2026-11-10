import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/profile.dart';
import 'repository.dart';

/// Versión real, usando Supabase (ver supabase/schema.sql).
class SupabaseRepository implements AppRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  bool get isDemo => false;
  @override
  bool get isSignedIn => _db.auth.currentUser != null;
  @override
  String? get userId => _db.auth.currentUser?.id;

  /// Llama a una función del servidor y traduce los errores conocidos.
  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    try {
      return await _db.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      final m = e.message;
      if (m.contains('too many')) throw TooManyException();
      if (m.contains('expired')) throw QrExpiredException();
      if (m.contains('own qr')) throw OwnQrException();
      if (m.contains('blocked')) throw Exception('No puedes conectar con esta persona.');
      if (m.contains('group full')) throw Exception('Ese grupo ya está lleno (máximo 50).');
      if (m.contains('not visible')) throw Exception('Activa Visible para saludar.');
      rethrow;
    }
  }

  String get _uid {
    final id = userId;
    if (id == null) throw StateError('No hay sesión iniciada');
    return id;
  }

  @override
  bool get usesEmailLink => true;

  /// Adonde vuelve el enlace del correo (abre la app). Debe estar en Supabase > Authentication > URL Configuration.
  static const loginRedirect = 'conecta://login-callback';

  @override
  Future<void> sendLoginCode(String email) =>
      _db.auth.signInWithOtp(email: email, shouldCreateUser: true, emailRedirectTo: loginRedirect);

  @override
  Future<void> verifyLoginCode(String email, String code) async {
    await _db.auth.verifyOTP(type: OtpType.email, email: email, token: code);
  }

  @override
  Future<void> signOut() => _db.auth.signOut();

  @override
  Future<Profile> loadMyProfile() async {
    final row = await _db.from('profiles').select().eq('id', _uid).maybeSingle();
    if (row == null) return Profile(id: _uid);
    return Profile.fromRow(row);
  }

  @override
  Future<void> saveMyProfile(Profile profile) async {
    await _db.from('profiles').upsert(profile.toRow());
  }

  @override
  Future<String> uploadImage(String localPath, {required String kind}) async {
    if (localPath.startsWith('http')) return localPath;
    final ext = localPath.split('.').last.toLowerCase();
    final path = '$_uid/$kind-${const Uuid().v4()}.$ext';
    await _db.storage.from('media').upload(path, File(localPath));
    return _db.storage.from('media').getPublicUrl(path);
  }

  @override
  Future<QrToken> createQrToken() async {
    final res = await _rpc('create_qr_token');
    final row = (res is List ? res.first : res) as Map<String, dynamic>;
    return QrToken(row['token'] as String, DateTime.parse(row['expires_at'] as String).toLocal());
  }

  @override
  Future<Profile> redeemQrToken(String token, {MeetPlace? place}) async {
    final res = await _rpc('redeem_qr_token', {
      'p_token': token,
      'p_place': place?.name ?? '',
      'p_lat': place?.lat,
      'p_lng': place?.lng,
    });
    return Profile.fromRow((res as Map).cast<String, dynamic>());
  }

  @override
  Future<List<Contact>> loadContacts() async {
    final rows = await _rpc('my_contacts') as List;
    return rows.map((r) {
      final m = (r as Map).cast<String, dynamic>();
      return Contact(
        profile: Profile.fromRow((m['profile'] as Map).cast<String, dynamic>()),
        relation: m['relation'] as String,
        since: DateTime.parse(m['since'] as String).toLocal(),
        revoked: m['revoked'] as bool? ?? false,
        place: m['place'] as String? ?? '',
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        selfieUrl: m['selfie_url'] as String?,
        note: m['note'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<void> setAccessRevoked(String contactUserId, bool revoked) async {
    await _rpc('set_access_revoked', {'p_viewer': contactUserId, 'p_revoked': revoked});
  }

  @override
  Future<void> saveNote(String contactUserId, String note) =>
      _rpc('save_note', {'p_about': contactUserId, 'p_note': note});

  @override
  Future<void> saveSelfie(String contactUserId, String url) =>
      _rpc('save_meet', {'p_other': contactUserId, 'p_selfie_url': url});

  @override
  Future<void> savePlace(String contactUserId, String place) =>
      _rpc('save_meet', {'p_other': contactUserId, 'p_place': place});

  @override
  Future<void> setVisible(MeetPlace? place) => _rpc('set_visible', {
        'p_place': place?.name ?? '',
        'p_lat': place?.lat,
        'p_lng': place?.lng,
      });

  @override
  Future<List<NearbyPerson>> loadNearby(MeetPlace place) async {
    if (!place.hasCoords) return const [];
    final rows = await _rpc('nearby', {'p_lat': place.lat, 'p_lng': place.lng}) as List;
    return rows.map((r) {
      final m = (r as Map).cast<String, dynamic>();
      return NearbyPerson(
        id: m['id'] as String,
        firstName: m['first_name'] as String? ?? '',
        avatarUrl: m['avatar_url'] as String?,
        sticker: m['sticker'] as String? ?? '',
        wavedAtMe: m['waved_at_me'] as bool? ?? false,
        iWaved: m['i_waved'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<void> sendWave(String userId) => _rpc('send_wave', {'p_to': userId});

  @override
  Future<void> block(String userId) => _rpc('block_user', {'p_id': userId});

  @override
  Future<void> report(String userId, String reason) =>
      _rpc('report_user', {'p_id': userId, 'p_reason': reason});

  @override
  Future<QrToken> createGroup({MeetPlace? place}) async {
    final res = await _rpc('create_group', {'p_place': place?.name ?? '', 'p_lat': place?.lat, 'p_lng': place?.lng});
    final row = (res is List ? res.first : res) as Map<String, dynamic>;
    return QrToken(row['token'] as String, DateTime.parse(row['expires_at'] as String).toLocal(), group: true);
  }

  @override
  Future<int> groupSize(String token) async => (await _rpc('group_size', {'p_token': token}) as num?)?.toInt() ?? 1;

  @override
  Future<void> endGroup(String token) => _rpc('end_group', {'p_token': token});

  @override
  Future<List<Profile>> joinGroup(String token, {MeetPlace? place}) async {
    final res = await _rpc('join_group', {
      'p_token': token,
      'p_place': place?.name ?? '',
      'p_lat': place?.lat,
      'p_lng': place?.lng,
    }) as List;
    return [for (final r in res) Profile.fromRow((r as Map).cast<String, dynamic>())];
  }

  @override
  Future<List<ActivityItem>> loadActivity(int afterId) async {
    final rows = await _rpc('my_activity', {'p_after': afterId}) as List;
    return [
      for (final r in rows)
        ActivityItem(
          id: ((r as Map)['id'] as num).toInt(),
          kind: r['kind'] as String,
          actorId: r['actor_id'] as String,
          firstName: r['first_name'] as String? ?? '',
        ),
    ];
  }
}
