import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/profile.dart';
import 'common.dart';

class QrStyleOption {
  final String label;
  final Color color;
  final bool dots;
  final bool roundEyes;
  const QrStyleOption(this.label, this.color, {this.dots = false, this.roundEyes = false});
}

const kQrStyles = [
  QrStyleOption('Clásico', Color(0xFF12131A)),
  QrStyleOption('Morado con puntos', Color(0xFF4A1E5C), dots: true),
  QrStyleOption('Azul', Color(0xFF0B4A7A)),
  QrStyleOption('Coral con puntos', Color(0xFFB2402A), dots: true),
  QrStyleOption('Verde redondo', Color(0xFF0B5C35), dots: true, roundEyes: true),
  QrStyleOption('Negro redondo', Color(0xFF12131A), dots: true, roundEyes: true),
];

QrStyleOption qrStyleAt(int i) => kQrStyles[i.clamp(0, kQrStyles.length - 1)];

/// Código QR con el estilo elegido y la foto de la persona en el centro.
class StyledQr extends StatelessWidget {
  final String data;
  final Profile profile;
  final int styleIndex;
  final double size;
  const StyledQr({super.key, required this.data, required this.profile, required this.styleIndex, this.size = 250});

  @override
  Widget build(BuildContext context) {
    final st = qrStyleAt(styleIndex);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        QrImageView(
          data: data,
          size: size,
          padding: EdgeInsets.zero,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          eyeStyle: QrEyeStyle(eyeShape: st.roundEyes ? QrEyeShape.circle : QrEyeShape.square, color: st.color),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: st.dots ? QrDataModuleShape.circle : QrDataModuleShape.square,
            color: st.color,
          ),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size)),
          padding: const EdgeInsets.all(3),
          child: Avatar(profile: profile, size: size * 0.19),
        ),
      ]),
    );
  }
}
