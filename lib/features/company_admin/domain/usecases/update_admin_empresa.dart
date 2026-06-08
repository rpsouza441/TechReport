import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class UpdateAdminEmpresa {
  const UpdateAdminEmpresa(this._repository);

  final CompanyAdminRepository _repository;

  Future<void> call({required String empresaId, String? nome, bool? ativo}) {
    if (nome == null && ativo == null) {
      throw ArgumentError('Update requer nome ou ativo.');
    }
    return _repository.updateEmpresa(
      empresaId: empresaId,
      nome: nome,
      ativo: ativo,
    );
  }
}
