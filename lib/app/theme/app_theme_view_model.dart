import 'package:flutter/material.dart';
import 'app_theme_mode.dart';
import 'app_theme_repository.dart';
import 'app_theme_variant.dart';
import 'metric_slate_theme.dart';

class AppThemeViewModel extends ChangeNotifier {
  AppThemeViewModel({required AppThemeRepository repository})
    : _repository = repository;

  final AppThemeRepository _repository;

  AppThemeVariant _currentVariant = AppThemeVariant.cobalt;
  AppThemeModePreference _currentMode = AppThemeModePreference.system;
  bool _loaded = false;

  AppThemeVariant get currentVariant => _currentVariant;
  AppThemeModePreference get currentMode => _currentMode;
  bool get loaded => _loaded;

  /// Retorna o [ThemeMode] correspondente à preferência atual.
  ThemeMode get themeMode => _currentMode.themeMode;

  ThemeData get currentTheme => lightTheme;

  ThemeData get lightTheme =>
      MetricSlateTheme.light(family: _currentVariant.family);

  ThemeData get darkTheme =>
      MetricSlateTheme.dark(family: _currentVariant.family);

  Future<void> load() async {
    _currentVariant = await _repository.loadVariant();
    _currentMode = await _repository.loadMode();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    if (_currentVariant == variant) return;
    _currentVariant = variant;
    notifyListeners();
    await _repository.saveVariant(variant);
  }

  Future<void> setMode(AppThemeModePreference mode) async {
    if (_currentMode == mode) return;
    _currentMode = mode;
    notifyListeners();
    await _repository.saveMode(mode);
  }
}
