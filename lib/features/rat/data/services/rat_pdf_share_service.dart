import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/utils/rat_number_formatter.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';

class RatPdfShareService {
  RatPdfShareService({required AssinaturaRepository assinaturaRepository})
    : _assinaturaRepository = assinaturaRepository;

  final AssinaturaRepository _assinaturaRepository;

  Future<void> share(
    ShareRatLocallyResult shareData, {
    String? empresaNome,
    String? tecnicoNome,
  }) async {
    final pdfBytes = await _buildPdf(
      shareData,
      empresaNome: empresaNome,
      tecnicoNome: tecnicoNome,
    );
    final file = await _saveTemporaryPdf(
      fileName: _pdfFileName(shareData.subject!),
      bytes: pdfBytes,
    );

    await SharePlus.instance.share(
      ShareParams(
        subject: shareData.subject,
        text: shareData.subject,
        files: [XFile(file.path)],
      ),
    );
  }

  /// Salva o PDF no dispositivo via seletor de arquivo (sem sheet de share).
  Future<bool> exportToDevice(
    ShareRatLocallyResult shareData, {
    String? empresaNome,
    String? tecnicoNome,
  }) async {
    final pdfBytes = await _buildPdf(
      shareData,
      empresaNome: empresaNome,
      tecnicoNome: tecnicoNome,
    );
    final fileName = _pdfFileName(shareData.subject!);

    final savedPath = await FilePicker.saveFile(
      dialogTitle: 'Exportar PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: pdfBytes,
    );

    return savedPath != null;
  }

  /// Gera bytes do PDF para preview na tela — aceita empresa/técnico diretamente.
  Future<Uint8List> buildPreviewBytes({
    required Rat rat,
    Uint8List? assinaturaBytes,
    String? empresaNome,
    String? tecnicoNome,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _buildFooter(context),
        build: (context) {
          return [
            _buildHeader(empresaNome: empresaNome, tecnicoNome: tecnicoNome),
            pw.SizedBox(height: 24),
            _buildIdentificationSection(rat),
            pw.SizedBox(height: 18),
            _buildDescriptionSection(rat),
            pw.SizedBox(height: 18),
            _buildEquipamentoSection(rat),
            pw.SizedBox(height: 24),
            _buildAssinaturaSection(assinaturaBytes),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildPdf(
    ShareRatLocallyResult shareData, {
    String? empresaNome,
    String? tecnicoNome,
  }) async {
    final assinaturaBytes = await _loadAssinaturaBytes(shareData.assinatura);
    final rat = shareData.rat;
    if (rat == null) {
      throw StateError('RAT ausente para gerar PDF.');
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _buildFooter(context),
        build: (context) {
          return [
            _buildHeader(empresaNome: empresaNome, tecnicoNome: tecnicoNome),
            pw.SizedBox(height: 24),
            _buildIdentificationSection(rat),
            pw.SizedBox(height: 18),
            _buildDescriptionSection(rat),
            pw.SizedBox(height: 18),
            _buildEquipamentoSection(rat),
            pw.SizedBox(height: 24),
            _buildAssinaturaSection(assinaturaBytes),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader({String? empresaNome, String? tecnicoNome}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TechReport',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  'Relatório de Atendimento Técnico',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
        ),
        if (empresaNome != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              'Empresa: $empresaNome',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        if (tecnicoNome != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              'Técnico: $tecnicoNome',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildIdentificationSection(Rat rat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Identificação'),
        pw.SizedBox(height: 8),
        _infoRow('RAT', ratDisplayNumber(rat.numero)),
        _infoRow('Cliente', rat.clienteNome),
        _infoRow(
          'Responsável',
          rat.responsavelRecebimento ?? ratNotInformedLabel,
        ),
        if (rat.responsavelDocumento != null)
          _infoRow('Documento do responsável', rat.responsavelDocumento!),
        _infoRow('Data da visita', _formatDate(rat.dataVisita)),
        _infoRow(
          'Horário',
          '${rat.horarioInicioAtendimento ?? '--:--'} até '
              '${rat.horarioTerminoAtendimento ?? '--:--'}',
        ),
        _infoRow('Status', ratStatusLabel(rat.status)),
      ],
    );
  }

  pw.Widget _buildDescriptionSection(Rat rat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Descrição do atendimento'),
        pw.SizedBox(height: 8),
        pw.Text(rat.descricao, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  pw.Widget _buildEquipamentoSection(Rat rat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Equipamento'),
        pw.SizedBox(height: 8),
        _infoRow('Movimentação', _movimentoLabel(rat.equipamentoMovimentoTipo)),
        _infoRow('Descrição', rat.equipamentoDescricao ?? ratNotInformedLabel),
        if (rat.equipamentoObservacao != null &&
            rat.equipamentoObservacao!.isNotEmpty)
          _infoRow('Observação', rat.equipamentoObservacao!),
      ],
    );
  }

  pw.Widget _buildAssinaturaSection(Uint8List? assinaturaBytes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Assinatura'),
        pw.SizedBox(height: 8),
        if (assinaturaBytes == null)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Assinatura não capturada.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          )
        else
          pw.Container(
            height: 140,
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Align(
              alignment: pw.Alignment.topLeft,
              child: pw.Image(
                pw.MemoryImage(assinaturaBytes),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado em: ${_formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'TechReport',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return ratNotInformedLabel;
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _movimentoLabel(EquipamentoMovimentoTipo? tipo) {
    if (tipo == null) {
      return ratNotInformedLabel;
    }

    return equipamentoMovimentoLabel(tipo);
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  Future<Uint8List?> _loadAssinaturaBytes(Assinatura? assinatura) async {
    if (assinatura == null) {
      return null;
    }

    try {
      return await _assinaturaRepository.readBytes(assinatura.id);
    } catch (_) {
      return null;
    }
  }

  Future<File> _saveTemporaryPdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _pdfFileName(String subject) {
    final sanitized = subject
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return '$sanitized.pdf';
  }
}
