import '../../domain/entities/rat.dart';

class RatRemoteDto {
  const RatRemoteDto({
    required this.id,
    required this.empresaId,
    required this.tecnicoId,
    required this.criadoPorUserId,
    required this.numero,
    required this.clienteNome,
    this.responsavelRecebimento,
    this.responsavelDocumento,
    this.dataVisita,
    this.horarioInicioAtendimento,
    this.horarioTerminoAtendimento,
    required this.descricao,
    this.equipamentoMovimentoTipo,
    this.equipamentoDescricao,
    this.equipamentoObservacao,
    required this.status,
    required this.deletado,
    required this.criadoEmDispositivo,
  });

  final String id;
  final String empresaId;
  final String tecnicoId;
  final String criadoPorUserId;
  final String numero;
  final String clienteNome;
  final String? responsavelRecebimento;
  final String? responsavelDocumento;
  final DateTime? dataVisita;
  final String? horarioInicioAtendimento;
  final String? horarioTerminoAtendimento;
  final String descricao;
  final EquipamentoMovimentoTipo? equipamentoMovimentoTipo;
  final String? equipamentoDescricao;
  final String? equipamentoObservacao;
  final String status;
  final bool deletado;
  final DateTime criadoEmDispositivo;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'tecnico_id': tecnicoId,
      'criado_por_user_id': criadoPorUserId,
      'numero': numero,
      'cliente_nome': clienteNome,
      'responsavel_recebimento': responsavelRecebimento,
      'responsavel_documento': responsavelDocumento,
      'data_visita': _dateOnly(dataVisita),
      'horario_inicio_atendimento': horarioInicioAtendimento,
      'horario_termino_atendimento': horarioTerminoAtendimento,
      'descricao': descricao,
      'equipamento_movimento_tipo': _movimentoToRemote(
        equipamentoMovimentoTipo,
      ),
      'equipamento_descricao': equipamentoDescricao,
      'equipamento_observacao': equipamentoObservacao,
      'status': status,
      'deletado': deletado,
      'criado_em_dispositivo': criadoEmDispositivo.toIso8601String(),
    };
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) {
      return null;
    }

    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String? _movimentoToRemote(EquipamentoMovimentoTipo? tipo) {
    switch (tipo) {
      case null:
        return null;
      case EquipamentoMovimentoTipo.nenhum:
        return 'nenhum';
      case EquipamentoMovimentoTipo.retiradaParaReparo:
        return 'retirada_para_reparo';
      case EquipamentoMovimentoTipo.entregaPosReparo:
        return 'entrega_pos_reparo';
      case EquipamentoMovimentoTipo.entregaPosCompra:
        return 'entrega_pos_compra';
    }
  }
}
