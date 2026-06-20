import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';

/// Widget de acoes visuais para gerenciamento de usuarios admin.
///
/// Per UI-12/UI-13 spec FR-004: Regras de permissao, cancelamento e RPC
/// permanecem nos view models/callers. Este widget so lida com apresentacao.
class AdminUserActionChips extends StatelessWidget {
  const AdminUserActionChips({
    super.key,
    required this.ativo,
    required this.mustChangePassword,
    required this.canManage,
    required this.onToggleAtivo,
    required this.onToggleMustChangePassword,
  });

  final bool ativo;
  final bool mustChangePassword;
  final bool canManage;
  final ValueChanged<bool> onToggleAtivo;
  final ValueChanged<bool> onToggleMustChangePassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: MetricSlateSpacing.xxs,
      runSpacing: MetricSlateSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (canManage) ...[
          ActionChip(
            label: Text(ativo ? 'Inativar' : 'Ativar'),
            avatar: Icon(
              ativo ? Icons.cancel_outlined : Icons.check_circle,
              size: 16,
              color: ativo
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            backgroundColor: ativo
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            onPressed: () => onToggleAtivo(!ativo),
          ),
          ActionChip(
            label: Text(mustChangePassword ? 'Senha OK' : 'Trocar senha'),
            avatar: Icon(
              Icons.key_outlined,
              size: 16,
              color: mustChangePassword
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.outline,
            ),
            backgroundColor: mustChangePassword
                ? theme.colorScheme.errorContainer
                : null,
            onPressed: () => onToggleMustChangePassword(!mustChangePassword),
          ),
        ],
      ],
    );
  }
}