import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class CreateTecnicoConvite {
  const CreateTecnicoConvite(this._repository);

  final CompanyAdminRepository _repository;

  Future<CreateTecnicoConviteResult> call({
    required String email,
    required String nome,
    required AdminTecnicoPapel papel,
  }) {
    return _repository.createConvite(email: email, nome: nome, papel: papel);
  }
}
