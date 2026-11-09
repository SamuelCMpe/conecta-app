import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/profile.dart';
import '../theme/polaroid.dart';
import 'contact_screen.dart';

/// Mapa de mis noches: una polaroid en cada lugar donde conocí gente.
class WallMap extends StatefulWidget {
  final List<Contact> contacts;
  const WallMap({super.key, required this.contacts});
  @override
  State<WallMap> createState() => _WallMapState();
}

class _Spot {
  final String place;
  final LatLng point;
  final List<Contact> people;
  _Spot(this.place, this.point, this.people);
}

class _WallMapState extends State<WallMap> {
  _Spot? _selected;

  static const _pillColors = [Pal.yellow, Pal.pink, Pal.green, Color(0xFFC4B5FD)];

  /// Junta a la gente del mismo lugar (mismo nombre, o a menos de ~500 m).
  List<_Spot> get _spots {
    final spots = <_Spot>[];
    for (final c in widget.contacts) {
      if (c.lat == null || c.lng == null) continue;
      final pt = LatLng(c.lat!, c.lng!);
      final same = spots.where((s) =>
          (c.place.isNotEmpty && s.place.toLowerCase() == c.place.toLowerCase()) ||
          const Distance().as(LengthUnit.Meter, s.point, pt) < 500);
      if (same.isNotEmpty) {
        same.first.people.add(c);
      } else {
        spots.add(_Spot(c.place, pt, [c]));
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spots;
    final points = [for (final s in spots) s.point];
    final options = points.length >= 2
        ? MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.fromLTRB(70, 160, 70, 220),
              maxZoom: 15,
            ),
            onTap: (_, __) => setState(() => _selected = null),
          )
        : MapOptions(
            initialCenter: points.isEmpty ? const LatLng(-12.12, -77.03) : points.first,
            initialZoom: points.isEmpty ? 11 : 14,
            onTap: (_, __) => setState(() => _selected = null),
          );

    return Stack(fit: StackFit.expand, children: [
      FlutterMap(
        options: options,
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            retinaMode: RetinaMode.isHighDensity(context),
            userAgentPackageName: 'com.qrconecta.qr_conecta',
          ),
          MarkerLayer(markers: [
            for (var i = 0; i < spots.length; i++)
              Marker(
                point: spots[i].point,
                width: 120,
                height: 104,
                child: GestureDetector(
                  onTap: () => setState(() => _selected = spots[i]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    PersonPolaroid(
                      id: spots[i].people.first.profile.id,
                      name: '',
                      photoUrl: spots[i].people.first.selfieUrl ?? spots[i].people.first.profile.avatarUrl,
                      width: 62,
                      angle: tiltFor(spots[i].place, max: 5),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _pillColors[i % _pillColors.length], borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          '${spots[i].place.isEmpty ? 'Aquí' : spots[i].place} · ${spots[i].people.length}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(11.5, color: Pal.ink, weight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
          const RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            attributions: [TextSourceAttribution('OpenStreetMap'), TextSourceAttribution('CARTO')],
          ),
        ],
      ),
      if (points.isEmpty)
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(22)),
            child: Text('Cuando escanees a alguien con la ubicación activada, el lugar aparece aquí 📍',
                textAlign: TextAlign.center, style: body(15)),
          ),
        ),
      if (_selected != null)
        Positioned(left: 20, right: 20, bottom: 104, child: SafeArea(top: false, child: _card(_selected!))),
    ]);
  }

  Widget _card(_Spot s) {
    final first = s.people.first.since;
    return Material(
      color: Pal.card,
      borderRadius: BorderRadius.circular(22),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.place.isEmpty ? 'Sin nombre' : s.place, style: body(17, weight: FontWeight.w800)),
          Text('${s.people.length} ${s.people.length == 1 ? 'persona' : 'personas'} · ${shortDate(first)}',
              style: body(13, color: Pal.muted)),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.people.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final c = s.people[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ContactScreen(contactId: c.profile.id))),
                  child: PersonPolaroid(
                    id: c.profile.id,
                    name: c.profile.displayName,
                    photoUrl: c.selfieUrl ?? c.profile.avatarUrl,
                    width: 66,
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
