# Phase: Code Review Report

**Reviewed:** 2025-01-15T00:00:00Z
**Depth:** standard
**Files Reviewed:** 18
**Files Reviewed List:**
- lib/app/bootstrap/bootstrap.dart
- lib/app/navigation/tech_report_app.dart
- lib/app/theme/app_theme_repository.dart
- lib/app/theme/app_theme_view_model.dart
- lib/app/theme/app_theme_mode.dart
- lib/features/company_auth/presentation/screens/company_home_screen.dart
- lib/features/local_auth/presentation/screens/local_home_screen.dart
- lib/features/local_auth/presentation/screens/local_profile_screen.dart
- lib/features/local_auth/presentation/screens/local_settings_screen.dart
- lib/features/rat/presentation/screens/rat_list_screen.dart
- lib/features/rat/presentation/view_models/rat_form_view_model.dart
- lib/features/signature/presentation/screens/signature_capture_screen.dart
- lib/shared/infra/database/open_encrypted_database.dart
- lib/shared/infra/debug/local_database_debug_log.dart
- lib/features/rat/domain/services/rat_sync_coordinator.dart
- lib/features/local_auth/presentation/widgets/local_info_card.dart
- test/app/theme/app_theme_view_model_test.dart
- test/features/rat/presentation/view_models/rat_form_view_model_test.dart

findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: issues_found

## Summary

Reviewed all 18 modified/new files including main screens, view models, database infrastructure, and test files. Found 1 critical issue related to incomplete error handling that can cause state inconsistency, 3 warnings for code quality improvements, and 3 informational suggestions.

## Critical Issues

### CR-01: Incomplete error handling in reopenForCorrection leaves state inconsistent

**File:** `lib/features/rat/presentation/view_models/rat_form_view_model.dart:447`
**Issue:** The `reopenForCorrection` method modifies state fields (lines 438-445) before calling `save()`. If `save()` throws an unhandled exception (e.g., from `_syncCoordinator?.syncAfterSave()` at line 381-386), the state rollback code (lines 449-456) never executes, leaving the RAT in an inconsistent state.

```dart
// State is modified here
status = RatStatus.draft;
ultimoAlteradorUserId = remoteSession.usuarioId;
ultimaAlteracaoEm = now;
// ... more state changes ...

final saved = await save();  // If this throws, rollback below never runs
if (!saved) {
  // rollback code - only runs if save() returns false
  status = previousStatus;
  // ... restore all state ...
}
```

**Impact:** Data inconsistency in company mode RATs. If sync fails after state is modified, the RAT shows as "reopened" locally but the status/audit fields may not reflect this correctly on next load.

**Fix:**
```dart
try {
  final saved = await save();
  if (!saved) {
    _rollbackReopenState(/* pass previous values as parameters */);
    return false;
  }
} catch (error) {
  _rollbackReopenState(/* pass previous values as parameters */);
  _errorMessage = 'Erro ao reabrir RAT para correção.';
  notifyListeners();
  return false;
}
```

## Warnings

### WR-01: UpdateTecnicoLocal instantiated inside save method

**File:** `lib/features/local_auth/presentation/screens/local_profile_screen.dart:135`
**Issue:** `UpdateTecnicoLocal` is instantiated inside `_saveEditing()` rather than being injected via constructor or stored as a field. This creates a new instance on every save attempt.

```dart
Future<void> _saveEditing() async {
  // ...
  try {
    final update = UpdateTecnicoLocal(widget.tecnicoLocalRepository);  // New instance each time
    await update.call(
      nome: _nomeController.text,
      email: _emailController.text,
    );
    // ...
  }
}
```

**Impact:** Minor performance overhead from object allocation. Also makes testing harder since the use case cannot be mocked.

**Fix:** Move `UpdateTecnicoLocal` to constructor or create once in `initState()`.

### WR-02: shouldRepaint always returns true causing unnecessary repaints

**File:** `lib/features/signature/presentation/screens/signature_capture_screen.dart:213-215`
**Issue:** The `shouldRepaint` method always returns `true`, causing the signature painter to repaint on every frame even when strokes have not changed.

```dart
@override
bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
  return true;  // Always repaints, even when nothing changed
}
```

**Impact:** Performance degradation during signature capture, especially on lower-end devices. Battery impact from continuous repaints.

**Fix:**
```dart
@override
bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
  if (strokes.length != oldDelegate.strokes.length) return true;
  for (var i = 0; i < strokes.length; i++) {
    if (strokes[i].length != oldDelegate.strokes[i].length) return true;
  }
  return false;
}
```

### WR-03: Magic number for signature size limit

**File:** `lib/features/rat/presentation/view_models/rat_form_view_model.dart:534`
**Issue:** The maximum signature size (1 MB) is defined as a literal inline constant rather than a named constant.

```dart
const maxSignatureBytes = 1 * 1024 * 1024; // 1 MB
```

**Impact:** If the limit needs to change, this value must be found and updated in multiple places. Also, the comment in the test file ("2 MB de bytes伪造") uses Chinese characters mixed with Portuguese, which is inconsistent.

**Fix:** Define as a class constant:
```dart
static const maxSignatureBytes = 1 * 1024 * 1024; // 1 MB
```

## Info

### IN-01: Comment inconsistency in test file

**File:** `test/features/rat/presentation/view_models/rat_form_view_model_test.dart:627`
**Issue:** Comment uses Chinese characters ("bytes伪造" = "bytes forged/fake") mixed with Portuguese. This is inconsistent with the rest of the codebase which uses Portuguese.

```dart
// 2 MB de bytes伪造
final bigBytes = Uint8List(2 * 1024 * 1024);
```

**Fix:** Replace with Portuguese comment:
```dart
// 2 MB de bytes simulados
final bigBytes = Uint8List(2 * 1024 * 1024);
```

### IN-02: Signature ID generation uses microsecondsSinceEpoch

**File:** `lib/features/rat/presentation/view_models/rat_form_view_model.dart:568`
**Issue:** Signature IDs are generated using `microsecondsSinceEpoch` which, while unlikely, could theoretically cause collisions in high-concurrency scenarios.

```dart
final assinaturaId = 'assinatura-${now.microsecondsSinceEpoch}';
```

**Impact:** Very low risk in practice. The app is single-user and microsecond precision is fine.

**Fix:** Consider using UUID for guaranteed uniqueness:
```dart
final assinaturaId = 'assinatura-${const Uuid().v4()}';
```

### IN-03: await missing for async delete operation

**File:** `lib/features/rat/presentation/view_models/rat_form_view_model.dart:553-558`
**Issue:** The `_enqueueAssinaturaSync?.delete()` call is not awaited. While the code comment explains this is intentional (local delete should proceed even if remote fails), the pattern is inconsistent with other async calls in the same method.

```dart
await _enqueueAssinaturaSync?.delete(  // Note: await is missing
  assinatura,
  empresaId: remoteSession.empresaId!,
  usuarioId: remoteSession.usuarioId,
  ratId: ratId,
);
```

**Impact:** Low. The comment explains the intent, but the code would be clearer with explicit fire-and-forget pattern or documented with `// ignore: unused_result`.

**Fix:** Add explicit documentation or use unawaited pattern:
```dart
// Fire-and-forget: local delete proceeds even if remote sync fails
unawaited(_enqueueAssinaturaSync?.delete(
  assinatura,
  empresaId: remoteSession.empresaId!,
  usuarioId: remoteSession.usuarioId,
  ratId: ratId,
));
```

---

_Reviewed: 2025-01-15T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
