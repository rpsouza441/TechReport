import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';

class SelectAppMode {
  SelectAppMode(this._appModeRepository);

  final AppModeRepository _appModeRepository;

  Future<void> call(AppMode mode) async {
    await _appModeRepository.savePreference(
      AppModePreference(lastMode: mode, updatedAt: DateTime.now()),
    );
  }

  Future<void> clear() async {
    await _appModeRepository.clearPreference();
  }
}
