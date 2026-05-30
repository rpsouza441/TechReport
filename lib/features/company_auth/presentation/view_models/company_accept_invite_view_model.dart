import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_in_company_with_invite.dart';

class CompanyAcceptInviteViewModel extends ChangeNotifier {
  CompanyAcceptInviteViewModel({
    required SignInCompanyWithInvite signInCompanyWithInvite,
  }) : _signInCompanyWithInvite = signInCompanyWithInvite;

  final SignInCompanyWithInvite _signInCompanyWithInvite;

  bool isSubmitting = false;
  String? errorMessage;
  SessaoRemota? session;

  Future<bool> submit({
    required String email,
    required String password,
    required String codigoConvite,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    session = null;
    notifyListeners();

    final result = await _signInCompanyWithInvite(
      email: email,
      password: password,
      codigoConvite: codigoConvite,
    );

    isSubmitting = false;

    if (result.success) {
      session = result.session;
      notifyListeners();
      return true;
    }

    errorMessage = result.errorMessage;
    notifyListeners();
    return false;
  }
}
