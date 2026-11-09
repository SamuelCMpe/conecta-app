import '../models/profile.dart';

class QrToken {
  final String token;
  final DateTime expiresAt;
  const QrToken(this.token, this.expiresAt);

  /// Lo que va dentro del código QR.
  String get payload => '$kQrPrefix$token';
}

const kQrPrefix = 'qrconecta:';

/// Saca el token de lo que leyó la cámara; null si no es un QR de la app.
String? tokenFromPayload(String raw) {
  final v = raw.trim();
  if (!v.startsWith(kQrPrefix)) return null;
  final t = v.substring(kQrPrefix.length);
  return t.isEmpty ? null : t;
}

class QrExpiredException implements Exception {
  @override
  String toString() => 'Este QR ya caducó. Pide que te muestren el código actualizado.';
}

class OwnQrException implements Exception {
  @override
  String toString() => 'Ese es tu propio QR.';
}

/// Todo lo que la app necesita del servidor.
/// Hay dos versiones: [DemoRepository] (sin servidor, para probar) y
/// [SupabaseRepository] (la real).
abstract class AppRepository {
  bool get isDemo;
  bool get isSignedIn;
  String? get userId;

  Future<void> sendLoginCode(String email);
  Future<void> verifyLoginCode(String email, String code);
  Future<void> signOut();

  Future<Profile> loadMyProfile();
  Future<void> saveMyProfile(Profile profile);

  /// Sube una foto (perfil o fondo) y devuelve su URL.
  Future<String> uploadImage(String localPath, {required String kind});

  /// Crea un código nuevo que caduca en pocos segundos.
  Future<QrToken> createQrToken();

  /// Canjea el QR de otra persona: devuelve su perfil y, al mismo tiempo, ella pasa a ver el tuyo.
  Future<Profile> redeemQrToken(String token);

  Future<List<Contact>> loadContacts();
  Future<List<ContactRequest>> loadRequests();
  Future<void> respondToRequest(String fromUserId, {required bool accept});

  /// Quita (o devuelve) a esa persona el acceso a tu perfil.
  Future<void> setAccessRevoked(String contactUserId, bool revoked);
}
