class RatRemoteDto {
  const RatRemoteDto({
    required this.id,
    required this.empresaId,
    required this.tecnicoId,
    required this.criadoPorUserId,
    required this.numero,
    required this.clienteNome,
    required this.descricao,
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
  final String descricao;
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
      'descricao': descricao,
      'status': status,
      'deletado': deletado,
      'criado_em_dispositivo': criadoEmDispositivo.toIso8601String(),
    };
  }
}
