import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/usecases/change_company_password.dart';

class CompanyAccountViewModel extends ChangeNotifier {
  CompanyAccountViewModel({required ChangeCompanyPassword changePassword})
    : _changePassword = changePassword;

  final ChangeCompanyPassword _changePassword;

  bool isChangingPassword = false;
  String? errorMessage;
  String? successMessage;

  Future<void> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    isChangingPassword = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    final result = await _changePassword(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    isChangingPassword = false;
    if (result.success) {
      successMessage = 'Senha atualizada.';
    } else {
      errorMessage = result.errorMessage ?? 'Nao foi possivel trocar a senha.';
    }
    notifyListeners();
  }
}
