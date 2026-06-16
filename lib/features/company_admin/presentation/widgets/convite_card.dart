import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_auth/data/services/secure_token_store.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';

/// Card que exibe um convite pendente com ações de compartilhar e cancelar.
class ConviteCard extends StatefulWidget {
  const ConviteCard({
    super.key,
    required this.convite,
    this.onCancel,
  });

  final AdminConviteResumo convite;
  final VoidCallback? onCancel;

  @override
  State<ConviteCard> createState() => ConviteCardState();
}

class ConviteCardState extends State<ConviteCard> {
  void share() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ConviteShareSheet(
        convite: widget.convite,
        papelLabel: _papelLabel(widget.convite.papel),
        formattedExpiry: _formatDateTime(widget.convite.expiresAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mail_outline, color: theme.colorScheme.primary),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.convite.nome, style: theme.textTheme.titleMedium),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(widget.convite.email),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(
                  _papelLabel(widget.convite.papel),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(
                  'Expira em ${_formatDateTime(widget.convite.expiresAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: share,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartilhar convite',
          ),
          if (widget.onCancel != null)
            IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancelar convite',
            ),
        ],
      ),
    );
  }

  String _papelLabel(AdminTecnicoPapel papel) {
    return switch (papel) {
      AdminTecnicoPapel.adminEmpresa => 'Admin empresa',
      AdminTecnicoPapel.gerente => 'Gerente',
      AdminTecnicoPapel.tecnico => 'Técnico',
    };
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

/// Bottom sheet para compartilhar convite.
class ConviteShareSheet extends StatelessWidget {
  const ConviteShareSheet({
    super.key,
    required this.convite,
    required this.papelLabel,
    required this.formattedExpiry,
  });

  final AdminConviteResumo convite;
  final String papelLabel;
  final String formattedExpiry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: MetricSlateSpacing.lg,
        right: MetricSlateSpacing.lg,
        top: MetricSlateSpacing.lg,
        bottom:
            MetricSlateSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, color: theme.colorScheme.primary),
              const SizedBox(width: MetricSlateSpacing.sm),
              Text('Compartilhar convite', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: MetricSlateSpacing.md),
          Text('Nome: ${convite.nome}', style: theme.textTheme.bodyMedium),
          Text('E-mail: ${convite.email}', style: theme.textTheme.bodyMedium),
          Text('Perfil: $papelLabel', style: theme.textTheme.bodyMedium),
          Text('Expira em: $formattedExpiry', style: theme.textTheme.bodySmall),
          const SizedBox(height: MetricSlateSpacing.sm),
          Text(
            'O código do convite foi exibido na tela após a criação. '
            'Se não copiou, gere um novo convite.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: MetricSlateSpacing.lg),
          FilledButton.icon(
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  subject: 'Convite TechReport',
                  text:
                      'Convite TechReport\n\n'
                      'Nome: ${convite.nome}\n'
                      'E-mail: ${convite.email}\n'
                      'Perfil: $papelLabel\n\n'
                      'O código foi exibido após a criação do convite. '
                      'Se não copiou, gere um novo convite no app.',
                ),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartilhar'),
          ),
          const SizedBox(height: MetricSlateSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

/// Banner warning that a pending invite is about to expire.
class ConviteExpiryWarning extends StatelessWidget {
  const ConviteExpiryWarning({
    super.key,
    required this.invite,
    this.onDismiss,
  });

  final PendingCompanyInvite invite;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(MetricSlateSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: MetricSlateSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Convite prestes a expirar',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Seu convite expira em ${invite.remainingTime}. '
                    'Aguarde o e-mail de confirmação.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onErrorContainer,
                ),
                tooltip: 'Dispensar',
              ),
          ],
        ),
      ),
    );
  }
}
