import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';
import 'package:techreport/features/company_auth/domain/usecases/change_company_password.dart';
import 'package:techreport/features/company_auth/domain/usecases/update_own_display_name.dart';

class CompanyAccountViewModel extends ChangeNotifier {
  CompanyAccountViewModel({
    required ChangeCompanyPassword changePassword,
    required UpdateOwnDisplayName updateOwnDisplayName,
    required RemoteSessionRepository remoteSessionRepository,
    required ValueNotifier<SessaoRemota?> sessionNotifier,
  }) : _changePassword = changePassword,
       _updateOwnDisplayName = updateOwnDisplayName,
       _remoteSessionRepository = remoteSessionRepository,
       _sessionNotifier = sessionNotifier;

  final ChangeCompanyPassword _changePassword;
  final UpdateOwnDisplayName _updateOwnDisplayName;
  final RemoteSessionRepository _remoteSessionRepository;
  final ValueNotifier<SessaoRemota?> _sessionNotifier;

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
      await _persistUpdatedName(result.updatedName ?? name);
    } else {
      errorMessage =
          result.errorMessage ?? 'Não foi possível atualizar o nome.';
    }
    notifyListeners();
    return result.success;
  }

  Future<void> _persistUpdatedName(String updatedName) async {
    final current = _sessionNotifier.value;
    if (current == null) return;

    final updated = current.copyWith(nome: updatedName);
    await _remoteSessionRepository.updateSession(updated);
    _sessionNotifier.value = updated;
  }
}
