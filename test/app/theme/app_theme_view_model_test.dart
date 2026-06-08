import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/app_theme_repository.dart';
import 'package:techreport/app/theme/app_theme_variant.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';

void main() {
  test('lightTheme e darkTheme usam a variante carregada', () async {
    final repository = _FakeAppThemeRepository(AppThemeVariant.volt);
    final viewModel = AppThemeViewModel(repository: repository);

    await viewModel.load();

    expect(viewModel.currentVariant, AppThemeVariant.volt);
    expect(viewModel.lightTheme.brightness, Brightness.light);
    expect(viewModel.darkTheme.brightness, Brightness.dark);
    expect(viewModel.lightTheme.colorScheme.primary, const Color(0xFF4C6700));
    expect(viewModel.darkTheme.colorScheme.primary, const Color(0xFFBCF723));
  });

  test('setVariant atualiza lightTheme e darkTheme da mesma familia', () async {
    final repository = _FakeAppThemeRepository(AppThemeVariant.cobalt);
    final viewModel = AppThemeViewModel(repository: repository);

    await viewModel.load();
    await viewModel.setVariant(AppThemeVariant.burgundy);

    expect(repository.savedVariant, AppThemeVariant.burgundy);
    expect(viewModel.lightTheme.brightness, Brightness.light);
    expect(viewModel.darkTheme.brightness, Brightness.dark);
    expect(viewModel.lightTheme.colorScheme.primary, const Color(0xFF5C0D1C));
    expect(viewModel.darkTheme.colorScheme.primary, const Color(0xFFFFB2B7));
  });
}

class _FakeAppThemeRepository extends AppThemeRepository {
  _FakeAppThemeRepository(this.variant);

  AppThemeVariant variant;
  AppThemeVariant? savedVariant;

  @override
  Future<AppThemeVariant> load() async => variant;

  @override
  Future<void> save(AppThemeVariant variant) async {
    this.variant = variant;
    savedVariant = variant;
  }
}
