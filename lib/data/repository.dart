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

  /// Sube una foto (perfil o selfie) y devuelve su URL.
  Future<String> uploadImage(String localPath, {required String kind});

  /// Crea un código nuevo que caduca en pocos segundos.
  Future<QrToken> createQrToken();

  /// Canjea el QR de otra persona: devuelve su perfil y, al mismo tiempo, ella pasa a ver el tuyo.
  /// Se guarda dónde se conocieron (para los dos).
  Future<Profile> redeemQrToken(String token, {MeetPlace? place});

  Future<List<Contact>> loadContacts();

  /// Quita (o devuelve) a esa persona el acceso a tu perfil.
  Future<void> setAccessRevoked(String contactUserId, bool revoked);

  /// Nota privada sobre un contacto (solo la ves tú).
  Future<void> saveNote(String contactUserId, String note);

  /// Foto juntos: queda en el muro de los dos.
  Future<void> saveSelfie(String contactUserId, String url);

  /// Cambia el lugar donde se conocieron (si la ubicación no funcionó).
  Future<void> savePlace(String contactUserId, String place);

  // ---------- Cerca de ti ----------
  /// Activa "Visible" por 2 horas en ese lugar (o lo apaga con null).
  Future<void> setVisible(MeetPlace? place);

  /// Personas visibles cerca (mismo lugar, unos 300 m).
  Future<List<NearbyPerson>> loadNearby(MeetPlace place);

  Future<void> sendWave(String userId);

  /// Bloquear: deja de verte en Cerca, pierde el acceso a tu perfil y desaparece de tu muro.
  Future<void> block(String userId);

  Future<void> report(String userId, String reason);
}
