enum AppMode { local, company }

class AppModePreference {
  const AppModePreference({required this.lastMode, required this.updatedAt});

  final AppMode lastMode;
  final DateTime updatedAt;

  bool get isLocal => lastMode == AppMode.local;

  bool get isCompany => lastMode == AppMode.company;

  AppModePreference copyWith({AppMode? lastMode, DateTime? updatedAt}) {
    return AppModePreference(
      lastMode: lastMode ?? this.lastMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppModePreference &&
        other.lastMode == lastMode &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(lastMode, updatedAt);
}
