import 'metric_slate_colors.dart';

/// User-facing theme variants backed by MetricSlate families.
enum AppThemeVariant {
  cobalt('TechReport Azul', 'Paleta azul profissional'),
  volt('TechReport Verde', 'Paleta verde eletrica'),
  burgundy('TechReport Vinho', 'Paleta vinho elegante');

  const AppThemeVariant(this.displayName, this.description);

  final String displayName;
  final String description;

  MetricSlateThemeFamily get family {
    return switch (this) {
      AppThemeVariant.cobalt => MetricSlateThemeFamily.cobalt,
      AppThemeVariant.volt => MetricSlateThemeFamily.volt,
      AppThemeVariant.burgundy => MetricSlateThemeFamily.burgundy,
    };
  }

  static AppThemeVariant fromName(String? name) {
    if (name == null) return AppThemeVariant.cobalt;
    for (final v in AppThemeVariant.values) {
      if (v.name == name) return v;
    }
    return AppThemeVariant.cobalt;
  }
}
