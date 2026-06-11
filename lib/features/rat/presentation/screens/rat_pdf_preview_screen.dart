import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/utils/rat_number_formatter.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

class RatPdfPreviewScreen extends StatefulWidget {
  const RatPdfPreviewScreen({
    super.key,
    required this.rat,
    required this.onShare,
    required this.onSave,
    this.signatureBytes,
    this.empresaNome,
    this.tecnicoNome,
  });

  final Rat rat;
  final Uint8List? signatureBytes;
  final Future<void> Function() onShare;
  final Future<void> Function() onSave;
  final String? empresaNome;
  final String? tecnicoNome;

  @override
  State<RatPdfPreviewScreen> createState() => _RatPdfPreviewScreenState();
}

class _RatPdfPreviewScreenState extends State<RatPdfPreviewScreen> {
  bool _isSharing = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Prévia do PDF'), centerTitle: true),
      body: Column(
        children: [
          // ── Documento ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MetricSlateSpacing.md),
              child: Center(
                child: _A4DocumentPreview(
                  rat: widget.rat,
                  signatureBytes: widget.signatureBytes,
                  empresaNome: widget.empresaNome,
                  tecnicoNome: widget.tecnicoNome,
                ),
              ),
            ),
          ),

          // ── Indicador de página ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: MetricSlateSpacing.xs,
            ),
            color: scheme.surfaceContainerLow,
            child: Center(
              child: Text(
                '1 / 1',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ),
          ),

          // ── Barra de ações ──────────────────────────────────────────
          _ActionBar(
            isSharing: _isSharing,
            isSaving: _isSaving,
            onBack: () => Navigator.of(context).pop(),
            onShare: _handleShare,
            onSave: _handleSave,
          ),
        ],
      ),
    );
  }

  Future<void> _handleShare() async {
    if (_isSharing || _isSaving) return;

    setState(() => _isSharing = true);

    try {
      await widget.onShare();
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (_isSharing || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await widget.onSave();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _A4DocumentPreview extends StatelessWidget {
  const _A4DocumentPreview({
    required this.rat,
    this.signatureBytes,
    this.empresaNome,
    this.tecnicoNome,
  });

  final Rat rat;
  final Uint8List? signatureBytes;
  final String? empresaNome;
  final String? tecnicoNome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Proporção A4 aproximada (210/297 ≈ 0.707)
    return AspectRatio(
      aspectRatio: 0.707,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabeçalho ────────────────────────────────────────────
              _buildHeader(scheme),
              const SizedBox(height: 16),

              // ── Identificação ───────────────────────────────────────
              _buildSection(
                context,
                title: 'Identificação',
                children: [
                  _infoRow('RAT', ratDisplayNumber(rat.numero)),
                  _infoRow('Cliente', rat.clienteNome),
                  _infoRow(
                    'Responsável',
                    rat.responsavelRecebimento ?? ratNotInformedLabel,
                  ),
                  if (rat.responsavelDocumento != null)
                    _infoRow('Documento', rat.responsavelDocumento!),
                  _infoRow('Data da visita', _formatDate(rat.dataVisita)),
                  _infoRow(
                    'Horário',
                    '${rat.horarioInicioAtendimento ?? '--:--'} até '
                        '${rat.horarioTerminoAtendimento ?? '--:--'}',
                  ),
                  _buildStatusBadge(context, rat.status),
                ],
              ),
              const SizedBox(height: 14),

              // ── Descrição ───────────────────────────────────────────
              _buildSection(
                context,
                title: 'Descrição do atendimento',
                children: [
                  Text(
                    rat.descricao,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Equipamento ──────────────────────────────────────────
              _buildSection(
                context,
                title: 'Equipamento',
                children: [
                  _infoRow(
                    'Movimentação',
                    equipamentoMovimentoLabel(
                      rat.equipamentoMovimentoTipo ??
                          EquipamentoMovimentoTipo.nenhum,
                    ),
                  ),
                  _infoRow(
                    'Descrição',
                    rat.equipamentoDescricao ?? ratNotInformedLabel,
                  ),
                  if (rat.equipamentoObservacao != null &&
                      rat.equipamentoObservacao!.isNotEmpty)
                    _infoRow('Observação', rat.equipamentoObservacao!),
                ],
              ),
              const SizedBox(height: 14),

              // ── Assinatura ─────────────────────────────────────────
              _buildSection(
                context,
                title: 'Assinatura',
                children: [
                  if (signatureBytes == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Assinatura não capturada.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 100,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Image.memory(signatureBytes!, fit: BoxFit.contain),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF1565C0), width: 2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TechReport',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Relatório de Atendimento Técnico',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        if (empresaNome != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2, top: 4),
            child: Text(
              'Empresa: $empresaNome',
              style: TextStyle(fontSize: 8, color: Colors.grey[600]),
            ),
          ),
        if (tecnicoNome != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'Técnico: $tecnicoNome',
              style: TextStyle(fontSize: 8, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 9, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, RatStatus status) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TechReportStatusChip(
        label: ratStatusLabel(status),
        tone: ratStatusTone(status),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return ratNotInformedLabel;
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isSharing,
    required this.isSaving,
    required this.onBack,
    required this.onShare,
    required this.onSave,
  });

  final bool isSharing;
  final bool isSaving;
  final VoidCallback onBack;
  final Future<void> Function() onShare;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBusy = isSharing || isSaving;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: MetricSlateSpacing.md,
        right: MetricSlateSpacing.md,
        top: MetricSlateSpacing.sm,
        bottom: bottomPadding + MetricSlateSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // ── Voltar ────────────────────────────────────────────────
          IconButton(
            onPressed: isBusy ? null : onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(width: MetricSlateSpacing.xs),

          // ── Enviar ────────────────────────────────────────────────
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onShare,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: MetricSlateSpacing.sm,
                  vertical: MetricSlateSpacing.md,
                ),
              ),
              icon: isSharing
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.share_outlined, size: 18),
              label: Text(
                isSharing ? 'Enviando...' : 'Enviar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(width: MetricSlateSpacing.sm),

          // ── Salvar ────────────────────────────────────────────────
          Expanded(
            child: FilledButton.icon(
              onPressed: isBusy ? null : onSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: MetricSlateSpacing.sm,
                  vertical: MetricSlateSpacing.md,
                ),
              ),
              icon: isSaving
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save_alt_outlined, size: 18),
              label: Text(
                isSaving ? 'Salvando...' : 'Salvar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
