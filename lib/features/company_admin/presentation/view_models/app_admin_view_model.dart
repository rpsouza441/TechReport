import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_empresas.dart';

class AppAdminViewModel extends ChangeNotifier {
  AppAdminViewModel({required ListAdminEmpresas listEmpresas})
    : _listEmpresas = listEmpresas;

  final ListAdminEmpresas _listEmpresas;

  bool isLoading = false;
  String? errorMessage;
  List<AdminEmpresaResumo> empresas = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      empresas = await _listEmpresas();
    } catch (_) {
      errorMessage = 'Nao foi possivel carregar empresas.';
    }

    isLoading = false;
    notifyListeners();
  }
}
