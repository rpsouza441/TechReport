# Codebase Structure

**Analysis Date:** 2025-01-20

## Directory Layout

```
C:/ws/TechReport/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── app/                           # App-level infrastructure
│   │   ├── bootstrap/                 # Bootstrap flow
│   │   ├── di/                        # Dependency injection
│   │   ├── navigation/                # App shell, routing
│   │   └── theme/                     # Theme definitions
│   ├── features/                     # Feature modules
│   │   ├── company_admin/
│   │   ├── company_auth/
│   │   ├── local_auth/
│   │   ├── rat/
│   │   ├── signature/
│   │   └── sync/
│   └── shared/                        # Cross-cutting utilities
│       ├── infra/                     # Infrastructure
│       └── presentation/              # Shared widgets
├── test/                              # Test files
└── .planning/codebase/                # This documentation
```

## Directory Purposes

### `lib/app/`

**Purpose:** Application-level concerns that cross-cut features

**Contains:**
- `bootstrap/` - App initialization and splash screen
- `di/` - `AppScope` dependency injection container
- `navigation/` - `TechReportApp`, `AppShell`, `CompanyShell`
- `theme/` - `MetricSlateTheme`, colors, spacing, component themes

### `lib/features/`

**Purpose:** Feature modules following Clean Architecture

**Structure per feature:**
```
features/{feature_name}/
├── data/                    # Implementations
│   ├── repositories/        # Concrete repository implementations
│   ├── services/            # External integrations
│   ├── dtos/                # Data transfer objects
│   └── exceptions/          # Custom exceptions
├── domain/                  # Business logic
│   ├── entities/           # Domain models
│   ├── repositories/       # Abstract repository interfaces
│   ├── usecases/            # Business operations
│   ├── permissions/        # Authorization rules
│   ├── utils/              # Domain helpers
│   └── services/           # Domain services
└── presentation/           # UI layer
    ├── screens/            # Full-page widgets
    ├── view_models/        # ChangeNotifier state
    └── widgets/            # Reusable UI components
```

### `lib/shared/`

**Purpose:** Cross-cutting infrastructure and reusable components

**Contains:**
- `infra/database/` - Drift database definition, encryption
- `infra/security/` - PIN store, key store
- `infra/debug/` - Logging utilities
- `presentation/widgets/` - Shared UI components

## Key File Locations

### Entry Points

| File | Purpose |
|------|---------|
| `lib/main.dart` | App bootstrap with error handling |
| `lib/app/bootstrap/bootstrap.dart` | Splash screen, AppScope creation |
| `lib/app/navigation/tech_report_app.dart` | Root app widget, deep links |

### Dependency Injection

| File | Purpose |
|------|---------|
| `lib/app/di/app_scope.dart` | All app dependencies, 400+ lines |

### Navigation/Shells

| File | Purpose |
|------|---------|
| `lib/app/navigation/tech_report_app.dart` | TechReportApp, AppShell |
| `lib/app/navigation/company_shell.dart` | Company mode with bottom nav |
| `lib/app/navigation/app_bootstrap_view_model.dart` | Bootstrap state machine |

### Database

| File | Purpose |
|------|---------|
| `lib/shared/infra/database/tech_report_local_database.dart` | Drift schema definition |
| `lib/shared/infra/database/open_encrypted_database.dart` | Encrypted DB initialization |

### Feature: RAT (Relatorio de Atendimento)

| File | Purpose |
|------|---------|
| `lib/features/rat/domain/entities/rat.dart` | RAT domain model |
| `lib/features/rat/domain/repositories/rat_repository.dart` | Abstract repository |
| `lib/features/rat/data/repositories/drift_rat_repository.dart` | Local SQLite implementation |
| `lib/features/rat/data/repositories/supabase_remote_rat_repository.dart` | Remote sync implementation |
| `lib/features/rat/presentation/view_models/rat_form_view_model.dart` | Form state (880 lines) |
| `lib/features/rat/presentation/view_models/rat_list_view_model.dart` | List state |
| `lib/features/rat/presentation/screens/rat_list_screen.dart` | RAT list UI |
| `lib/features/rat/presentation/screens/rat_form_screen.dart` | RAT form UI |

### Feature: Local Auth

| File | Purpose |
|------|---------|
| `lib/features/local_auth/domain/entities/sessao_local.dart` | Local session model |
| `lib/features/local_auth/domain/usecases/bootstrap_local_session.dart` | Session init |
| `lib/features/local_auth/presentation/view_models/app_session_view_model.dart` | Session state |
| `lib/features/local_auth/presentation/screens/local_home_screen.dart` | Local mode home |
| `lib/features/local_auth/presentation/screens/local_unlock_screen.dart` | PIN unlock |

