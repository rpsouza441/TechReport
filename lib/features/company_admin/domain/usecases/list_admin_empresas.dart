import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class ListAdminEmpresas {
  const ListAdminEmpresas(this._repository);

  final CompanyAdminRepository _repository;

  Future<List<AdminEmpresaResumo>> call() {
    return _repository.listEmpresas();
  }
}
