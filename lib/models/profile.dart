/// Datos de un perfil y su diseño.
class ProfileStyle {
  /// 'montanas' | 'bokeh' | 'oceano' | 'aurora' | 'neon' | 'papel' | 'custom'
  final String background;
  final String? customBackgroundUrl;

  /// 0 = suave, 1 = medio, 2 = fuerte
  final int dim;
  final bool blur;

  /// 'circulo' | 'redondeada' | 'cuadrada'
  final String avatarShape;

  /// índice en [ringOptions]
  final int ring;

  /// 'moderna' | 'elegante' | 'divertida'
  final String font;

  /// 'vidrio' | 'relleno' | 'contorno'
  final String buttons;

  /// null = color del fondo
  final int? accent;

  /// índice en kQrStyles
  final int qrStyle;

  /// Stickers de la polaroid (máx. 3), ej: ['📍 Máncora', 'aquí de paso 🌊']
  final List<String> stickers;

  /// Índice en kFrameColors (color del marco de la polaroid)
  final int frame;

  /// Fondo de "Mi muro": 'corcho' | 'ladrillo' | 'neon' | 'liso'
  final String wall;

  const ProfileStyle({
    this.background = 'montanas',
    this.customBackgroundUrl,
    this.dim = 1,
    this.blur = false,
    this.avatarShape = 'circulo',
    this.ring = 0,
    this.font = 'elegante',
    this.buttons = 'vidrio',
    this.accent,
    this.qrStyle = 1,
    this.stickers = const [],
    this.frame = 0,
    this.wall = 'liso',
  });

  ProfileStyle copyWith({
    String? background,
    String? customBackgroundUrl,
    int? dim,
    bool? blur,
    String? avatarShape,
    int? ring,
    String? font,
    String? buttons,
    int? accent,
    bool clearAccent = false,
    int? qrStyle,
    List<String>? stickers,
    int? frame,
    String? wall,
  }) {
    return ProfileStyle(
      background: background ?? this.background,
      customBackgroundUrl: customBackgroundUrl ?? this.customBackgroundUrl,
      dim: dim ?? this.dim,
      blur: blur ?? this.blur,
      avatarShape: avatarShape ?? this.avatarShape,
      ring: ring ?? this.ring,
      font: font ?? this.font,
      buttons: buttons ?? this.buttons,
      accent: clearAccent ? null : (accent ?? this.accent),
      qrStyle: qrStyle ?? this.qrStyle,
      stickers: stickers ?? this.stickers,
      frame: frame ?? this.frame,
      wall: wall ?? this.wall,
    );
  }

  Map<String, dynamic> toJson() => {
        'background': background,
        'customBackgroundUrl': customBackgroundUrl,
        'dim': dim,
        'blur': blur,
        'avatarShape': avatarShape,
        'ring': ring,
        'font': font,
        'buttons': buttons,
        'accent': accent,
        'qrStyle': qrStyle,
        'stickers': stickers,
        'frame': frame,
        'wall': wall,
      };

  factory ProfileStyle.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ProfileStyle();
    return ProfileStyle(
      background: j['background'] as String? ?? 'montanas',
      customBackgroundUrl: j['customBackgroundUrl'] as String?,
      dim: (j['dim'] as num?)?.toInt() ?? 1,
      blur: j['blur'] as bool? ?? false,
      avatarShape: j['avatarShape'] as String? ?? 'circulo',
      ring: (j['ring'] as num?)?.toInt() ?? 0,
      font: j['font'] as String? ?? 'elegante',
      buttons: j['buttons'] as String? ?? 'vidrio',
      accent: (j['accent'] as num?)?.toInt(),
      qrStyle: (j['qrStyle'] as num?)?.toInt() ?? 1,
      stickers: (j['stickers'] as List?)?.cast<String>() ?? const [],
      frame: (j['frame'] as num?)?.toInt() ?? 0,
      wall: j['wall'] as String? ?? 'liso',
    );
  }
}

class Profile {
  final String id;
  final String displayName;
  final String username;
  final String city;
  final String bio;
  final List<String> interests;
  final String? avatarUrl;
  final ProfileStyle style;

  /// Redes visibles, en orden. Ej: ['wa', 'ig', 'fb']
  final List<String> networks;

  /// Lo que la persona escribió en cada red (número, usuario o enlace).
  final Map<String, String> socials;

  final bool featuredEnabled;
  final String featuredTitle;
  final String featuredUrl;

