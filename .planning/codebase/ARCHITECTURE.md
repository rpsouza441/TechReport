# Architecture

**Analysis Date:** 2025-01-20

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      TechReportApp                          │
│                  `lib/app/navigation/tech_report_app.dart`   │
├─────────────────────────────────────────────────────────────┤
│                     AppShell (Stateful)                     │
│     Switches between modes based on AppBootstrapViewModel   │
├──────────────────┬──────────────────┬───────────────────────┤
│  Local Mode      │  Company Mode    │  Bootstrap Flow       │
│  LocalHomeScreen │  CompanyShell    │  AppModeChoiceScreen  │
│  LocalUnlock     │  (with NavBar)   │  RemoteServerConfig    │
│  LocalOnboarding │                  │  CompanySignIn        │
└─────────────────┴──────────────────┴───────────────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    AppScope (DI Container)                  │
│                    `lib/app/di/app_scope.dart`              │
│  - Repositories instantiated with DB/remote client          │
│  - Use cases created with injected dependencies             │
│  - ViewModels receive all required dependencies             │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│              Shared Infrastructure Layer                    │
│  `lib/shared/infra/`                                         │
│  - Database: Drift encrypted SQLite                         │
│  - Security: PIN store, key store                            │
│  - Debug: Logging utilities                                  │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| TechReportApp | Root app widget, deep link handling | `lib/app/navigation/tech_report_app.dart` |
| AppShell | Mode-based screen switching | `lib/app/navigation/tech_report_app.dart` |
| AppScope | DI container, all dependencies | `lib/app/di/app_scope.dart` |
| AppBootstrapViewModel | App state machine (local/company) | `lib/app/navigation/app_bootstrap_view_model.dart` |
| CompanyShell | Company mode navigation, sync | `lib/app/navigation/company_shell.dart` |
| AppSessionViewModel | Local session lifecycle | `lib/features/local_auth/presentation/view_models/app_session_view_model.dart` |

## Pattern Overview

**Overall:** Clean Architecture with MVVM presentation layer

**Key Characteristics:**
- **Domain-driven separation**: Each feature has `domain/`, `data/`, `presentation/` layers
- **Repository pattern**: Abstract repositories in domain, implementations in data
- **Use case injection**: Business logic injected via constructor into ViewModels
- **State machine navigation**: AppShell switches screens based on bootstrap status enum
- **Dual-mode operation**: App supports "Local" (offline-only) and "Company" (cloud-synced) modes

## Layers

### Domain Layer (`domain/`)

**Purpose:** Business logic and entities, free of Flutter/framework dependencies

**Location:** `lib/features/{feature}/domain/`

**Contains:**
- `entities/` - Immutable data classes with `copyWith`, `==`, `hashCode`
- `repositories/` - Abstract repository interfaces
- `usecases/` - Single-responsibility business operations
- `permissions/` - Authorization rules
- `utils/` - Domain helpers (formatters, etc.)

**Example entity:**
```dart
// lib/features/rat/domain/entities/rat.dart
class Rat {
  const Rat({required this.id, required this.numero, ...});
  final String id;
  // ... fields
  Rat copyWith({...});
}
```

**Example use case:**
```dart
// lib/features/rat/domain/usecases/share_rat_locally.dart
class ShareRatLocally {
  ShareRatLocally({required RatRepository ratRepository, ...});
  Future<ShareRatLocallyResult> call({required String ratId, ...});
}
```

### Data Layer (`data/`)

**Purpose:** Implementation of domain contracts, external integrations

**Location:** `lib/features/{feature}/data/`

**Contains:**
- `repositories/` - Concrete implementations (e.g., `DriftRatRepository`)
- `services/` - External integrations (PDF generation, backup, etc.)
- `dtos/` - Data transfer objects for API serialization
- `exceptions/` - Custom exception types

**Key implementations:**
- `DriftRatRepository` - SQLite persistence via Drift ORM
- `SupabaseRemoteRatRepository` - Remote sync via Supabase
- `LocalDataImportParser` - Backup/restore parsing

### Presentation Layer (`presentation/`)

**Purpose:** UI and state management

**Location:** `lib/features/{feature}/presentation/`

**Contains:**
- `screens/` - Full-page widgets
- `view_models/` - `ChangeNotifier` classes managing state
- `widgets/` - Reusable UI components

**ViewModel pattern:**
```dart
// lib/features/rat/presentation/view_models/rat_form_view_model.dart
class RatFormViewModel extends ChangeNotifier {
  RatFormViewModel({required RatRepository ratRepository, ...});
  // State fields as properties
  // Methods that mutate state and call notifyListeners()
}
```

## Data Flow

### Primary Request Path (Local RAT Creation)

1. **Entry:** `LocalHomeScreen` displays RAT list (`lib/features/local_auth/presentation/screens/local_home_screen.dart`)
2. **User action:** Tap FAB to create new RAT
3. **Navigation:** Push `RatFormScreen` with dependencies from AppScope
4. **State:** `RatFormViewModel` manages form state, validates input
5. **Save:** Calls `ratRepository.save(rat)` which persists to Drift DB
6. **Result:** UI updates via `notifyListeners()`

