import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class UpdateAdminEmpresa {
  const UpdateAdminEmpresa(this._repository);

  final CompanyAdminRepository _repository;

  Future<void> call({
    required String empresaId,
    required bool ativo,
  }) {
    return _repository.updateEmpresa(empresaId: empresaId, ativo: ativo);
  }
}