### Feature: Company Auth

| File | Purpose |
|------|---------|
| `lib/features/company_auth/domain/entities/sessao_remota.dart` | Remote session model |
| `lib/features/company_auth/data/services/supabase_client_factory.dart` | Supabase client factory |
| `lib/features/company_auth/presentation/screens/company_sign_in_screen.dart` | Login screen |

### Feature: Sync

| File | Purpose |
|------|---------|
| `lib/features/sync/domain/usecases/process_sync_queue.dart` | Queue processor |
| `lib/features/sync/domain/usecases/download_remote_rats.dart` | Remote fetch |
| `lib/features/sync/data/repositories/drift_sync_queue_repository.dart` | Queue persistence |

## Naming Conventions

### Files

- **Dart source:** `snake_case.dart`
- **Generated (Drift):** `*.g.dart`
- **Screen widgets:** `*_screen.dart`
- **ViewModels:** `*_view_model.dart`
- **Repositories:** `*_repository.dart`
- **Use cases:** `*_usecase.dart` or `{verb}_{noun}.dart`

### Directories

- **Feature modules:** `snake_case` (e.g., `company_auth`, `local_auth`)
- **Layer folders:** `domain`, `data`, `presentation`
- **Sub-folders:** `entities`, `repositories`, `usecases`, `screens`, `view_models`, `widgets`

### Classes

- **Entities:** PascalCase noun (`Rat`, `SessaoLocal`)
- **ViewModels:** PascalCase ending in `ViewModel` (`RatFormViewModel`)
- **Repositories:** PascalCase ending in `Repository` (`RatRepository`)
- **Use cases:** PascalCase verb phrase (`ShareRatLocally`, `ProcessSyncQueue`)
- **Screens:** PascalCase ending in `Screen` (`RatListScreen`)

### Variables/Properties

- **State fields:** `camelCase` (`clienteNome`, `dataVisita`)
- **Dependencies:** `camelCase` prefixed with `_` (`_ratRepository`)
- **Getters:** `camelCase` (`isSubmitting`, `hasSignature`)

## Where to Add New Code

### New Feature Module

1. Create directory structure:
   ```
   lib/features/{feature_name}/
   ├── data/
   │   ├── repositories/
   │   └── services/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── usecases/
   └── presentation/
       ├── screens/
       ├── view_models/
       └── widgets/
   ```

2. Register in `AppScope` (`lib/app/di/app_scope.dart`):
   - Add repository field
   - Instantiate in `create()` method
   - Add use case instantiation

3. Create ViewModel extending `ChangeNotifier`

4. Create screen(s) using ViewModel

### New Entity

1. Add to `lib/features/{feature}/domain/entities/`
2. Include `copyWith`, `==`, `hashCode`
3. Add repository interface method in domain
4. Implement in data layer

### New Use Case

1. Add to `lib/features/{feature}/domain/usecases/`
2. Inject required repositories via constructor
3. Register in `AppScope` if needed by ViewModel

### New Widget

1. **Feature-specific:** `lib/features/{feature}/presentation/widgets/`
2. **Shared:** `lib/shared/presentation/widgets/`

### New Screen

1. Add to `lib/features/{feature}/presentation/screens/`
2. Receive dependencies via constructor (from AppScope)
3. Use `ListenableBuilder` for ViewModel-driven state

## Special Directories

### `lib/shared/infra/database/`

**Purpose:** Drift database definition

**Generated:** `tech_report_local_database.g.dart` (auto-generated by Drift)

**Committed:** Yes, both schema and generated file

### `lib/app/theme/`

**Purpose:** Custom theme "MetricSlate"

**Files:**
- `metric_slate_theme.dart` - ThemeData builder
- `metric_slate_colors.dart` - Color palette
- `metric_slate_spacing.dart` - Spacing constants
- `metric_slate_radii.dart` - Border radius
- `metric_slate_component_themes.dart` - Component themes

### `lib/app/navigation/`

**Purpose:** App-level navigation orchestration

**Key insight:** No routing package used. Navigation via:
- State machine in `AppShell` (enum-based screen switching)
- `Navigator.push()` for modal/detail screens
- `MaterialPageRoute` builder pattern

### `lib/features/rat/domain/services/`

**Purpose:** Domain services for RAT feature

**Contains:**
- `rat_sync_coordinator.dart` - Coordinates sync after save/delete

## Test Organization

**Location:** `test/` (mirrors `lib/` structure)

**Examples:**
- `test/app/theme/app_theme_view_model_test.dart`
- `test/features/rat/presentation/view_models/rat_form_view_model_test.dart`

**Pattern:** Unit tests for ViewModels and use cases

---

*Structure analysis: 2025-01-20*
