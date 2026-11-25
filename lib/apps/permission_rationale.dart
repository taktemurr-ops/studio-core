/// İzin istemeden önce nedenini anlatan kısa pencere (Play ve App Store
/// kurallarına uygun: önce açıklama, sonra sistem penceresi).
library;

import 'package:flutter/material.dart';

import 'app_tx.dart';

/// Kullanıcı "Devam et" derse true döner; sistem izin penceresi ancak
/// bundan sonra açılmalıdır.
Future<bool> explainPermission(
  BuildContext context, {
  required String lang,
  required IconData icon,
  required String reason,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: Icon(icon, size: 36),
      title: Text(appTx('perm_title', lang)),
      content: Text(reason),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(appTx('perm_not_now', lang))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(appTx('perm_continue', lang))),
      ],
    ),
  );
  return ok ?? false;
}

/// İzin verilmediğinde kısa bilgi.
void showPermissionDenied(BuildContext context, String lang) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(appTx('perm_denied', lang))));
}
