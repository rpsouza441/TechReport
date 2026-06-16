import 'package:flutter/material.dart';

/// Helper para dialogos de confirmacao booleanos simples.
///
/// Retorna `true` se o usuario confirmar, `false` se cancelar ou dispensar.
///
/// Usage:
/// ```dart
/// final confirmed = await showTechReportConfirmationDialog(
///   context: context,
///   title: 'Trocar para modo empresa?',
///   message: 'Seus RATs locais permanecem neste dispositivo.',
///   confirmLabel: 'Trocar',
///   cancelLabel: 'Cancelar',
///   isDangerous: false,
/// );
/// ```
Future<bool> showTechReportConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        isDangerous
            ? TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(confirmLabel),
              )
            : FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
      ],
    ),
  );
  return result ?? false;
}
