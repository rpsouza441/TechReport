import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class CreateAdminEmpresa {
  const CreateAdminEmpresa(this._repository);

  final CompanyAdminRepository _repository;

  Future<void> call({required String nome}) {
    return _repository.createEmpresa(nome: nome);
  }
}
