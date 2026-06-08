import 'package:flutter/material.dart';
import 'app_theme_repository.dart';
import 'app_theme_variant.dart';
import 'metric_slate_theme.dart';

class AppThemeViewModel extends ChangeNotifier {
  AppThemeViewModel({required AppThemeRepository repository})
      : _repository = repository;

  final AppThemeRepository _repository;

  AppThemeVariant _currentVariant = AppThemeVariant.cobalt;
  bool _loaded = false;

  AppThemeVariant get currentVariant => _currentVariant;
  bool get loaded => _loaded;

  ThemeData get currentTheme => MetricSlateTheme.light(
        family: _currentVariant.family,
      );

  Future<void> load() async {
    _currentVariant = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    if (_currentVariant == variant) return;
    _currentVariant = variant;
    notifyListeners();
    await _repository.save(variant);
  }
}
