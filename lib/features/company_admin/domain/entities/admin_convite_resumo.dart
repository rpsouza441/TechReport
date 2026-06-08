import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';

enum AdminConviteStatus { pending, accepted, expired, cancelled }

class AdminConviteResumo {
  const AdminConviteResumo({
    required this.id,
    required this.empresaId,
    required this.email,
    required this.nome,
    required this.papel,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String empresaId;
  final String email;
  final String nome;
  final AdminTecnicoPapel papel;
  final AdminConviteStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;

  bool get isPending => status == AdminConviteStatus.pending;

  bool get isExpired => isPending && DateTime.now().isAfter(expiresAt);
}

class CreateTecnicoConviteResult {
  const CreateTecnicoConviteResult({
    required this.conviteId,
    required this.codigoConvite,
    required this.expiresAt,
  });

  final String conviteId;
  final String codigoConvite;
  final DateTime expiresAt;
}
