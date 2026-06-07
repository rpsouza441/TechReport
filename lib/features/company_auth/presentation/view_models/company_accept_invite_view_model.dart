import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_in_company_with_invite.dart';

class CompanyAcceptInviteViewModel extends ChangeNotifier {
  CompanyAcceptInviteViewModel({
    required SignInCompanyWithInvite signInCompanyWithInvite,
    required AuthRepository authRepository,
    String? codigo,
  })  : _signInCompanyWithInvite = signInCompanyWithInvite,
        _authRepository = authRepository,
        _codigo = codigo;

  final SignInCompanyWithInvite _signInCompanyWithInvite;
  final AuthRepository _authRepository;

  bool isSubmitting = false;
  bool isResendingConfirmation = false;
  String? errorMessage;
  String? resendSuccessMessage;
  SessaoRemota? session;
  bool pendingEmailConfirmation = false;
  String? _codigo;

  String? get codigo => _codigo;

  void preFillCodigo(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      _codigo = value.trim().toUpperCase();
    }
  }

  Future<bool> submit({
    required String email,
    required String password,
    required String codigoConvite,
    required bool createAccount,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    session = null;
    pendingEmailConfirmation = false;
    notifyListeners();

    final result = await _signInCompanyWithInvite(
      email: email,
      password: password,
      codigoConvite: codigoConvite,
      createAccount: createAccount,
    );

    isSubmitting = false;

    if (result.success) {
      session = result.session;
      notifyListeners();
      return true;
    }

    if (result.pendingEmailConfirmation) {
      pendingEmailConfirmation = true;
      errorMessage = null;
      notifyListeners();
      return false;
    }

    errorMessage = result.errorMessage;
    notifyListeners();
    return false;
  }

  Future<void> resendConfirmationEmail({required String email}) async {
    isResendingConfirmation = true;
    resendSuccessMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resendConfirmationEmail(email: email);
      resendSuccessMessage = 'E-mail de confirmacao reenviado.';
    } catch (e) {
      errorMessage = e.toString().replaceFirst('RemoteAuthException: ', '');
    } finally {
      isResendingConfirmation = false;
      notifyListeners();
    }
  }
}
