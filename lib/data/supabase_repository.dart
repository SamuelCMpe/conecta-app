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

  String get _uid {
    final id = userId;
    if (id == null) throw StateError('No hay sesión iniciada');
    return id;
  }

  @override
  Future<void> sendLoginCode(String email) => _db.auth.signInWithOtp(email: email, shouldCreateUser: true);

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
    final res = await _db.rpc('create_qr_token');
    final row = (res is List ? res.first : res) as Map<String, dynamic>;
    return QrToken(row['token'] as String, DateTime.parse(row['expires_at'] as String).toLocal());
  }

  @override
  Future<Profile> redeemQrToken(String token, {MeetPlace? place}) async {
    try {
      final res = await _db.rpc('redeem_qr_token', params: {
        'p_token': token,
        'p_place': place?.name ?? '',
        'p_lat': place?.lat,
        'p_lng': place?.lng,
      });
      return Profile.fromRow((res as Map).cast<String, dynamic>());
    } on PostgrestException catch (e) {
      if (e.message.contains('expired')) throw QrExpiredException();
      if (e.message.contains('own')) throw OwnQrException();
      if (e.message.contains('blocked')) throw Exception('No puedes conectar con esta persona.');
      rethrow;
    }
  }

  @override
  Future<List<Contact>> loadContacts() async {
    final rows = await _db.rpc('my_contacts') as List;
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
    await _db.rpc('set_access_revoked', params: {'p_viewer': contactUserId, 'p_revoked': revoked});
  }

  @override
  Future<void> saveNote(String contactUserId, String note) =>
      _db.rpc('save_note', params: {'p_about': contactUserId, 'p_note': note});

  @override
  Future<void> saveSelfie(String contactUserId, String url) =>
      _db.rpc('save_meet', params: {'p_other': contactUserId, 'p_selfie_url': url});

  @override
  Future<void> savePlace(String contactUserId, String place) =>
      _db.rpc('save_meet', params: {'p_other': contactUserId, 'p_place': place});

  @override
  Future<void> setVisible(MeetPlace? place) => _db.rpc('set_visible', params: {
        'p_place': place?.name ?? '',
        'p_lat': place?.lat,
        'p_lng': place?.lng,
      });

  @override
  Future<List<NearbyPerson>> loadNearby(MeetPlace place) async {
    if (!place.hasCoords) return const [];
    final rows = await _db.rpc('nearby', params: {'p_lat': place.lat, 'p_lng': place.lng}) as List;
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
  Future<void> sendWave(String userId) => _db.rpc('send_wave', params: {'p_to': userId});

  @override
  Future<void> block(String userId) => _db.rpc('block_user', params: {'p_id': userId});

  @override
  Future<void> report(String userId, String reason) =>
      _db.rpc('report_user', params: {'p_id': userId, 'p_reason': reason});
}
