import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class CancelTecnicoConvite {
  const CancelTecnicoConvite(this._repository);

  final CompanyAdminRepository _repository;

  Future<void> call({required String conviteId}) {
    return _repository.cancelConvite(conviteId: conviteId);
  }
}
