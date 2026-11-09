import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/networks.dart';
import '../models/profile.dart';
import '../theme/polaroid.dart';

Future<void> openLink(BuildContext context, String? link) async {
  if (link == null || link.isEmpty) {
    showError(context, 'Esta persona no puso ese dato.');
    return;
  }
  final ok = await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showError(context, 'No se pudo abrir $link');
}

/// Abre una red de un perfil.
Future<void> openNetwork(BuildContext context, Profile p, Network n) => openLink(context, n.linkFor(p.socials[n.id]));
