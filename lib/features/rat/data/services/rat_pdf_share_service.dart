import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';

class RatPdfShareService {
  RatPdfShareService({
    required LocalSignatureAssetStore localSignatureAssetStore,
  }) : _localSignatureAssetStore = localSignatureAssetStore;

  final LocalSignatureAssetStore _localSignatureAssetStore;

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
            _sectionTitle('Dados do atendimento'),
            pw.SizedBox(height: 8),
            pw.Text(shareData.body!),
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

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  Future<Uint8List?> _loadAssinaturaBytes(Assinatura? assinatura) async {
    if (assinatura == null || assinatura.storageMode != StorageMode.localFile) {
      return null;
    }

    return _localSignatureAssetStore.read(assinatura.assetRef);
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
