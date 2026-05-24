import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_preview.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_result.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/presentation/view_models/local_data_import_view_model.dart';

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

        return Scaffold(
          appBar: AppBar(title: const Text('Importar dados locais')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Revise o backup antes de importar. RATs já existentes não serão duplicadas.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _selectBackup(context),
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text('Selecionar backup JSON'),
                ),
                if (viewModel.isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (result != null) ...[
                  const SizedBox(height: 24),
                  _ImportResultSection(result: result),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Concluir'),
                  ),
                ] else if (preview != null) ...[
                  const SizedBox(height: 24),
                  _ImportPreviewSection(preview: preview),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: preview.canApply && !viewModel.isLoading
                        ? () => viewModel.apply(
                            conflictPolicy: LocalImportConflictPolicy.skip,
                          )
                        : null,
                    child: Text(
                      preview.hasConflicts
                          ? 'Importar novos e pular conflitos'
                          : 'Importar backup',
                    ),
                  ),
                  if (preview.hasConflicts) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: preview.canApply && !viewModel.isLoading
                          ? () => _confirmOverwriteConflicts(context)
                          : null,
                      child: const Text('Substituir conflitos'),
                    ),
                  ],
                ],
              ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Resumo do backup',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _InfoRow(label: 'RATs no arquivo', value: '${preview.totalRats}'),
        _InfoRow(
          label: 'Assinaturas no arquivo',
          value: '${preview.totalAssinaturas}',
        ),
        _InfoRow(label: 'Novos ou restaurados', value: '${preview.newRats}'),
        _InfoRow(label: 'Duplicados iguais', value: '${preview.duplicateRats}'),
        _InfoRow(label: 'Conflitos', value: '${preview.conflictingRats}'),
        _InfoRow(label: 'Itens inválidos', value: '${preview.invalidItems}'),
      ],
    );
  }
}

class _ImportResultSection extends StatelessWidget {
  const _ImportResultSection({required this.result});

  final LocalImportResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Importação concluída',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _InfoRow(label: 'RATs importadas', value: '${result.importedRats}'),
        _InfoRow(
          label: 'Duplicados ignorados',
          value: '${result.ignoredDuplicates}',
        ),
        _InfoRow(
          label: 'Conflitos pulados',
          value: '${result.skippedConflicts}',
        ),
        _InfoRow(
          label: 'Conflitos substituídos',
          value: '${result.overwrittenConflicts}',
        ),
        _InfoRow(
          label: 'Assinaturas importadas',
          value: '${result.importedAssinaturas}',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
