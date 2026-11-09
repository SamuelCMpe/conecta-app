import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/networks.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../theme/polaroid.dart';
import '../widgets/profile_card.dart';

/// "Diseña tu polaroid": stickers, marco, foto, datos y redes, con vista previa.
class PolaroidEditorScreen extends StatefulWidget {
  final Profile initial;
  final int initialTab;
  const PolaroidEditorScreen({super.key, required this.initial, this.initialTab = 0});
  @override
  State<PolaroidEditorScreen> createState() => _PolaroidEditorScreenState();
}

class _PolaroidEditorScreenState extends State<PolaroidEditorScreen> {
  static const _tabs = ['Stickers', 'Marco', 'Foto', 'Datos', 'Redes'];
  late Profile _p = widget.initial;
  late int _tab = widget.initialTab;
  bool _saving = false;

  late final _name = TextEditingController(text: _p.displayName);
  late final _user = TextEditingController(text: _p.username);
  late final _city = TextEditingController(text: _p.city);
  late final _bio = TextEditingController(text: _p.bio);
  final _newInterest = TextEditingController();
  final _newSticker = TextEditingController();
  final Map<String, TextEditingController> _social = {};

  ProfileStyle get _s => _p.style;
  void _style(ProfileStyle s) => setState(() => _p = _p.copyWith(style: s));

  TextEditingController _socialCtl(String id) =>
      _social.putIfAbsent(id, () => TextEditingController(text: _p.socials[id] ?? ''));

