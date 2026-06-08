import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/usecases/change_company_password.dart';
import 'package:techreport/features/company_auth/domain/usecases/update_own_display_name.dart';

class CompanyAccountViewModel extends ChangeNotifier {
  CompanyAccountViewModel({
    required ChangeCompanyPassword changePassword,
    required UpdateOwnDisplayName updateOwnDisplayName,
  }) : _changePassword = changePassword,
       _updateOwnDisplayName = updateOwnDisplayName;

  final ChangeCompanyPassword _changePassword;
  final UpdateOwnDisplayName _updateOwnDisplayName;

  bool isChangingPassword = false;
  bool isSavingName = false;
  String? errorMessage;
  String? successMessage;

  Future<void> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    isChangingPassword = true;
    errorMessage = null;
    successMessage = null;

    final result = await _changePassword(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    isChangingPassword = false;
    if (result.success) {
      successMessage = 'Senha atualizada.';
    } else {
      errorMessage = result.errorMessage ?? 'Não foi possível trocar a senha.';
    }
    notifyListeners();
  }

  Future<bool> updateDisplayName(String name) async {
    isSavingName = true;
    errorMessage = null;
    notifyListeners();

    final result = await _updateOwnDisplayName(name);

    isSavingName = false;
    if (result.success) {
      successMessage = 'Nome atualizado.';
    } else {
      errorMessage =
          result.errorMessage ?? 'Não foi possível atualizar o nome.';
    }
    notifyListeners();
    return result.success;
  }
}
