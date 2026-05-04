import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_in_company.dart';

enum CompanySignInStatus { idle, submitting, success, failure }

class CompanySignInViewModel extends ChangeNotifier {
  CompanySignInViewModel({
    required SignInCompany signInCompany,
  }) : _signInCompany = signInCompany;

  final SignInCompany _signInCompany;

  CompanySignInStatus status = CompanySignInStatus.idle;
  SessaoRemota? session;
  String? errorMessage;

  bool get isSubmitting => status == CompanySignInStatus.submitting;
  bool get isSuccess => status == CompanySignInStatus.success;
  bool get hasError => errorMessage != null;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      status = CompanySignInStatus.failure;
      errorMessage = 'Informe email e senha.';
      notifyListeners();
      return false;
    }

    status = CompanySignInStatus.submitting;
    errorMessage = null;
    notifyListeners();

    final result = await _signInCompany(
      email: normalizedEmail,
      password: normalizedPassword,
    );

    if (!result.success || result.session == null) {
      status = CompanySignInStatus.failure;
      errorMessage = result.errorMessage ?? 'Nao foi possivel entrar.';
      notifyListeners();
      return false;
    }

    session = result.session;
    status = CompanySignInStatus.success;
    notifyListeners();
    return true;
  }
}