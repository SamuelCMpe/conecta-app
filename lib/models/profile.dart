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

/// Una persona en "Mis contactos".
class Contact {
  final Profile profile;

  /// 'escaneaste' | 'te_escaneo' | 'mutuo'
  final String relation;
  final DateTime since;

  /// true si le quitaste el acceso a tu perfil
  final bool revoked;

  const Contact({required this.profile, required this.relation, required this.since, this.revoked = false});

  Contact copyWith({bool? revoked}) =>
      Contact(profile: profile, relation: relation, since: since, revoked: revoked ?? this.revoked);
}

/// Alguien que escaneó tu QR y te envió su perfil; tú decides si lo aceptas.
class ContactRequest {
  final Profile from;
  final DateTime at;
  const ContactRequest({required this.from, required this.at});
}
