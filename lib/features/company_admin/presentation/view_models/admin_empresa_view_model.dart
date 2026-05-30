import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_tecnicos.dart';

class AdminEmpresaViewModel extends ChangeNotifier {
  AdminEmpresaViewModel({
    required this.empresaId,
    required ListAdminTecnicos listTecnicos,
  }) : _listTecnicos = listTecnicos;

  final String empresaId;
  final ListAdminTecnicos _listTecnicos;

  bool isLoading = false;
  String? errorMessage;
  List<AdminTecnicoResumo> tecnicos = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      tecnicos = await _listTecnicos(empresaId: empresaId);
    } catch (_) {
      errorMessage = 'Não foi possível carregar a equipe.';
    }

    isLoading = false;
    notifyListeners();
  }
}
