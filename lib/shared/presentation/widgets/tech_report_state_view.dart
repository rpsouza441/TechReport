import 'package:flutter/material.dart';

/// Widget padrao para estados de loading/vazio/erro.
///
/// Uso:
///   TechReportStateView.empty(message: 'Nenhum item.')
///   TechReportStateView.error(message: 'Falha ao carregar.', ...)
class TechReportStateView extends StatelessWidget {
  const TechReportStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.primaryAction,
  });

  /// Estado vazio padrao.
  const TechReportStateView.empty({
    Key? key,
    String title = 'Nenhum item',
    String message = 'Não há itens para exibir.',
    Widget? primaryAction,
  }) : this._(
         key: key,
         title: title,
         message: message,
         icon: Icons.inbox_outlined,
         primaryAction: primaryAction,
       );

  /// Estado de erro padrao.
  const TechReportStateView.error({
    Key? key,
    String title = 'Algo deu errado',
    required String message,
    Widget? primaryAction,
  }) : this._(
         key: key,
         title: title,
         message: message,
         icon: Icons.error_outline,
         primaryAction: primaryAction,
       );

  const TechReportStateView._({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.primaryAction,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Widget? primaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (primaryAction != null) ...[
              const SizedBox(height: 24),
              primaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}
