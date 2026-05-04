import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/usecases/select_app_mode.dart';

enum AppModeChoiceStatus { idle, saving, saved, failure }

class AppModeChoiceViewModel extends ChangeNotifier {
  AppModeChoiceViewModel({required SelectAppMode selectAppMode})
    : _selectAppMode = selectAppMode;

  final SelectAppMode _selectAppMode;

  AppModeChoiceStatus status = AppModeChoiceStatus.idle;
  String? errorMessage;

  bool get isSaving => status == AppModeChoiceStatus.saving;

  Future<bool> chooseLocal() {
    return _choose(AppMode.local);
  }

  Future<bool> chooseCompany() {
    return _choose(AppMode.company);
  }

  Future<bool> _choose(AppMode mode) async {
    status = AppModeChoiceStatus.saving;
    errorMessage = null;
    notifyListeners();

    try {
      await _selectAppMode(mode);

      status = AppModeChoiceStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      status = AppModeChoiceStatus.failure;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
