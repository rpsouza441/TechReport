import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';

class ChangeCompanyPassword {
  ChangeCompanyPassword({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  Future<ChangeCompanyPasswordResult> call({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.trim().length < 6) {
      return const ChangeCompanyPasswordResult.failure(
        'A senha deve ter pelo menos 6 caracteres.',
      );
    }

    if (newPassword != confirmPassword) {
      return const ChangeCompanyPasswordResult.failure(
        'As senhas nao conferem.',
      );
    }

    try {
      await _authRepository.changePassword(newPassword);
      return const ChangeCompanyPasswordResult.success();
    } catch (e) {
      return ChangeCompanyPasswordResult.failure(e.toString());
    }
  }
}

class ChangeCompanyPasswordResult {
  const ChangeCompanyPasswordResult._({
    required this.success,
    this.errorMessage,
  });

  const ChangeCompanyPasswordResult.success() : this._(success: true);

  const ChangeCompanyPasswordResult.failure(String errorMessage)
    : this._(success: false, errorMessage: errorMessage);

  final bool success;
  final String? errorMessage;
}
