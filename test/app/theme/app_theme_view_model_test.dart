import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/app_theme_mode.dart';
import 'package:techreport/app/theme/app_theme_repository.dart';
import 'package:techreport/app/theme/app_theme_variant.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';

void main() {
  group('AppThemeViewModel — paleta de cores', () {
    test('lightTheme e darkTheme usam a variante carregada', () async {
      final repository = _FakeAppThemeRepository(
        AppThemeVariant.volt,
        AppThemeModePreference.system,
      );
      final viewModel = AppThemeViewModel(repository: repository);

      await viewModel.load();

      expect(viewModel.currentVariant, AppThemeVariant.volt);
      expect(viewModel.lightTheme.brightness, Brightness.light);
      expect(viewModel.darkTheme.brightness, Brightness.dark);
      expect(viewModel.lightTheme.colorScheme.primary, const Color(0xFF4C6700));
      expect(viewModel.darkTheme.colorScheme.primary, const Color(0xFFBCF723));
    });

    test('setVariant atualiza lightTheme e darkTheme da mesma familia',
        () async {
      final repository = _FakeAppThemeRepository(
        AppThemeVariant.cobalt,
        AppThemeModePreference.system,
      );
      final viewModel = AppThemeViewModel(repository: repository);

      await viewModel.load();
      await viewModel.setVariant(AppThemeVariant.burgundy);

      expect(repository.savedVariant, AppThemeVariant.burgundy);
      expect(viewModel.lightTheme.brightness, Brightness.light);
      expect(viewModel.darkTheme.brightness, Brightness.dark);
      expect(
        viewModel.lightTheme.colorScheme.primary,
        const Color(0xFF5C0D1C),
      );
      expect(viewModel.darkTheme.colorScheme.primary, const Color(0xFFFFB2B7));
    });
  });

  group('AppThemeViewModel — modo de aparência', () {
    test('valor padrao do modo deve ser system', () async {
      final repository = _FakeAppThemeRepository(
        AppThemeVariant.cobalt,
        AppThemeModePreference.system,
      );
      final viewModel = AppThemeViewModel(repository: repository);

      await viewModel.load();

      expect(viewModel.currentMode, AppThemeModePreference.system);
      expect(viewModel.themeMode, ThemeMode.system);
    });

    test('setMode(light) atualiza themeMode para ThemeMode.light', () async {
      final repository = _FakeAppThemeRepository(
        AppThemeVariant.cobalt,
        AppThemeModePreference.system,
      );
      final viewModel = AppThemeViewModel(repository: repository);

      await viewModel.load();
      await viewModel.setMode(AppThemeModePreference.light);

      expect(repository.savedMode, AppThemeModePreference.light);
      expect(viewModel.currentMode, AppThemeModePreference.light);
      expect(viewModel.themeMode, ThemeMode.light);
    });

    test('setMode(dark) atualiza themeMode para ThemeMode.dark', () async {
      final repository = _FakeAppThemeRepository(
        AppThemeVariant.cobalt,
        AppThemeModePreference.system,
      );
      final viewModel = AppThemeViewModel(repository: repository);

      await viewModel.load();
      await viewModel.setMode(AppThemeModePreference.dark);

      expect(repository.savedMode, AppThemeModePreference.dark);
      expect(viewModel.currentMode, AppThemeModePreference.dark);
      expect(viewModel.themeMode, ThemeMode.dark);
    });

    test('setMode(system) atualiza themeMode para ThemeMode.system', () async {
      final repository = _FakeAppThemeRepository(
        AppThemeVariant.cobalt,
        AppThemeModePreference.dark,
      );
      final viewModel = AppThemeViewModel(repository: repository);

      await viewModel.load();
      expect(viewModel.themeMode, ThemeMode.dark);

      await viewModel.setMode(AppThemeModePreference.system);

      expect(repository.savedMode, AppThemeModePreference.system);
      expect(viewModel.currentMode, AppThemeModePreference.system);
      expect(viewModel.themeMode, ThemeMode.system);
    });

    test('trocar modo nao altera a paleta', () async {
      final repository = _FakeAppThemeRepository(
        AppThemeVariant.volt,
        AppThemeModePreference.system,
      );
      final viewModel = AppThemeViewModel(repository: repository);

      await viewModel.load();
      final originalPrimary = viewModel.lightTheme.colorScheme.primary;

      await viewModel.setMode(AppThemeModePreference.dark);

      expect(viewModel.currentVariant, AppThemeVariant.volt);
      expect(viewModel.lightTheme.colorScheme.primary, originalPrimary);
    });

    test('trocar paleta nao altera o modo', () async {
      final repository = _FakeAppThemeRepository(
        AppThemeVariant.volt,
        AppThemeModePreference.light,
      );
      final viewModel = AppThemeViewModel(repository: repository);

      await viewModel.load();
      expect(viewModel.currentMode, AppThemeModePreference.light);
      expect(viewModel.themeMode, ThemeMode.light);

      await viewModel.setVariant(AppThemeVariant.burgundy);

      expect(viewModel.currentMode, AppThemeModePreference.light);
      expect(viewModel.themeMode, ThemeMode.light);
    });
  });
}

class _FakeAppThemeRepository extends AppThemeRepository {
  _FakeAppThemeRepository(this.variant, this.mode);

  AppThemeVariant variant;
  AppThemeModePreference mode;
  AppThemeVariant? savedVariant;
  AppThemeModePreference? savedMode;

  @override
  Future<AppThemeVariant> loadVariant() async => variant;

  @override
  Future<void> saveVariant(AppThemeVariant variant) async {
    this.variant = variant;
    savedVariant = variant;
  }

  @override
  Future<AppThemeModePreference> loadMode() async => mode;

  @override
  Future<void> saveMode(AppThemeModePreference mode) async {
    this.mode = mode;
    savedMode = mode;
  }
}
