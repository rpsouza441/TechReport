import 'dart:typed_data';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_view_model.dart';

/// Prepares data for PDF generation and handles PDF sharing.
///
/// Single responsibility: PDF data preparation.
/// Extracted from RatFormViewModel to reduce coupling and improve testability.
class RatPdfGenerator {
  RatPdfGenerator({
    required RatPdfShareService ratPdfShareService,
    required ShareRatLocally shareRatLocally,
    required String ratId,
    SupabaseClientFactory? supabaseClientFactory,
  })  : _ratPdfShareService = ratPdfShareService,
        _shareRatLocally = shareRatLocally,
        _supabaseClientFactory = supabaseClientFactory,
        _ratId = ratId;

  final RatPdfShareService _ratPdfShareService;
  final ShareRatLocally _shareRatLocally;
  final SupabaseClientFactory? _supabaseClientFactory;
  final String _ratId;

  String? empresaNome;

  /// Resolves empresaNome from remote session if not already set.
  Future<String?> resolveEmpresaNome(String? empresaId) async {
    if (empresaNome != null) {
      return empresaNome;
    }

    if (empresaId == null || _supabaseClientFactory == null) {
      return null;
    }

    try {
      final client = await _supabaseClientFactory!.tryCreateAuthenticatedClient();
      if (client == null) {
        return null;
      }

      final row = await client
          .from('empresas')
          .select('nome')
          .eq('id', empresaId)
          .maybeSingle();
      empresaNome = row?['nome'] as String?;
      return empresaNome;
    } catch (e, st) {
      // Debug output in release will be no-op
      assert(false, "Error: $e$st");
      return null;
    }
  }

  /// Prepares PDF preview data.
  ///
  /// [persist] controls whether to save RAT before generating preview.
  Future<PdfPreviewData?> prepareForPreview({
    required Rat rat,
    Uint8List? signatureBytes,
    bool assinaturaPendente = false,
    String? tecnicoNome,
  }) async {
    final shareData = await _shareRatLocally(
      ratId: _ratId,
      scope: _inferScope(rat),
    );

    if (!shareData.success || shareData.rat == null) {
      return null;
    }

    return PdfPreviewData(
      rat: shareData.rat!,
      signatureBytes: assinaturaPendente ? null : signatureBytes,
      assinaturaPendente: assinaturaPendente,
      empresaNome: empresaNome,
      tecnicoNome: tecnicoNome,
    );
  }

  /// Shares the RAT PDF using the system share sheet.
  Future<bool> share({
    required Rat rat,
    required bool assinaturaPendente,
    String? tecnicoNome,
    required Future<ShareRatLocallyResult> Function() getShareData,
    required void Function(String) setError,
    required void Function() notifyListeners,
    required bool Function() startSharing,
  }) async {
    final started = startSharing();
    if (!started) {
      return false;
    }

    try {
      final shareData = await getShareData();
      if (!shareData.success) {
        setError(shareData.errorMessage ?? 'Erro ao preparar dados.');
        return false;
      }

      await _ratPdfShareService.share(
        shareData,
        empresaNome: empresaNome,
        tecnicoNome: tecnicoNome,
        assinaturaPendente: assinaturaPendente,
      );
      return true;
    } catch (e, st) {
      assert(false, "Error: $e$st");
      setError('Nao foi possivel compartilhar o PDF.');
      return false;
    }
  }

  /// Exports the RAT PDF to device storage.
  Future<bool> exportToDevice({
    required Rat rat,
    required bool assinaturaPendente,
    String? tecnicoNome,
    required Future<ShareRatLocallyResult> Function() getShareData,
    required void Function(String) setError,
    required void Function() notifyListeners,
    required bool Function() startSharing,
  }) async {
    final started = startSharing();
    if (!started) {
      return false;
    }

    try {
      final shareData = await getShareData();
      if (!shareData.success) {
        setError(shareData.errorMessage ?? 'Erro ao preparar dados.');
        return false;
      }

      final exported = await _ratPdfShareService.exportToDevice(
        shareData,
        empresaNome: empresaNome,
        tecnicoNome: tecnicoNome,
        assinaturaPendente: assinaturaPendente,
      );

      if (!exported) {
        return false;
      }
      return true;
    } catch (e, st) {
      assert(false, "Error: $e$st");
      setError('Nao foi possivel salvar o PDF.');
      return false;
    }
  }

  /// Infers the share scope from RAT data.
  RatListScope _inferScope(Rat rat) {
    if (rat.empresaId == null) {
      return const RatListScope.local();
    }

    final empresaId = rat.empresaId!;

    // For RATs with empresaId but no tecnicoId, use manager scope
    if (rat.tecnicoId == null) {
      return RatListScope.companyManager(empresaId: empresaId);
    }

    return RatListScope.companyTechnician(
      empresaId: empresaId,
      tecnicoId: rat.tecnicoId!,
    );
  }
}
