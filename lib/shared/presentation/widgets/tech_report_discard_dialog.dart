import 'package:flutter/material.dart';

/// Helper para dialogo de descarte de alteracoes nao salvas.
///
/// Retorna `true` se o usuario confirmar o descarte,
/// `false` se cancelar ou se o dialog for dispensado.
///
/// Usage:
/// ```dart
/// final discard = await showTechReportDiscardDialog(context);
/// if (discard) { Navigator.of(context).pop(); }
/// ```
Future<bool> showTechReportDiscardDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar alterações?'),
      content: const Text(
        'Suas alterações não foram salvas. Deseja descartá-las?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  return result ?? false;
}
