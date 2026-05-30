import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class ListAdminConvites {
  const ListAdminConvites(this._repository);

  final CompanyAdminRepository _repository;

  Future<List<AdminConviteResumo>> call({required String empresaId}) {
    return _repository.listConvites(empresaId: empresaId);
  }
}