  const Profile({
    required this.id,
    this.displayName = '',
    this.username = '',
    this.city = '',
    this.bio = '',
    this.interests = const [],
    this.avatarUrl,
    this.style = const ProfileStyle(),
    this.networks = const ['wa', 'ig', 'fb'],
    this.socials = const {},
    this.featuredEnabled = false,
    this.featuredTitle = '',
    this.featuredUrl = '',
  });

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Profile copyWith({
    String? displayName,
    String? username,
    String? city,
    String? bio,
    List<String>? interests,
    String? avatarUrl,
    ProfileStyle? style,
    List<String>? networks,
    Map<String, String>? socials,
    bool? featuredEnabled,
    String? featuredTitle,
    String? featuredUrl,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      style: style ?? this.style,
      networks: networks ?? this.networks,
      socials: socials ?? this.socials,
      featuredEnabled: featuredEnabled ?? this.featuredEnabled,
      featuredTitle: featuredTitle ?? this.featuredTitle,
      featuredUrl: featuredUrl ?? this.featuredUrl,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'display_name': displayName,
        'username': username.isEmpty ? null : username,
        'city': city,
        'bio': bio,
        'interests': interests,
        'avatar_url': avatarUrl,
        'style': style.toJson(),
        'networks': networks,
        'socials': socials,
        'featured_enabled': featuredEnabled,
        'featured_title': featuredTitle,
        'featured_url': featuredUrl,
      };

  factory Profile.fromRow(Map<String, dynamic> r) {
    return Profile(
      id: r['id'] as String,
      displayName: r['display_name'] as String? ?? '',
      username: r['username'] as String? ?? '',
      city: r['city'] as String? ?? '',
      bio: r['bio'] as String? ?? '',
      interests: (r['interests'] as List?)?.cast<String>() ?? const [],
      avatarUrl: r['avatar_url'] as String?,
      style: ProfileStyle.fromJson((r['style'] as Map?)?.cast<String, dynamic>()),
      networks: (r['networks'] as List?)?.cast<String>() ?? const ['wa', 'ig', 'fb'],
      socials: (r['socials'] as Map?)?.map((k, v) => MapEntry(k as String, v as String)) ?? const {},
      featuredEnabled: r['featured_enabled'] as bool? ?? false,
      featuredTitle: r['featured_title'] as String? ?? '',
      featuredUrl: r['featured_url'] as String? ?? '',
    );
  }
}

/// Dónde se conocieron (lo pone la app al escanear, o la persona a mano).
class MeetPlace {
  final String name;
  final double? lat;
  final double? lng;
  const MeetPlace(this.name, {this.lat, this.lng});
  bool get hasCoords => lat != null && lng != null;
}

/// Una persona en "Mi muro".
class Contact {
  final Profile profile;

  /// 'escaneaste' | 'te_escaneo' | 'mutuo'
  final String relation;

  /// Cuándo se conocieron.
  final DateTime since;

  /// true si le quitaste el acceso a tu perfil
  final bool revoked;

  /// Barrio o lugar donde se conocieron (puede faltar).
  final String place;
  final double? lat;
  final double? lng;

  /// Foto que se tomaron juntos (la ven los dos).
  final String? selfieUrl;

  /// Nota privada que solo ve quien la escribió.
  final String note;

  const Contact({
    required this.profile,
    required this.relation,
    required this.since,
    this.revoked = false,
    this.place = '',
    this.lat,
    this.lng,
    this.selfieUrl,
    this.note = '',
  });

  /// Para guardar el muro en el celular (y verlo sin conexión).
  Map<String, dynamic> toJson() => {
        'profile': profile.toRow(),
        'relation': relation,
        'since': since.toIso8601String(),
        'revoked': revoked,
        'place': place,
        'lat': lat,
        'lng': lng,
        'selfie_url': selfieUrl,
        'note': note,
      };

  factory Contact.fromJson(Map<String, dynamic> m) => Contact(
        profile: Profile.fromRow((m['profile'] as Map).cast<String, dynamic>()),
        relation: m['relation'] as String? ?? 'mutuo',
        since: DateTime.parse(m['since'] as String),
        revoked: m['revoked'] as bool? ?? false,
        place: m['place'] as String? ?? '',
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        selfieUrl: m['selfie_url'] as String?,
        note: m['note'] as String? ?? '',
      );

  Contact copyWith({bool? revoked, String? selfieUrl, String? note, String? place}) => Contact(
        profile: profile,
        relation: relation,
        since: since,
        revoked: revoked ?? this.revoked,
        place: place ?? this.place,
        lat: lat,
        lng: lng,
        selfieUrl: selfieUrl ?? this.selfieUrl,
        note: note ?? this.note,
      );
}

/// Alguien con "Visible" activado cerca de ti. Solo nombre, foto y un sticker: sus redes no.
class NearbyPerson {
  final String id;
  final String firstName;
  final String? avatarUrl;
  final String sticker;
  final bool wavedAtMe;
  final bool iWaved;
  const NearbyPerson({
    required this.id,
    required this.firstName,
    this.avatarUrl,
    this.sticker = '',
    this.wavedAtMe = false,
    this.iWaved = false,
  });

  NearbyPerson copyWith({bool? iWaved}) => NearbyPerson(
      id: id,
      firstName: firstName,
      avatarUrl: avatarUrl,
      sticker: sticker,
      wavedAtMe: wavedAtMe,
      iWaved: iWaved ?? this.iWaved);
}

/// Un aviso: alguien te saludó, te escaneó o se unió a tu grupo.
class ActivityItem {
  final int id;

  /// 'wave' | 'connect' | 'group'
  final String kind;
  final String actorId;
  final String firstName;
  const ActivityItem({required this.id, required this.kind, required this.actorId, this.firstName = ''});

  String get message {
    final who = firstName.isEmpty ? 'Alguien' : firstName;
    switch (kind) {
      case 'wave':
        return '$who te saludó 👋';
      case 'group':
        return '$who se unió a tu grupo 👯';
      default:
        return '$who escaneó tu QR. Ya está en tu muro 📸';
    }
  }
}
