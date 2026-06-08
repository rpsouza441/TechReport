import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class ListEmpresaAdmins {
  const ListEmpresaAdmins(this._repository);

  final CompanyAdminRepository _repository;

  Future<List<AdminTecnicoResumo>> call({required String empresaId}) async {
    final tecnicos = await _repository.listTecnicos(empresaId: empresaId);
    return tecnicos
        .where((t) => t.papel == AdminTecnicoPapel.adminEmpresa)
        .toList();
  }
}
