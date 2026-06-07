import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';

class ListEmpresaAdminConvites {
  const ListEmpresaAdminConvites(this._repository);

  final CompanyAdminRepository _repository;

  Future<List<AdminConviteResumo>> call({required String empresaId}) async {
    final convites =
        await _repository.listConvites(empresaId: empresaId);
    return convites
        .where((c) =>
            c.papel == AdminTecnicoPapel.adminEmpresa &&
            c.status == AdminConviteStatus.pending)
        .toList();
  }
}