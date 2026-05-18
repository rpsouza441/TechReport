import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class ListAdminTecnicos {
  const ListAdminTecnicos(this._repository);

  final CompanyAdminRepository _repository;

  Future<List<AdminTecnicoResumo>> call({required String empresaId}) {
    return _repository.listTecnicos(empresaId: empresaId);
  }
}
