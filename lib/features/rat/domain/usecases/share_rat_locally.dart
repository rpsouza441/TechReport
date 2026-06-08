import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
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

  Future<ShareRatLocallyResult> call({
    required String ratId,
    required RatListScope scope,
  }) async {
    final rat = await _ratRepository.getByIdScoped(id: ratId, scope: scope);

    if (rat == null) {
      return const ShareRatLocallyResult.failure('RAT não encontrado.');
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
    final horario = _formatHorario(
      rat.horarioInicioAtendimento,
      rat.horarioTerminoAtendimento,
    );

    final equipamentoObservacao = rat.equipamentoObservacao;
    final equipamentoSection = equipamentoObservacao != null &&
            equipamentoObservacao.trim().isNotEmpty
        ? '''
Movimentacao: ${equipamentoMovimentoLabel(rat.equipamentoMovimentoTipo ?? EquipamentoMovimentoTipo.nenhum)}
Descricao: ${rat.equipamentoDescricao ?? ratNotInformedLabel}
Observacao: $equipamentoObservacao'''
        : '''
Movimentacao: ${equipamentoMovimentoLabel(rat.equipamentoMovimentoTipo ?? EquipamentoMovimentoTipo.nenhum)}
Descricao: ${rat.equipamentoDescricao ?? ratNotInformedLabel}''';

    return '''
=== TECHREPORT - RELATORIO DE ATENDIMENTO ===

--- Identificacao ---
RAT: ${rat.numero}
Cliente: ${rat.clienteNome}
Responsavel: ${rat.responsavelRecebimento ?? ratNotInformedLabel}
Documento: ${rat.responsavelDocumento ?? ratNotInformedLabel}
Data da visita: ${_formatDate(rat.dataVisita)}
Horario: $horario
Status: ${ratStatusLabel(rat.status)}

--- Descricao do atendimento ---
${rat.descricao}

--- Equipamento ---
$equipamentoSection

--- Assinatura ---
Assinatura: ${assinatura == null ? 'nao capturada' : 'capturada'}

Gerado em: ${_formatDateTime(DateTime.now())}
''';
  }

  String _formatHorario(String? inicio, String? termino) {
    if (inicio == null && termino == null) {
      return ratNotInformedLabel;
    }
    if (inicio == null) {
      return 'ate $termino';
    }
    if (termino == null) {
      return '$inicio ate $inicio';
    }
    return '$inicio ate $termino';
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
