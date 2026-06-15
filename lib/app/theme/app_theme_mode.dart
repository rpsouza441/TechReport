import 'package:flutter/material.dart';

/// Preferência de modo de tema do usuário.
///
/// Controla apenas o brilho (claro/escuro/sistema), separado da paleta de cores.
enum AppThemeModePreference {
  system('Seguir sistema', ThemeMode.system),
  light('Claro', ThemeMode.light),
  dark('Escuro', ThemeMode.dark);

  const AppThemeModePreference(this.label, this.themeMode);

  /// Label em português para exibir na UI.
  final String label;

  /// Representação em [ThemeMode] do Flutter.
  final ThemeMode themeMode;

  /// Converte string salva em storage para enum.
  static AppThemeModePreference fromName(String? name) {
    if (name == null) return system;
    return AppThemeModePreference.values.firstWhere(
      (e) => e.name == name,
      orElse: () => system,
    );
  }
}