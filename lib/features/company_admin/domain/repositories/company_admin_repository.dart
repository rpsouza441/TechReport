import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';

abstract class CompanyAdminRepository {
  Future<List<AdminEmpresaResumo>> listEmpresas();

  Future<AdminEmpresaResumo> getEmpresa(String empresaId);

  Future<void> createEmpresa({required String nome});

  Future<void> updateEmpresa({
    required String empresaId,
    String? nome,
    bool? ativo,
  });

  Future<List<AdminTecnicoResumo>> listTecnicos({required String empresaId});

  Future<List<AdminConviteResumo>> listConvites({required String empresaId});

  Future<CreateTecnicoConviteResult> createConvite({
    required String email,
    required String nome,
    required AdminTecnicoPapel papel,
  });

  Future<CreateTecnicoConviteResult> createEmpresaConvite({
    required String empresaId,
    required String email,
    required String nome,
    required AdminTecnicoPapel papel,
  });

  Future<void> cancelConvite({required String conviteId});

  Future<void> acceptConvite({required String codigoConvite});

  Future<void> updateTecnicoEquipe({
    required String tecnicoId,
    bool? ativo,
    bool? mustChangePassword,
  });
}
