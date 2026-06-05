import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';

class RatPdfShareService {
  RatPdfShareService({
    required AssinaturaRepository assinaturaRepository,
  }) : _assinaturaRepository = assinaturaRepository;

  final AssinaturaRepository _assinaturaRepository;

  Future<void> share(ShareRatLocallyResult shareData) async {
    final pdfBytes = await _buildPdf(shareData);
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

  Future<Uint8List> _buildPdf(ShareRatLocallyResult shareData) async {
    final assinaturaBytes = await _loadAssinaturaBytes(shareData.assinatura);
    final assinaturaImage = assinaturaBytes == null
        ? null
        : pw.MemoryImage(assinaturaBytes);
    final rat = shareData.rat;
    if (rat == null) {
      throw StateError('RAT ausente para gerar PDF.');
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              'Tech Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              shareData.subject!,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 24),
            _sectionTitle('Identificação'),
            pw.SizedBox(height: 8),
            _infoRow('RAT', rat.numero),
            _infoRow('Cliente', rat.clienteNome),
            _infoRow(
              'Responsável',
              rat.responsavelRecebimento ?? ratNotInformedLabel,
            ),
            _infoRow(
              'Documento do responsável',
              rat.responsavelDocumento ?? ratNotInformedLabel,
            ),
            _infoRow('Data da visita', _formatDate(rat.dataVisita)),
            _infoRow(
              'Horário',
              '${rat.horarioInicioAtendimento ?? '--:--'} até '
                  '${rat.horarioTerminoAtendimento ?? '--:--'}',
            ),
            _infoRow('Status', ratStatusLabel(rat.status)),

            pw.SizedBox(height: 18),
            _sectionTitle('Descrição do atendimento'),
            pw.SizedBox(height: 8),
            pw.Text(rat.descricao),

            pw.SizedBox(height: 18),
            _sectionTitle('Equipamento'),
            pw.SizedBox(height: 8),
            _infoRow(
              'Movimentação',
              _movimentoLabel(rat.equipamentoMovimentoTipo),
            ),
            _infoRow('Descrição', rat.equipamentoDescricao ?? ratNotInformedLabel),
            _infoRow(
              'Observação',
              rat.equipamentoObservacao ?? ratNotInformedLabel,
            ),

            pw.SizedBox(height: 24),
            _sectionTitle('Assinatura'),
            pw.SizedBox(height: 8),
            if (assinaturaImage == null)
              pw.Text('Nenhuma assinatura capturada.')
            else
              pw.Container(
                height: 160,
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
                child: pw.Image(assinaturaImage, fit: pw.BoxFit.contain),
              ),
          ];
        },
      ),
    );

    return pdf.save();
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

    return _assinaturaRepository.readBytes(assinatura.id);
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
