import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_preview.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_result.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/presentation/view_models/local_data_import_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_info_row.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';

class LocalDataImportScreen extends StatelessWidget {
  const LocalDataImportScreen({super.key, required this.viewModel});

  final LocalDataImportViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final preview = viewModel.preview;
        final result = viewModel.result;
        final isLoading = viewModel.isLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Importar dados locais')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: TechReportCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TechReportFormHeader(
                          icon: Icons.upload_file_outlined,
                          title: 'Importar backup',
                          subtitle:
                              'Revise o arquivo JSON antes de importar. RATs já existentes não serão duplicadas.',
                        ),
                        const SizedBox(height: MetricSlateSpacing.lg),
                        FilledButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => _selectBackup(context),
                          icon: const Icon(Icons.file_open_outlined, size: 20),
                          label: const Text('Selecionar backup JSON'),
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: MetricSlateSpacing.lg),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        if (viewModel.errorMessage != null) ...[
                          const SizedBox(height: MetricSlateSpacing.md),
                          TechReportErrorBanner(
                            message: viewModel.errorMessage!,
                          ),
                        ],
                        if (result != null) ...[
                          const SizedBox(height: MetricSlateSpacing.lg),
                          _ImportResultSection(result: result),
                          const SizedBox(height: MetricSlateSpacing.lg),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Concluir'),
                          ),
                        ] else if (preview != null) ...[
                          const SizedBox(height: MetricSlateSpacing.lg),
                          _ImportPreviewSection(preview: preview),
                          const SizedBox(height: MetricSlateSpacing.lg),
                          FilledButton.icon(
                            onPressed: preview.canApply && !isLoading
                                ? () => viewModel.apply(
                                    conflictPolicy:
                                        LocalImportConflictPolicy.skip,
                                  )
                                : null,
                            icon: const Icon(Icons.download_outlined, size: 20),
                            label: Text(
                              preview.hasConflicts
                                  ? 'Importar novos e pular conflitos'
                                  : 'Importar backup',
                            ),
                          ),
                          if (preview.hasConflicts) ...[
                            const SizedBox(height: MetricSlateSpacing.sm),
                            OutlinedButton(
                              onPressed: preview.canApply && !isLoading
                                  ? () => _confirmOverwriteConflicts(context)
                                  : null,
                              child: const Text('Substituir conflitos'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectBackup(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && path == null) {
      await viewModel.previewRawJson('');
      return;
    }

    final rawJson = bytes != null
        ? utf8.decode(bytes)
        : await File(path!).readAsString();

    await viewModel.previewRawJson(rawJson);
  }

  Future<void> _confirmOverwriteConflicts(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Substituir conflitos?'),
          content: const Text(
            'RATs com o mesmo ID e conteúdo diferente serão substituídas pelos dados do backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Substituir'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await viewModel.apply(
        conflictPolicy: LocalImportConflictPolicy.overwrite,
      );
    }
  }
}

class _ImportPreviewSection extends StatelessWidget {
  const _ImportPreviewSection({required this.preview});

  final LocalImportPreview preview;

  @override
  Widget build(BuildContext context) {
    return TechReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TechReportSectionHeader(
            title: 'Resumo do backup',
            padding: EdgeInsets.zero,
          ),
          TechReportInfoRow(
            label: 'RATs no arquivo',
            value: '${preview.totalRats}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Assinaturas no arquivo',
            value: '${preview.totalAssinaturas}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Novos ou restaurados',
            value: '${preview.newRats}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Duplicados iguais',
            value: '${preview.duplicateRats}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Conflitos',
            value: '${preview.conflictingRats}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Itens inválidos',
            value: '${preview.invalidItems}',
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _ImportResultSection extends StatelessWidget {
  const _ImportResultSection({required this.result});

  final LocalImportResult result;

  @override
  Widget build(BuildContext context) {
    return TechReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TechReportSectionHeader(
            title: 'Importação concluída',
            padding: EdgeInsets.zero,
          ),
          TechReportInfoRow(
            label: 'RATs importadas',
            value: '${result.importedRats}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Duplicados ignorados',
            value: '${result.ignoredDuplicates}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Conflitos pulados',
            value: '${result.skippedConflicts}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Conflitos substituídos',
            value: '${result.overwrittenConflicts}',
            dense: true,
          ),
          TechReportInfoRow(
            label: 'Assinaturas importadas',
            value: '${result.importedAssinaturas}',
            dense: true,
          ),
        ],
      ),
    );
  }
}
