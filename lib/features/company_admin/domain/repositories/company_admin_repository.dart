import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';

abstract class CompanyAdminRepository {
  Future<List<AdminEmpresaResumo>> listEmpresas();

  Future<List<AdminTecnicoResumo>> listTecnicos({required String empresaId});
}
