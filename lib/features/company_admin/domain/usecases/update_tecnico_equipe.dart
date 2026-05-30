import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class UpdateTecnicoEquipe {
  const UpdateTecnicoEquipe(this._repository);

  final CompanyAdminRepository _repository;

  Future<void> call({
    required String tecnicoId,
    bool? ativo,
    bool? mustChangePassword,
  }) {
    return _repository.updateTecnicoEquipe(
      tecnicoId: tecnicoId,
      ativo: ativo,
      mustChangePassword: mustChangePassword,
    );
  }
}
