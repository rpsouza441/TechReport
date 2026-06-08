import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class GetAdminEmpresa {
  const GetAdminEmpresa(this._repository);

  final CompanyAdminRepository _repository;

  Future<AdminEmpresaResumo> call(String empresaId) {
    return _repository.getEmpresa(empresaId);
  }
}
