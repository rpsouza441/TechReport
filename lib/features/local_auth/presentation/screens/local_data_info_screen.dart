import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_info_row.dart';

class LocalDataInfoScreen extends StatefulWidget {
  const LocalDataInfoScreen({
    super.key,
    required this.ratRepository,
    this.latestBackupAt,
  });

  final RatRepository ratRepository;
  final DateTime? latestBackupAt;

  @override
  State<LocalDataInfoScreen> createState() => _LocalDataInfoScreenState();
}

class _LocalDataInfoScreenState extends State<LocalDataInfoScreen> {
  List<Rat>? _rats;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rats = await widget.ratRepository.listAllLocalForBackup();
      if (!mounted) return;
      setState(() {
        _rats = rats;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informações dos dados')),
      body: SafeArea(
        child: _rats == null && _error == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                children: [
                  if (_error != null) ...[
                    const TechReportErrorBanner(
                      message:
                          'Não foi possível carregar as informações locais.',
                    ),
                    const SizedBox(height: MetricSlateSpacing.md),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Tentar novamente'),
                    ),
                  ] else ...[
                    TechReportCard(
                      child: Column(
                        children: [
                          TechReportInfoRow(
                            label: 'RATs ativas',
                            value:
                                '${_rats!.where((rat) => !rat.isDeleted).length}',
                          ),
                          TechReportInfoRow(
                            label: 'Na lixeira',
                            value:
                                '${_rats!.where((rat) => rat.isDeleted).length}',
                          ),
                          TechReportInfoRow(
                            label: 'Última atualização local',
                            value: _latestLocalUpdate,
                          ),
                          if (widget.latestBackupAt != null)
                            TechReportInfoRow(
                              label: 'Backup mais recente',
                              value: _formatDate(widget.latestBackupAt!),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MetricSlateSpacing.md),
                    const TechReportCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.enhanced_encryption_outlined),
                          SizedBox(width: MetricSlateSpacing.sm),
                          Expanded(
                            child: Text(
                              'O banco local continua criptografado. '
                              'A chave é gerenciada automaticamente pelo app.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  String get _latestLocalUpdate {
    if (_rats == null || _rats!.isEmpty) return 'Nenhuma atualização';
    final latest = _rats!
        .map((rat) => rat.updatedAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);
    return _formatDate(latest);
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        'às ${two(local.hour)}:${two(local.minute)}';
  }
}
