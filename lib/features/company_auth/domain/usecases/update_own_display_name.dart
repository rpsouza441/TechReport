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
      return UpdateOwnDisplayNameResult(success: true, updatedName: trimmed);
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('session') ||
          msg.contains('unauthorized') ||
          msg.contains('expir')) {
        return const UpdateOwnDisplayNameResult(
          success: false,
          errorMessage: 'Sessão expirada. Entre novamente.',
        );
      }
      return const UpdateOwnDisplayNameResult(
        success: false,
        errorMessage: 'Não foi possível salvar. Tente novamente.',
      );
    }
  }
}

class UpdateOwnDisplayNameResult {
  const UpdateOwnDisplayNameResult({
    required this.success,
    this.errorMessage,
    this.updatedName,
  });

  final bool success;
  final String? errorMessage;
  final String? updatedName;
}
