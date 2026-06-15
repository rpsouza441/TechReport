# Technology Stack

**Analysis Date:** 2025-06-15

## Languages

**Primary:**
- Dart 3.11.4 - Core language for Flutter development

**Secondary:**
- SQL (via Drift ORM) - Database migrations and queries

## Runtime

**Environment:**
- Flutter (stable channel, revision db50e20168db8fee486b9abf32fc912de3bc5b6a)
- Target platforms: Android, iOS, Linux, macOS, Windows, Web

**Package Manager:**
- Pub (Dart package manager)
- Lockfile: `pubspec.lock` (present)

## Frameworks

**Core:**
- Flutter SDK - Cross-platform mobile/desktop app framework
- Material Design 3 - UI component library

**State Management:**
- ChangeNotifier + ValueNotifier - ViewModels use ChangeNotifier pattern
- AppScope manual DI - No external DI framework; AppScope aggregates all dependencies

**Build/Dev:**
- build_runner ^2.10.1 - Code generation
- drift_dev ^2.32.1 - Drift ORM code generation

## Key Dependencies

**Database & Storage:**
- drift ^2.32.1 - Type-safe SQLite ORM
- sqlite3 ^3.3.1 - SQLite3 native bindings
- sqlite3mc (sqlite3-multiple-ciphers) - Database encryption via user-defined hooks
- flutter_secure_storage ^10.0.0 - Secure storage for tokens/keys
- path_provider ^2.1.5 - Platform-specific file paths

**Backend/Remote:**
- supabase_flutter ^2.0.0 - Supabase client for auth and database
- http ^1.2.0 - HTTP client for API calls

**PDF & Documents:**
- pdf ^3.12.0 - PDF generation
- share_plus ^12.0.2 - Native share functionality
- file_picker ^11.0.2 - File selection dialogs

**Utilities:**
- uuid ^4.5.3 - UUID generation
- archive ^4.0.4 - Archive handling (zip)
- crypto ^3.0.6 - Cryptographic utilities
- package_info_plus ^9.0.1 - App version info

**UI:**
- cupertino_icons ^1.0.8 - iOS-style icons

**App Links:**
- app_links ^6.0.0 - Deep linking support

## Architecture Pattern

**Clean Architecture with Feature-First Organization:**
```
lib/
  app/                    # App-level bootstrapping, DI, navigation
    bootstrap/
    di/                   # AppScope dependency injection
    navigation/           # App routing
    theme/                # Theme configuration
  features/               # Feature modules (each with domain/data/presentation)
    [feature_name]/
      domain/             # Entities, repositories (interfaces), use cases
      data/               # Repository implementations, services
      presentation/       # Screens, view models, widgets
  shared/                 # Cross-cutting concerns
    infra/
      database/           # Drift database setup, migrations
      debug/              # Logging utilities
      security/           # Key stores, PIN management
    presentation/
      widgets/            # Shared UI components
```

**Key Architectural Decisions:**

1. **No External DI Framework** - AppScope manually wires all dependencies
2. **Drift ORM for Local Database** - Type-safe SQL with code generation
3. **Repository Pattern** - Domain layer defines interfaces; data layer implements
4. **Use Cases** - Business logic isolated in use case classes
5. **ChangeNotifier ViewModels** - UI state managed via ChangeNotifier

## Configuration

**Environment:**
- No `.env` file pattern detected; configuration stored in local/secure storage
- Remote endpoints configured via `LocalRemoteEndpointRepository`

**Linting:**
- flutter_lints ^6.0.0 with recommended Flutter rules
- Custom exclusion: `rat/**` directory excluded from analysis

**Build:**
- `analysis_options.yaml` - Analyzer configuration
- `pubspec.yaml` - Dependencies and project metadata
- `hooks/user_defines/sqlite3/source: sqlite3mc` - Custom SQLite build

---

*Stack analysis: 2025-06-15*