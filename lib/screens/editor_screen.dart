import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/networks.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../theme/profile_look.dart';
import '../widgets/common.dart';

/// "Personalizar": datos, fondo, foto, estilo y redes, con vista previa en vivo.
class EditorScreen extends StatefulWidget {
  final Profile initial;
  final int initialTab;
  const EditorScreen({super.key, required this.initial, this.initialTab = 0});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with SingleTickerProviderStateMixin {
  late Profile _p = widget.initial;
  late final TabController _tabs = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
  late final _name = TextEditingController(text: _p.displayName);
  late final _user = TextEditingController(text: _p.username);
  late final _city = TextEditingController(text: _p.city);
  late final _bio = TextEditingController(text: _p.bio);
  final _newInterest = TextEditingController();
  late final _featTitle = TextEditingController(text: _p.featuredTitle);
  late final _featUrl = TextEditingController(text: _p.featuredUrl);
  final Map<String, TextEditingController> _social = {};
  bool _saving = false;

  ProfileStyle get _s => _p.style;
  void _style(ProfileStyle s) => setState(() => _p = _p.copyWith(style: s));

  TextEditingController _socialCtl(String id) =>
      _social.putIfAbsent(id, () => TextEditingController(text: _p.socials[id] ?? ''));

  @override
  void dispose() {
    for (final c in [_name, _user, _city, _bio, _newInterest, _featTitle, _featUrl, ..._social.values]) {
      c.dispose();
    }
    _tabs.dispose();
    super.dispose();
  }

  Future<String?> _pick() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    return f?.path;
  }

