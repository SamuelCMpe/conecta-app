import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/styled_qr.dart';

/// Elegir cómo se ve mi código QR.
class QrDesignScreen extends StatefulWidget {
  final Profile initial;
  const QrDesignScreen({super.key, required this.initial});
  @override
  State<QrDesignScreen> createState() => _QrDesignScreenState();
}

class _QrDesignScreenState extends State<QrDesignScreen> {
  late int _style = widget.initial.style.qrStyle;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final p = widget.initial.copyWith(style: widget.initial.style.copyWith(qrStyle: _style));
      await context.read<AppState>().saveProfile(p);
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
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        title: Text('Diseño del QR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Guardando…' : 'Guardar')),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: StyledQr(
                data: 'qrconecta:vista-previa-del-diseno', profile: widget.initial, styleIndex: _style, size: 220),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Vista previa: el código real cambia cada 30 segundos.',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5B5E6B), fontSize: 13)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            for (var i = 0; i < kQrStyles.length; i++)
              Semantics(
                button: true,
                selected: i == _style,
                label: kQrStyles[i].label,
                child: GestureDetector(
                  onTap: () => setState(() => _style = i),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: i == _style ? const Color(0xFF4B3BEF) : const Color(0xFFE6E7EE),
                          width: i == _style ? 3 : 1),
                    ),
                    child: Column(children: [
                      Expanded(
                        child: FittedBox(
                          child: StyledQr(data: 'qrconecta:muestra', profile: widget.initial, styleIndex: i, size: 120),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(kQrStyles[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}