### Company Mode RAT Sync Flow

1. **User saves RAT:** `RatFormViewModel.save()` called
2. **Persistence:** RAT saved to local Drift DB
3. **Enqueue sync:** `syncCoordinator.syncAfterSave()` enqueues to `SyncQueueRepository`
4. **Background sync:** `ProcessSyncQueue` processes queue, uploads to Supabase
5. **Download:** `DownloadRemoteRats` fetches latest from server
6. **UI refresh:** List ViewModel reloads data

### App Bootstrap Flow

1. **main.dart:** Calls `bootstrap()` with `runZonedGuarded`
2. **Bootstrap widget:** Shows splash, initializes `AppScope`
3. **AppScope.create():** Opens encrypted DB, creates all repositories/use cases
4. **TechReportApp:** Receives scope, creates `AppBootstrapViewModel`
5. **bootstrap():** Checks local session, company session status
6. **AppShell:** Renders appropriate screen based on `AppBootstrapStatus` enum

## Key Abstractions

### Repository Pattern

**Purpose:** Decouple domain from persistence/remote details

**Examples:**
- `RatRepository` (abstract) - `DriftRatRepository` (local), `SupabaseRemoteRatRepository` (remote)
- `AssinaturaRepository` - handles signature storage

**Pattern:**
```dart
// Abstract in domain
abstract class RatRepository {
  Future<Rat?> getById(String id);
  Future<void> save(Rat rat);
}

// Implementation in data
class DriftRatRepository implements RatRepository {
  DriftRatRepository(this._database);
  final database.TechReportLocalDatabase _database;
}
```

### Use Case Pattern

**Purpose:** Encapsulate single business operations

**Location:** `lib/features/{feature}/domain/usecases/`

**Pattern:**
```dart
class ShareRatLocally {
  ShareRatLocally({required RatRepository ratRepository, ...});
  Future<ShareRatLocallyResult> call({required String ratId, ...});
}
```

### Value Objects

**Purpose:** Immutable domain types with validation

**Examples:**
- `RatStatus` enum: `draft`, `finalizado`, `enviado`, `arquivado`
- `RatSyncStatus` enum: `localOnly`, `pendingSync`, `synced`, `syncError`
- `RatListScope` - typed scope for list queries

## Entry Points

### main.dart

**Location:** `lib/main.dart`

**Triggers:** App launch via `bootstrap()`

**Responsibilities:**
- Wraps app in `runZonedGuarded` for error handling
- Delegates to `_TechReportBootstrapApp`

### bootstrap.dart

**Location:** `lib/app/bootstrap/bootstrap.dart`

**Responsibilities:**
- Creates `AppScope` asynchronously
- Shows splash screen during initialization
- Handles bootstrap failures with retry/reset options

### TechReportApp

**Location:** `lib/app/navigation/tech_report_app.dart`

**Triggers:** After AppScope creation

**Responsibilities:**
- Deep link handling via `app_links` package
- Theme management via `AppThemeViewModel`
- Routes to `AppShell` with appropriate screen

## Architectural Constraints

- **No service locator/get_it:** Dependencies explicitly passed via constructor
- **No routing package:** Screen navigation via `Navigator.push()` and state machine in AppShell
- **Synchronous scope creation:** `AppScope.create()` is async but all dependencies created upfront
- **ChangeNotifier for state:** ViewModels extend `ChangeNotifier`, screens use `ListenableBuilder`
- **No BLoC/Riverpod:** State management via ChangeNotifier only

## Anti-Patterns

### Heavy ViewModel

**What happens:** `RatFormViewModel` (880 lines) contains form state, validation, PDF generation, sync coordination

**Why it's wrong:** Violates single responsibility; difficult to test in isolation

**Do this instead:** Extract `PdfPreviewData` preparation, sync coordination into separate use cases

### Constructor Injection for Optional Dependencies

**What happens:** `RatFormViewModel` accepts nullable `syncCoordinator`, `downloadRemoteRats` as optional

**Why it's wrong:** Makes it unclear which dependencies are required vs optional; runtime null checks scattered

**Do this instead:** Create specialized constructors or factory methods for different modes (local vs company)

## Error Handling

**Strategy:** Centralized via `AppErrorLog` and `runZonedGuarded`

**Patterns:**
- Bootstrap errors caught and displayed with retry option
- Sync errors logged but don't crash app (queued for retry)
- Form validation errors shown inline via `_errorMessage` field

## Cross-Cutting Concerns

**Logging:** `LocalDatabaseDebugLog` for structured debug logging

**Validation:** ViewModels implement `validate()` methods returning error strings

**Authentication:** Two modes: local (PIN/biometric) and company (Supabase auth)

**Theme:** `AppThemeViewModel` manages light/dark/system theme preference

---

*Architecture analysis: 2025-01-20*
