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
  Future<Profile> redeemQrToken(String token) async {
    try {
      final res = await _db.rpc('redeem_qr_token', params: {'p_token': token});
      return Profile.fromRow((res as Map).cast<String, dynamic>());
    } on PostgrestException catch (e) {
      if (e.message.contains('expired')) throw QrExpiredException();
      if (e.message.contains('own')) throw OwnQrException();
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
      );
    }).toList();
  }

  @override
  Future<List<ContactRequest>> loadRequests() async {
    final rows = await _db.rpc('my_requests') as List;
    return rows.map((r) {
      final m = (r as Map).cast<String, dynamic>();
      return ContactRequest(
        from: Profile.fromRow((m['profile'] as Map).cast<String, dynamic>()),
        at: DateTime.parse(m['at'] as String).toLocal(),
      );
    }).toList();
  }

  @override
  Future<void> respondToRequest(String fromUserId, {required bool accept}) async {
    await _db.rpc('respond_request', params: {'p_from': fromUserId, 'p_accept': accept});
  }

  @override
  Future<void> setAccessRevoked(String contactUserId, bool revoked) async {
    await _db.rpc('set_access_revoked', params: {'p_viewer': contactUserId, 'p_revoked': revoked});
  }
}
