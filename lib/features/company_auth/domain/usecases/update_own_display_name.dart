import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';

class UpdateOwnDisplayName {
  UpdateOwnDisplayName({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  Future<UpdateOwnDisplayNameResult> call(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const UpdateOwnDisplayNameResult(
        success: false,
        errorMessage: 'Informe o nome.',
      );
    }
    if (trimmed.length > 120) {
      return const UpdateOwnDisplayNameResult(
        success: false,
        errorMessage: 'O nome deve ter no máximo 120 caracteres.',
      );
    }

    try {
      await _authRepository.updateOwnDisplayName(trimmed);
      return const UpdateOwnDisplayNameResult(success: true);
    } on Exception catch (e) {
      return UpdateOwnDisplayNameResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

class UpdateOwnDisplayNameResult {
  const UpdateOwnDisplayNameResult({required this.success, this.errorMessage});

  final bool success;
  final String? errorMessage;
}
