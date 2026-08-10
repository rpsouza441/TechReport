import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat_audit_event.dart';
import 'package:techreport/features/rat/presentation/widgets/rat_audit_diff_row.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';

class RatAuditEventCard extends StatefulWidget {
  const RatAuditEventCard({super.key, required this.event, this.currentUserId});

  final RatAuditEvent event;
  final String? currentUserId;

  @override
  State<RatAuditEventCard> createState() => _RatAuditEventCardState();
}

class _RatAuditEventCardState extends State<RatAuditEventCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.event.diffs.length <= 3;
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final title = _eventTitle(event.type);
    final actor = event.actorUserId == widget.currentUserId
        ? 'Você'
        : _actorLabel(event);
    final date = _formatDate(event.editedAt);
    final count = event.diffs.length;

    return Semantics(
      container: true,
      label:
          '$title, por ${_actorLabel(event)}, em $date, '
          '$count ${count == 1 ? 'campo alterado' : 'campos alterados'}, '
          '${_expanded ? 'expandido' : 'recolhido'}.',
      child: TechReportCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: MetricSlateSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: MetricSlateSpacing.xxs),
                      Text(
                        '$actor · $date',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: _expanded
                        ? 'Recolher alterações'
                        : 'Expandir alterações',
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  ),
              ],
            ),
            if (count > 0 && !_expanded)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = true),
                  child: Text(
                    event.type == RatAuditEventType.created
                        ? 'Ver dados iniciais'
                        : 'Ver $count alterações',
                  ),
                ),
              ),
            if (_expanded && count > 0) ...[
              const SizedBox(height: MetricSlateSpacing.md),
              for (var index = 0; index < event.diffs.length; index++) ...[
                RatAuditDiffRow(diff: event.diffs[index]),
                if (index < event.diffs.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: MetricSlateSpacing.sm,
                    ),
                    child: Divider(),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _actorLabel(RatAuditEvent event) {
    final name = event.actorName.trim();
    if (name.isNotEmpty) return name;
    final id = event.actorUserId;
    return 'Usuário · ${id.length <= 8 ? id : id.substring(0, 8)}';
  }

  String _eventTitle(RatAuditEventType type) => switch (type) {
    RatAuditEventType.created => 'RAT criada',
    RatAuditEventType.updated => 'RAT atualizada',
    RatAuditEventType.trashed => 'Movida para a lixeira',
    RatAuditEventType.restored => 'RAT restaurada',
  };

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        'às ${two(local.hour)}:${two(local.minute)}';
  }
}
