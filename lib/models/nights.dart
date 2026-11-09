import 'profile.dart';

/// Una salida: la gente que conociste una misma noche en un mismo lugar.
class Night {
  /// Día en que empezó la noche (lo de la madrugada cuenta como la noche anterior).
  final DateTime day;
  final String place;
  final List<Contact> people;
  const Night(this.day, this.place, this.people);

  static const _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Setiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  /// "Hoy", "Anoche", "Sábado" o "Octubre", según qué tan lejos fue.
  String get when {
    final today = nightOf(DateTime.now());
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Hoy';
    if (diff == 1) return 'Anoche';
    if (diff < 7) return _days[day.weekday - 1];
    return _months[day.month - 1];
  }

  String get title => place.isEmpty ? when : '$when · $place';

  /// La noche a la que pertenece una hora: antes de las 6 am cuenta como el día anterior.
  static DateTime nightOf(DateTime t) {
    final s = t.subtract(const Duration(hours: 6));
    return DateTime(s.year, s.month, s.day);
  }

  /// Agrupa los contactos por noche y lugar, de la más reciente a la más antigua.
  static List<Night> group(List<Contact> contacts) {
    final map = <String, Night>{};
    final sorted = [...contacts]..sort((a, b) => b.since.compareTo(a.since));
    for (final c in sorted) {
      final d = nightOf(c.since);
      final key = '${d.toIso8601String()}|${c.place.toLowerCase()}';
      map.putIfAbsent(key, () => Night(d, c.place, [])).people.add(c);
    }
    return map.values.toList();
  }
}