  @override
  void dispose() {
    for (final c in [_name, _user, _city, _bio, _newInterest, _newSticker, ..._social.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_p.displayName.trim().isEmpty) {
      setState(() => _tab = 3);
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

  void _toggleSticker(String s) {
    final list = [..._s.stickers];
    if (list.contains(s)) {
      list.remove(s);
    } else {
      if (list.length >= 3) {
        showError(context, 'Máximo 3 stickers. Quita uno primero.');
        return;
      }
      list.add(s);
    }
    _style(_s.copyWith(stickers: list));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              RoundIconButton(Icons.close, tooltip: 'Cancelar', onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(child: Text('Tu polaroid', style: display(20))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Pal.yellow, foregroundColor: Pal.ink),
                onPressed: _saving ? null : _save,
                child:
                    Text(_saving ? 'Guardando…' : 'Guardar', style: body(14, color: Pal.ink, weight: FontWeight.w800)),
              ),
            ]),
          ),
          SizedBox(
            height: 290,
            child: Center(child: ProfilePolaroid(profile: _p, width: 200)),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Pal.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(children: [
                SizedBox(
                  height: 62,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ChoiceChip(
                      label: Text(_tabs[i]),
                      selected: i == _tab,
                      showCheckmark: false,
                      labelStyle:
                          body(14, color: i == _tab ? Pal.ink : const Color(0xFFBDBAC7), weight: FontWeight.w700),
                      selectedColor: Colors.white,
                      backgroundColor: Pal.glass,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onSelected: (_) => setState(() => _tab = i),
                    ),
                  ),
                ),
                Expanded(child: [_stickers, _marco, _foto, _datos, _redes][_tab]()),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(t, style: body(13, color: Pal.muted, weight: FontWeight.w600)));

  // ---------- Stickers ----------
  Widget _stickers() {
    final mine = _s.stickers;
    final all = [...mine, ...kSuggestedStickers.where((s) => !mine.contains(s))];
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
      _label('Toca para agregar o quitar (máx. 3)'),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < all.length; i++)
          GestureDetector(
            onTap: () => _toggleSticker(all[i]),
            child: Container(
              decoration: mine.contains(all[i])
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white, width: 2.5))
                  : null,
              padding: const EdgeInsets.all(2),
              child: Sticker(all[i], color: i, size: 13.5),
            ),
          ),
      ]),
      const SizedBox(height: 18),
      _label('O escribe el tuyo'),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _newSticker,
            maxLength: 22,
            decoration: const InputDecoration(hintText: 'Ej: 📍 Máncora', counterText: ''),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: () {
            final t = _newSticker.text.trim();
            if (t.isEmpty) return;
            _toggleSticker(t);
            _newSticker.clear();
          },
          child: const Text('Agregar'),
        ),
      ]),
    ]);
  }

  // ---------- Marco ----------
  Widget _marco() {
    const names = ['Blanco', 'Rosa', 'Crema', 'Menta', 'Negro'];
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
      _label('Color del marco'),
      Wrap(spacing: 16, runSpacing: 16, children: [
        for (var i = 0; i < kFrameColors.length; i++)
          GestureDetector(
            onTap: () => _style(_s.copyWith(frame: i)),
            child: Column(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kFrameColors[i],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _s.frame == i ? Pal.yellow : Pal.line, width: _s.frame == i ? 3 : 1),
                ),
              ),
              const SizedBox(height: 6),
              Text(names[i], style: body(12.5, color: _s.frame == i ? Pal.text : Pal.muted)),
            ]),
          ),
      ]),
    ]);
  }

  // ---------- Foto ----------
  Widget _foto() {
    Future<void> pick(ImageSource src) async {
      final f = await ImagePicker().pickImage(
        source: src,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (f != null) setState(() => _p = _p.copyWith(avatarUrl: f.path));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
      _label('Tu foto de la polaroid'),
      BigButton('Elegir de mi galería', icon: Icons.photo_library_outlined, onTap: () => pick(ImageSource.gallery)),
      const SizedBox(height: 12),
      BigButton('Tomarme una foto',
          icon: Icons.photo_camera_outlined,
          color: Pal.glass,
          textColor: Pal.text,
          onTap: () => pick(ImageSource.camera)),
      if ((_p.avatarUrl ?? '').isNotEmpty) ...[
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _p = Profile.fromRow({..._p.toRow(), 'avatar_url': null})),
          child: Text('Quitar foto', style: body(14, color: const Color(0xFFFF8FB1), weight: FontWeight.w700)),
        ),
      ],
    ]);
  }

  // ---------- Datos ----------
  Widget _datos() {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
      TextField(
        controller: _name,
        decoration: const InputDecoration(labelText: 'Tu nombre'),
        onChanged: (v) => setState(() => _p = _p.copyWith(displayName: v)),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _user,
            decoration: const InputDecoration(labelText: 'Usuario', hintText: 'tu.usuario'),
            onChanged: (v) => setState(() => _p = _p.copyWith(username: v.replaceFirst('@', '').trim())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'Ciudad', hintText: 'Opcional'),
            onChanged: (v) => setState(() => _p = _p.copyWith(city: v)),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _bio,
        maxLength: 120,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Tu frase', hintText: 'Algo corto sobre ti'),
        onChanged: (v) => setState(() => _p = _p.copyWith(bio: v)),
      ),
      _label('Gustos (hasta 5)'),
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
          child: TextField(
            controller: _newInterest,
            decoration: const InputDecoration(hintText: 'Ej: 🎮 Gaming'),
          ),
        ),
        const SizedBox(width: 10),
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
    ]);
  }

  // ---------- Redes ----------
  Widget _redes() {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
      _label('Toca para mostrar u ocultar'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final n in kNetworks)
          FilterChip(
            label: Text(n.label),
            selected: _p.networks.contains(n.id),
            showCheckmark: false,
            selectedColor: Pal.yellow,
            labelStyle: body(13.5, color: _p.networks.contains(n.id) ? Pal.ink : Pal.text, weight: FontWeight.w700),
            onSelected: (on) => setState(() {
              final list = [..._p.networks];
              on ? list.add(n.id) : list.remove(n.id);
              _p = _p.copyWith(networks: list);
            }),
          ),
      ]),
      const SizedBox(height: 14),
      _label('Tus datos en cada red'),
      for (final id in _p.networks) ...[
        Builder(builder: (_) {
          final n = networkById(id);
          final link = n.linkFor(_p.socials[id]);
          return TextField(
            controller: _socialCtl(id),
            keyboardType: n.keyboard,
            decoration: InputDecoration(
              prefixIcon: Padding(padding: const EdgeInsets.all(8), child: NetCircle(network: n, size: 30)),
              labelText: n.fieldLabel,
              hintText: n.hint,
              helperText: link == null ? 'Puedes pegar tu enlace o solo tu usuario' : 'Se abrirá: $link',
              helperMaxLines: 2,
            ),
            onChanged: (v) => setState(() => _p = _p.copyWith(socials: {..._p.socials, id: v.trim()})),
          );
        }),
        const SizedBox(height: 14),
      ],
      if (_p.networks.isEmpty) Text('Activa al menos una red arriba.', style: body(14, color: Pal.muted)),
    ]);
  }
}
