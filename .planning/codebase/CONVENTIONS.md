# Coding Conventions

**Analysis Date:** 2025-01-20

## Naming Patterns

**Files:**
- Dart source files use `snake_case.dart` (e.g., `rat_form_view_model.dart`, `share_rat_locally.dart`)
- Test files use `snake_case_test.dart` (e.g., `rat_form_view_model_test.dart`)
- Feature files mirror the lib structure: `feature_name/` contains `domain/`, `data/`, `presentation/`

**Classes:**
- Classes use `PascalCase` (e.g., `RatFormViewModel`, `ShareRatLocally`, `TechReportCard`)
- ViewModels typically end with `ViewModel` suffix
- Repositories use `Repository` suffix
- Use cases use `UseCase` suffix (e.g., `SignInCompany`, `DownloadRemoteRats`)
- Entities use singular nouns (e.g., `Rat`, `Assinatura`, `SessaoRemota`)

**Variables and Functions:**
- Variables use `camelCase` (e.g., `clienteNome`, `hasSignature`, `isSubmitting`)
- Private fields use leading underscore `_camelCase` (e.g., `_ratRepository`, `_isSubmitting`)
- Boolean getters use `is` or `has` prefix (e.g., `isSaved`, `hasSignature`, `isReadOnly`)
- Private helper functions use leading underscore `_snake_case` (e.g., `_normalizeHour`, `_isHourInRange`)
- Setter methods use `set` prefix (e.g., `setClienteNome`, `setDataVisita`)

**Enums:**
- Enums use `PascalCase` with `CamelCase` values (e.g., `RatStatus.draft`, `RatSyncStatus.pendingSync`)

## Code Style

**Formatting:**
- Uses `flutter_lints` package (included via `package:flutter_lints/flutter.yaml`)
- 2-space indentation (Flutter default)
- Single quotes for strings
- Trailing commas for collections and parameters

**Linting:**
- Analysis options in `analysis_options.yaml` at project root
- `rat/` subdirectory excluded from analysis
- No custom rules enabled beyond defaults

## Import Organization

**Order:**
1. Dart SDK imports (`dart:async`, `dart:typed_data`)
2. Flutter/Dart package imports (`package:flutter/...`)
3. Relative imports for same-feature code (`../../../signature/...`)
4. Relative imports for shared code (`../../../../shared/...`)

**Pattern:**
```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';

import '../../../signature/data/services/local_signature_asset_store.dart';
import '../../../signature/domain/entities/assinatura.dart';
```

## Architecture Pattern

**Overall:** Clean Architecture with feature-based organization

**Layers per feature:**
```
feature/
  data/           # Repository implementations, DTOs, services
    repositories/
    services/
    dtos/
  domain/         # Entities, repository interfaces, use cases
    entities/
    repositories/
    usecases/
    permissions/  # Authorization rules
    services/      # Domain services
    utils/         # Utility functions
  presentation/   # UI components
    screens/
    view_models/
    widgets/
```

**Shared layer:**
```
lib/shared/
  infra/          # Infrastructure (database, security)
  presentation/   # Reusable widgets
```

## ViewModel Pattern

ViewModels extend `ChangeNotifier` and follow this structure:

```dart
class RatFormViewModel extends ChangeNotifier {
  RatFormViewModel({
    required AssinaturaRepository assinaturaRepository,
    required RatRepository ratRepository,
    Rat? initialRat,
  }) : _ratRepository = ratRepository,
       _assinaturaRepository = assinaturaRepository,
       _initialRat = initialRat;

  // Private fields
  final RatRepository _ratRepository;
  final Rat? _initialRat;

  // Public state (mutable for form fields)
  String clienteNome = '';
  DateTime? dataVisita;

  // Private mutable state
  bool _isSubmitting = false;
  String? _errorMessage;

  // Getters
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // Setter methods (call notifyListeners())
  void setClienteNome(String value) {
    clienteNome = value;
    notifyListeners();
  }

  // Async methods handle loading state
  Future<bool> save() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ratRepository.save(rat);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSubmitting = false;
      _errorMessage = 'Error message';
      notifyListeners();
      return false;
    }
  }
}
```

## Entity Pattern

Entities are immutable classes with:
- `const` constructor
- `copyWith()` method using sentinel pattern for nullable fields
- Manual `==` and `hashCode` implementations
- Computed getters for state checks (e.g., `isDraft`, `isDeleted`)

```dart
class Rat {
  const Rat({
    required this.id,
    required this.authorId,
    this.empresaId,
    // ...
  });

  Rat copyWith({
    String? id,
    Object? empresaId = _sentinel,  // sentinel for nullable
  }) {
    return Rat(
      id: id ?? this.id,
      empresaId: empresaId == _sentinel
          ? this.empresaId
          : empresaId as String?,
    );
  }
}

const Object _sentinel = Object();
```

## Error Handling

**Pattern:** Try-catch with catch-all and error state

```dart
try {
  await _ratRepository.save(rat);
  _isSubmitting = false;
  notifyListeners();
  return true;
} catch (_) {
  _isSubmitting = false;
  _errorMessage = 'Mensagem amigavel';
  notifyListeners();
  return false;
}
```

**Async fire-and-forget:** Use `unawaited()` from `dart:async` for non-critical background tasks:

```dart
unawaited(() async {
  try {
    await downloadRemoteRats.call(...);
  } catch (_) {
    // Retry handled by list screen
  }
}());
```

## Async/Await Patterns

**Standard async methods:**
- Return `Future<T>` for operations that complete
- Use `try-catch` for error handling
- Call `notifyListeners()` before and after async operations

**Validation methods:**
- Return `String?` (null = valid, non-null = error message)
- Do not use exceptions for validation errors

```dart
String? validate() {
  if (clienteNome.trim().isEmpty) {
    return 'Informe o cliente.';
  }
  // ...
  return null;
}
```

## Widget Conventions

**Stateless widgets:**
```dart
class TechReportCard extends StatelessWidget {
  const TechReportCard({
    super.key,
    required this.child,
    this.padding,
    this.tone = TechReportCardTone.normal,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final TechReportCardTone tone;

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**Widget helper functions** may be placed in the same file (e.g., `ratSyncStatusLabel`, `ratSyncStatusIcon` in `rat_list_item_card.dart`)

## Repository Pattern

Repositories are abstract interfaces defining data operations:

```dart
abstract class RatRepository {
  Future<Rat?> getById(String id);
  Future<List<Rat>> listLocalPage({required int limit, required int offset});
  Future<void> save(Rat rat);
  Future<void> update(Rat rat);
}
```

Implementations live in `data/repositories/` and are injected via constructor.

## Comments

**Documentation comments:** Use triple-slash `///` for public API documentation

**Inline comments:** Use `//` for implementation notes

**Portuguese comments:** Comments are in Portuguese (this is a Brazilian codebase)

---

*Convention analysis: 2025-01-20*
