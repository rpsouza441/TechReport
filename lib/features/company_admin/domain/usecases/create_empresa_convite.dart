import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class CreateEmpresaConvite {
  const CreateEmpresaConvite(this._repository);

  final CompanyAdminRepository _repository;

  Future<CreateTecnicoConviteResult> call({
    required String empresaId,
    required String email,
    required String nome,
    required AdminTecnicoPapel papel,
  }) {
    return _repository.createEmpresaConvite(
      empresaId: empresaId,
      email: email,
      nome: nome,
      papel: papel,
    );
  }
}