  Future<void> _save() async {
    if (_p.displayName.trim().isEmpty) {
      _tabs.animateTo(0);
      showError(context, 'Escribe tu nombre.');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppState>().saveProfile(_p);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        SizedBox(height: 330, child: _preview()),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Datos'),
              Tab(text: 'Fondo'),
              Tab(text: 'Foto'),
              Tab(text: 'Estilo'),
              Tab(text: 'Redes')
            ],
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabs, children: [_datos(), _fondo(), _foto(), _estilo(), _redes()]),
        ),
      ]),
    );
  }

  // ---------- Vista previa ----------
  Widget _preview() {
    final look = ProfileLook(_s);
    final handle = [
      '@${_p.username.replaceFirst('@', '').isEmpty ? 'tu.usuario' : _p.username.replaceFirst('@', '')}',
      if (_p.city.isNotEmpty) _p.city,
    ].join(' · ');
    final btn = look.button;
    return ProfileBackground(
      style: _s,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(children: [
            Row(children: [
              Glass(
                color: look.glass,
                border: Border.all(color: look.glassBorder),
                radius: 20,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: TextStyle(color: look.text)),
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: look.accent, foregroundColor: look.onAccent),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando…' : 'Guardar'),
              ),
            ]),
            const SizedBox(height: 6),
            Avatar(profile: _p, size: 72),
            const SizedBox(height: 6),
            Text(_p.displayName.isEmpty ? 'Tu nombre' : _p.displayName, style: look.titleFont(size: 24)),
            Text(handle, style: TextStyle(color: look.subtext, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
              for (final id in _p.networks)
                Glass(
                  color: btn.bg,
                  border: btn.border,
                  blur: btn.blur,
                  radius: 14,
                  padding: const EdgeInsets.all(8),
                  child: NetworkBadge(network: networkById(id), size: 28),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ---------- Pestañas ----------
  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B5E6B), letterSpacing: 0.6)),
          const SizedBox(height: 10),
          ...children,
        ]),
      );

  InputDecoration _dec(String label, {String? hint, String? helper}) =>
      InputDecoration(labelText: label, hintText: hint, helperText: helper, border: const OutlineInputBorder());

  Widget _datos() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        controller: _name,
        decoration: _dec('Nombre que se muestra'),
        onChanged: (v) => setState(() => _p = _p.copyWith(displayName: v)),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _user,
            decoration: _dec('Usuario', hint: 'tu.usuario'),
            onChanged: (v) => setState(() => _p = _p.copyWith(username: v.replaceFirst('@', '').trim())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _city,
            decoration: _dec('Ciudad', hint: 'Opcional'),
            onChanged: (v) => setState(() => _p = _p.copyWith(city: v)),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _bio,
        maxLength: 120,
        maxLines: 3,
        decoration: _dec('Descripción', hint: 'Cuéntales algo de ti en una o dos líneas'),
        onChanged: (v) => setState(() => _p = _p.copyWith(bio: v)),
      ),
      _section('Gustos (hasta 5)', [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final g in _p.interests)
            InputChip(
              label: Text(g),
              onDeleted: () => setState(() => _p = _p.copyWith(interests: _p.interests.where((x) => x != g).toList())),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(controller: _newInterest, decoration: _dec('Nuevo gusto', hint: 'Ej: Cocina, Gaming'))),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              final g = _newInterest.text.trim();
              if (g.isEmpty || _p.interests.length >= 5 || _p.interests.contains(g)) return;
              setState(() => _p = _p.copyWith(interests: [..._p.interests, g]));
              _newInterest.clear();
            },
            child: const Text('Agregar'),
          ),
        ]),
      ]),
      _section('Enlace destacado (opcional)', [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostrar un botón extra'),
          subtitle: const Text('Para tu tienda, tu música, tu página web… lo que quieras.'),
          value: _p.featuredEnabled,
          onChanged: (v) => setState(() => _p = _p.copyWith(featuredEnabled: v)),
        ),
        if (_p.featuredEnabled) ...[
          TextField(
            controller: _featTitle,
            decoration: _dec('Título del botón', hint: 'Ej: Mi tienda'),
            onChanged: (v) => setState(() => _p = _p.copyWith(featuredTitle: v)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _featUrl,
            keyboardType: TextInputType.url,
            decoration: _dec('Dirección', hint: 'https://...'),
            onChanged: (v) => setState(() => _p = _p.copyWith(featuredUrl: v.trim())),
          ),
        ],
      ]),
    ]);
  }

  Widget _thumb(
      {required bool selected,
      required Widget child,
      required VoidCallback onTap,
      required String label,
      double height = 104}) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 76,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? const Color(0xFF4B3BEF) : Colors.transparent, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(fit: StackFit.expand, children: [
              child,
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        maxLines: 1,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _segmented<T>(List<(String, T)> options, T value, ValueChanged<T> onChanged) {
    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [for (final o in options) ButtonSegment(value: o.$2, label: Text(o.$1))],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }

  Widget _fondo() {
    final custom = _s.customBackgroundUrl;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _section('Imagen de fondo', [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _thumb(
              label: custom == null ? 'Subir' : 'Cambiar',
              selected: _s.background == 'custom',
              onTap: () async {
                final path = await _pick();
                if (path != null) {
                  _style(_s.copyWith(background: 'custom', customBackgroundUrl: path, clearAccent: true));
                } else if (custom != null) {
                  _style(_s.copyWith(background: 'custom', clearAccent: true));
                }
              },
              child: custom == null
                  ? const ColoredBox(
                      color: Color(0xFFF0F1F5), child: Icon(Icons.add_photo_alternate_outlined, size: 28))
                  : ProfileBackground(
                      style: _s.copyWith(background: 'custom', dim: 0, blur: false), child: const SizedBox()),
            ),
            for (final p in kImagePresets)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _thumb(
                  label: p.label,
                  selected: _s.background == p.id,
                  onTap: () => _style(_s.copyWith(background: p.id, clearAccent: true)),
                  child: BackgroundThumb(presetId: p.id),
                ),
              ),
          ]),
        ),
      ]),
      _section('Degradados y patrones', [
        Row(children: [
          for (final p in kPatternPresets)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _thumb(
                label: p.label,
                height: 72,
                selected: _s.background == p.id,
                onTap: () => _style(_s.copyWith(background: p.id, clearAccent: true)),
                child: BackgroundThumb(presetId: p.id),
              ),
            ),
        ]),
      ]),
      _section('Oscurecer fondo (para leer mejor)', [
        _segmented([('Suave', 0), ('Medio', 1), ('Fuerte', 2)], _s.dim, (v) => _style(_s.copyWith(dim: v))),
      ]),
      if (_s.background == 'custom')
        _section('Tu imagen', [
          _segmented([('Nítida', false), ('Desenfocada', true)], _s.blur, (v) => _style(_s.copyWith(blur: v))),
        ]),
    ]);
  }

  Widget _foto() {
    final look = ProfileLook(_s);
    final rings = ringOptions(look.accent);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () async {
              final path = await _pick();
              if (path != null) setState(() => _p = _p.copyWith(avatarUrl: path));
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Elegir foto'),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      _section('Forma', [
        _segmented([('Círculo', 'circulo'), ('Redondeada', 'redondeada'), ('Cuadrada', 'cuadrada')], _s.avatarShape,
            (v) => _style(_s.copyWith(avatarShape: v))),
      ]),
      _section('Aro de la foto', [
        Wrap(spacing: 12, children: [
          for (var i = 0; i < rings.length; i++)
            Semantics(
              button: true,
              selected: _s.ring == i,
              label: rings[i].label,
              child: GestureDetector(
                onTap: () => _style(_s.copyWith(ring: i)),
                child: Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _s.ring == i ? const Color(0xFF4B3BEF) : Colors.transparent, width: 3),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: rings[i].gradient,
                      color: i == 4 ? const Color(0xFFF0F1F5) : rings[i].color,
                      border: Border.all(color: const Color(0xFFD5D7E0)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    ]);
  }

  Widget _estilo() {
    final preset = presetById(_s.background);
    final accents = [preset.accent, ...kAccentChoices];
    return ListView(padding: const EdgeInsets.all(16), children: [
      _section('Tipografía', [
        Row(children: [
          for (final f in const [('moderna', 'Moderna'), ('elegante', 'Elegante'), ('divertida', 'Divertida')])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(80),
                    side: BorderSide(
                        color: _s.font == f.$1 ? const Color(0xFF4B3BEF) : const Color(0xFFD5D7E0), width: 2),
                  ),
                  onPressed: () => _style(_s.copyWith(font: f.$1)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Aa',
                        style:
                            ProfileLook(_s.copyWith(font: f.$1)).titleFont(size: 26, color: const Color(0xFF12131A))),
                    Text(f.$2, style: const TextStyle(fontSize: 12)),
                  ]),
                ),
              ),
            ),
        ]),
      ]),
      _section('Botones', [
        _segmented([('Vidrio', 'vidrio'), ('Relleno', 'relleno'), ('Contorno', 'contorno')], _s.buttons,
            (v) => _style(_s.copyWith(buttons: v))),
      ]),
      _section('Color de acento', [
        Wrap(spacing: 12, children: [
          for (var i = 0; i < accents.length; i++)
            Semantics(
              button: true,
              label: i == 0 ? 'Color del fondo' : 'Color ${i + 1}',
              selected: i == 0 ? _s.accent == null : _s.accent == accents[i].toARGB32(),
              child: GestureDetector(
                onTap: () => i == 0
                    ? _style(_s.copyWith(clearAccent: true))
                    : _style(_s.copyWith(accent: accents[i].toARGB32())),
                child: Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (i == 0 ? _s.accent == null : _s.accent == accents[i].toARGB32())
                          ? const Color(0xFF4B3BEF)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accents[i],
                      border: Border.all(color: const Color(0xFFD5D7E0)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    ]);
  }

  Widget _redes() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _section('Toca para mostrar u ocultar', [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final n in kNetworks)
            FilterChip(
              avatar: NetworkBadge(network: n, size: 22),
              label: Text(n.label),
              selected: _p.networks.contains(n.id),
              showCheckmark: false,
              onSelected: (on) => setState(() {
                final list = [..._p.networks];
                on ? list.add(n.id) : list.remove(n.id);
                _p = _p.copyWith(networks: list);
              }),
            ),
        ]),
      ]),
      _section('Tus datos en cada red', [
        for (final id in _p.networks) ...[
          Builder(builder: (_) {
            final n = networkById(id);
            final link = n.linkFor(_p.socials[id]);
            return TextField(
              controller: _socialCtl(id),
              keyboardType: n.keyboard,
              decoration: InputDecoration(
                prefixIcon: Padding(padding: const EdgeInsets.all(10), child: NetworkBadge(network: n, size: 24)),
                labelText: n.fieldLabel,
                hintText: n.hint,
                helperText: link == null ? 'Puedes pegar tu enlace o solo tu usuario' : 'Se abrirá: $link',
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _p = _p.copyWith(socials: {..._p.socials, id: v.trim()})),
            );
          }),
          const SizedBox(height: 14),
        ],
        if (_p.networks.isEmpty) const Text('Activa al menos una red arriba.'),
      ]),
    ]);
  }
}
