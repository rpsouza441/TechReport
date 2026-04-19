import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

class ShareRatLocally {
  ShareRatLocally({
    required RatRepository ratRepository,
    required AssinaturaRepository assinaturaRepository,
  }) : _ratRepository = ratRepository,
       _assinaturaRepository = assinaturaRepository;

  final RatRepository _ratRepository;
  final AssinaturaRepository _assinaturaRepository;

  Future<ShareRatLocallyResult> call(String ratId) async {
    final rat = await _ratRepository.getById(ratId);
    if (rat == null) {
      return const ShareRatLocallyResult.failure('RAT nao encontrado.');
    }

    final assinaturas = await _assinaturaRepository.listByRatId(ratId);
    assinaturas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final assinatura = assinaturas.isEmpty ? null : assinaturas.first;

    final subject = 'RAT ${rat.numero} - ${rat.clienteNome}';
    final body = _buildBody(rat: rat, assinatura: assinatura);

    return ShareRatLocallyResult.success(
      rat: rat,
      assinatura: assinatura,
      subject: subject,
      body: body,
    );
  }

  String _buildBody({required Rat rat, required Assinatura? assinatura}) {
    return '''
RAT: ${rat.numero}
Cliente: ${rat.clienteNome}
Status: ${rat.status.name}
Atualizado em: ${_formatDateTime(rat.updatedAt)}

Descri\u00e7\u00e3o:
${rat.descricao}

Assinatura: ${assinatura == null ? 'nao capturada' : 'capturada'}
''';
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class ShareRatLocallyResult {
  const ShareRatLocallyResult._({
    required this.success,
    this.rat,
    this.assinatura,
    this.subject,
    this.body,
    this.errorMessage,
  });

  const ShareRatLocallyResult.success({
    required Rat rat,
    required Assinatura? assinatura,
    required String subject,
    required String body,
  }) : this._(
         success: true,
         rat: rat,
         assinatura: assinatura,
         subject: subject,
         body: body,
       );

  const ShareRatLocallyResult.failure(String errorMessage)
    : this._(success: false, errorMessage: errorMessage);

  final bool success;
  final Rat? rat;
  final Assinatura? assinatura;
  final String? subject;
  final String? body;
  final String? errorMessage;
}
