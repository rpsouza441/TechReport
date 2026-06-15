# Codebase Concerns

**Analysis Date:** 2025-03-11

## Tech Debt

**Large ViewModel with excessive state management:**
- File: `lib/features/rat/presentation/view_models/rat_form_view_model.dart` (879 lines)
- Issue: The `RatFormViewModel` contains 50+ fields and handles form state, PDF generation, signature management, sync coordination, and network operations. This violates Single Responsibility Principle.
- Impact: Difficult to test, maintain, and extend. Any change risks unintended side effects across unrelated features.
- Fix approach: Break into specialized classes: `RatFormState`, `RatSignatureManager`, `RatPdfGenerator`, `RatSyncHandler`.

**Large Screen files with deep widget nesting:**
- File: `lib/features/company_admin/presentation/screens/admin_empresa_area.dart` (833 lines)
- File: `lib/features/rat/presentation/screens/rat_form_screen.dart` (728 lines)
- File: `lib/features/company_auth/presentation/screens/company_home_screen.dart` (720 lines)
- Issue: Multiple screens exceed 700 lines with deeply nested widget trees (5-7 levels deep).
- Impact: Difficult to navigate, test, and modify. Re-render performance may suffer.
- Fix approach: Extract `_FormSection` widgets, `_buildChips`, `_buildStatusRow` into separate widget files. Use composition over nesting.

**SupabaseAuthRepository handles too many responsibilities:**
- File: `lib/features/company_auth/data/repositories/supabase_auth_repository.dart` (702 lines)
- Issue: Single class handles authentication, session management, profile fetching, and invite processing across multiple flows.
- Impact: High coupling, difficult to test individual flows in isolation.
- Fix approach: Extract `ProfileFetcher`, `InviteProcessor`, `SessionManager` as separate services.

**Generated database file included in source tree:**
- File: `lib/shared/infra/database/tech_report_local_database.g.dart` (6603 lines)
- Issue: 6603-line generated file is committed to source control.
- Impact: Bloats repository, creates merge conflicts during code generation.
- Fix approach: Add to `.gitignore` and regenerate on build. Use `build_runner` in CI.

## Missing Error Handling

**Silent catch blocks swallow exceptions without user feedback:**
- `lib/app/bootstrap/bootstrap.dart:74` - `} catch (_) {` in `_logBootstrapScopeAuditFailure`
- `lib/app/bootstrap/bootstrap.dart:82` - `} catch (_) {` in key store access
- `lib/app/navigation/company_shell.dart:494` - `} catch (_) {` in sync status
- `lib/features/company_admin/presentation/view_models/app_admin_view_model.dart:40,59,95,123` - Multiple `} catch (_) {`
- `lib/features/company_auth/data/repositories/supabase_auth_repository.dart:73,142,223,366` - `} catch (_) {`
- Issue: Exception variables are discarded, making debugging impossible and silently failing operations.
- Fix approach: Log errors at minimum, provide user-facing messages where appropriate.

**Catch blocks without specific exception types:**
- `lib/features/rat/presentation/view_models/rat_form_view_model.dart:388,498,527,627` - `catch (_)` with generic error messages
- Issue: Only catches `Exception` base type, loses stack traces and error context.
- Fix approach: Catch specific exceptions or use `catch (error, stackTrace)` and log appropriately.

**Missing validation in backup import:**
- `lib/features/local_auth/data/services/local_backup_parser.dart:57-58` - Legacy JSON import accepts without checksum validation
- `lib/features/local_auth/data/services/local_backup_parser.dart:56-58` - `validateIntegrity` returns true for legacy JSON without actual validation
- Issue: Legacy backups bypass integrity checks entirely.
- Impact: Corrupted or tampered legacy backups could be imported without detection.
- Fix approach: Add checksum validation to legacy format or warn users about reduced validation.

## Performance Concerns

**AnimatedBuilder rebuilds entire widget tree:**
- `lib/app/navigation/company_shell.dart:250` - `AnimatedBuilder(animation: widget.viewModel, builder: ...)` wraps full build
- `lib/features/company_admin/presentation/screens/admin_empresa_area.dart:42-73` - Full screen wrapped in AnimatedBuilder
- `lib/features/rat/presentation/screens/rat_list_screen.dart:90-125` - Full build wrapped
- Issue: Any `notifyListeners()` in the ViewModel triggers full widget rebuild, even for unrelated UI parts.
- Impact: Performance degradation as app grows. List scrolling may trigger unnecessary rebuilds.
- Fix approach: Use `Selector` or `context.select` for granular rebuilds where possible.

**No pagination/infinite scroll optimization:**
- `lib/features/rat/presentation/screens/rat_list_screen.dart:195-228` - Uses `ListView.separated` with full list
- Issue: All loaded RATs are rendered in the list, no virtualization for large datasets.
- Impact: Memory issues with hundreds of RATs. Scroll performance may degrade.
- Fix approach: Implement `ListView.builder` with pagination or use a lazy-loading approach.

**RAT number generator uses microseconds:**
- `lib/features/rat/presentation/view_models/rat_form_view_model.dart:811-813`:
```dart
String _newRatNumber() {
  return '${DateTime.now().microsecondsSinceEpoch}';
}
```
- Issue: If two RATs are created in the same microsecond, duplicate numbers occur.
- Impact: Data integrity issue in high-speed usage scenarios.
- Fix approach: Use UUID-based identifier or add a counter.

## Security Considerations

**Implicit auth flow in Supabase client:**
- `lib/features/company_auth/data/services/supabase_client_factory.dart:63`:
```dart
authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
```
- Issue: `AuthFlowType.implicit` is deprecated in OAuth 2.0 (RFC 6749) and considered less secure than PKCE. The `supabase_flutter` SDK uses this by default.
- Impact: Tokens exposed in URL fragment, vulnerable to token theft via browser history or referrer headers.
- Fix approach: Verify `AuthFlowType.pkce` is available in current SDK version and migrate.

**PIN stored with low iteration count:**
- `lib/shared/infra/security/local_pin_secret_store.dart:14`:
```dart
static const _defaultIterations = 10000;
```
- Issue: PBKDF2 with only 10,000 iterations is below OWASP 2023 recommendations (120,000+ for PBKDF2-HMAC-SHA256).
- Impact: PINs could be brute-forced if device storage is compromised.
- Fix approach: Increase to at least 100,000 iterations. Consider using Argon2id instead.

**Backup export contains no encryption:**
- `lib/features/local_auth/data/services/local_backup_service.dart` - Exports data as ZIP with checksums only
- Issue: Backup file contains plaintext RAT data and signatures (base64 encoded in JSON).
- Impact: If backup file is shared or stolen, all data is readable without any encryption.
- Fix approach: Add optional password-protected ZIP encryption using `archive` package or encrypt the entire archive with AES-256.

**Secret keys stored with FlutterSecureStorage defaults:**
- `lib/features/company_auth/data/services/flutter_secure_token_store.dart:6`:
```dart
FlutterSecureTokenStore([FlutterSecureStorage? storage])
  : _storage = storage ?? const FlutterSecureStorage();
```
- Issue: Uses default `FlutterSecureStorage` without explicit platform options. On Android, may use SharedPreferences under certain configurations.
- Impact: Security depends on platform defaults which may vary.
- Fix approach: Explicitly configure `FlutterSecureStorage` with `iOptions` and `aOptions` for maximum security.

## Accessibility Gaps

**Missing semantic labels on icon-only buttons:**
- `lib/features/company_admin/presentation/screens/admin_empresa_area.dart:574-580` - Share/cancel invite buttons have tooltips but no `semanticsLabel`
- `lib/features/rat/presentation/widgets/rat_list_item_card.dart:78-91` - PDF preview button has tooltip only
- Issue: Screen readers cannot describe icon-only buttons without `semanticsLabel`.
- Impact: App is not fully accessible for visually impaired users using screen readers.
- Fix approach: Add `semanticsLabel` to all IconButtons and icon-only actions.

**No keyboard navigation support:**
- Files: `lib/features/company_admin/presentation/screens/admin_empresa_area.dart`, `lib/features/local_auth/presentation/screens/local_settings_screen.dart`
- Issue: Forms and lists lack explicit keyboard navigation (FocusNode, Tab order).
- Impact: Users with motor impairments cannot fully use the app without a mouse.
- Fix approach: Add `FocusNode` management and ensure logical tab order.

**Missing color contrast considerations:**
- `lib/shared/presentation/widgets/tech_report_status_chip.dart` - Uses tone-based colors without explicit contrast checking
- Issue: Custom color variants (cobalt, volt, burgundy) may not meet WCAG AA contrast ratios.
- Impact: Users with color vision deficiencies may have difficulty distinguishing states.
- Fix approach: Verify all color combinations meet 4.5:1 contrast ratio for normal text.

## Code Smells / Anti-Patterns

**God ViewModel pattern:**
- `lib/features/rat/presentation/view_models/rat_form_view_model.dart` - 879 lines, 50+ fields
- Issue: Single ViewModel handles form data, validation, persistence, sync, PDF generation, and signature management.
- Fix approach: Extract into `RatFormState`, `RatPdfService`, `RatSyncService`, `RatSignatureService`.

**Duplicate error handling patterns:**
- `lib/features/company_admin/presentation/view_models/admin_empresa_view_model.dart:87,126,145,171,200,238` - Same `catch (error)` pattern repeated
- Issue: Copy-paste error handling scattered across view models.
- Fix approach: Create base `ViewModel` class with standard error handling or create error extension methods.

**Magic strings throughout codebase:**
- `lib/features/company_auth/data/services/secure_token_store.dart:2-7` - Static const keys defined but used inconsistently
- `lib/features/rat/domain/entities/rat.dart` - Status/sync status as string enums
- Issue: String values are repeated and not centralized.
- Fix approach: Use enums and centralized constants consistently.

**Long parameter lists in constructors:**
- `lib/features/rat/presentation/screens/rat_list_screen.dart:25-55` - 14 parameters
- `lib/features/rat/presentation/screens/rat_form_screen.dart:21-27` - 2 parameters (but many on ViewModel)
- Issue: Functions require many arguments, making calls error-prone.
- Fix approach: Group related parameters into configuration objects/data classes.

**Inconsistent error message language:**
- Files: `lib/features/company_auth/data/repositories/supabase_auth_repository.dart`, `lib/features/rat/presentation/view_models/rat_form_view_model.dart`
- Issue: Mix of Portuguese and English error messages (e.g., "Nao foi possivel" vs "Failed to")
- Impact: Inconsistent user experience.
- Fix approach: Standardize on Portuguese for all user-facing messages.

## Missing Documentation

**No documentation on database migrations:**
- `lib/shared/infra/database/` - No migration strategy documented
- Issue: `dbSchemaVersion = 8` is hardcoded in `local_backup_service.dart:50` but no migration path exists.
- Impact: Schema changes require manual intervention and risk data loss.
- Fix approach: Document migration strategy and implement version-based migrations.

**No API documentation for external integrations:**
- `lib/features/company_auth/data/repositories/supabase_auth_repository.dart` - RPC calls like `accept_tecnico_convite`, `update_own_display_name` have no documentation
- Issue: Unknown what these functions do or their expected inputs/outputs.
- Fix approach: Add doc comments explaining each RPC call and its contract.

**Missing architecture decision records (ADRs):**
- No documentation explaining key architectural choices:
  - Why SQLite3MultipleCiphers for encryption?
  - Why Supabase over other backends?
  - Why Drift ORM over other options?
- Fix approach: Create ADRs in `docs/adr/` explaining major decisions.

## Dependency Risks

**Outdated package with known issues:**
- `supabase_flutter: ^2.0.0` - Current version may have auth issues (see `resendConfirmationEmail` workaround in line 524)
- `archive: ^4.0.4` - Version 4.x had known ZIP handling issues in early releases
- Issue: No explicit pinning to specific versions.
- Impact: `^` version ranges could pull incompatible versions on upgrade.
- Fix approach: Use exact version pins for critical dependencies or use `pubspec_overrides.yaml`.

**No dependency audit in CI:**
- No `flutter pub outdated` or security audit in build pipeline
- Issue: Vulnerable dependencies may be introduced without detection.
- Fix approach: Add `flutter pub outdated` check and `dart pub upgrade --major-versions` with review.

**rat/ directory excluded from analysis:**
- `analysis_options.yaml:14` - `exclude: - rat/**`
- Issue: Legacy code in `rat/` directory is not linted, may contain issues.
- Impact: Technical debt in legacy code is invisible.
- Fix approach: Either fix the linting issues or remove the legacy code entirely.

## Test Coverage Gaps

**Limited integration test coverage:**
- Only 17 test files found for a full-featured application
- No integration tests for sync flows, backup/restore, or multi-step auth flows
- Issue: Critical user flows may break without detection.
- Fix approach: Add integration tests for backup/restore, sync scenarios, and auth flows.

**No test for RatFormViewModel sync behavior:**
- `test/features/rat/presentation/view_models/rat_form_view_model_test.dart` exists but may not cover sync edge cases
- Issue: Sync failures could cause data loss or inconsistency.
- Fix approach: Add tests for offline scenarios, sync queue failures, and conflict resolution.

## Fragile Areas

**Database key rotation logic:**
- `lib/shared/infra/database/open_encrypted_database.dart:91-203` - Complex rekey logic with multiple fallback paths
- Issue: Handles plaintext detection, legacy passphrase, and new key formats with complex try/catch chains.
- Why fragile: Edge cases in database state can cause silent data loss if rekey fails partially.
- Safe modification: Add extensive tests before any change. Ensure rollback capability.

**Pending invite flow with expiration:**
- `lib/features/company_auth/data/repositories/supabase_auth_repository.dart:388-392`:
```dart
final age = DateTime.now().difference(pendingInvite.createdAt);
if (age > const Duration(days: 7)) {
  await _tokenStore.clearPendingInvite();
  return;
}
```
- Issue: Hardcoded 7-day expiration with no user notification.
- Why fragile: Users may not realize their invite expired.
- Safe modification: Add UI notification when invites are about to expire.

**Implicit Supabase session refresh:**
- `lib/features/company_auth/data/services/supabase_client_factory.dart:30-43` - Session refresh logic in factory
- Issue: Automatic session refresh may fail silently, leaving user logged out.
- Why fragile: Network issues during refresh can cause unexpected logout.
- Safe modification: Add retry logic and better error handling for session refresh failures.

## UI Duplication

**Source:** Detailed analysis in `docs/sprint9.4/README.md` (Sprint 9.4 - Levantamento de Componentizacao e Reutilizacao de UI)

**Classification of extraction types:**
| Type | Target | When to use |
|------|--------|-------------|
| Cross-feature reuse | `lib/shared/presentation/widgets/` | Widget used in 3+ different features |
| Local extraction | `lib/features/X/presentation/widgets/` | Avoid duplication WITHIN same feature |
| Logical extraction | `lib/features/X/domain/services/` | Non-visual logic (PDF, sync, etc.) |
| No extraction | Keep inline | Widget too specific or only 1-2 usages |

**Pendente items from Sprint 9.4 (not yet applied):**

**UI-07 - Dialog de descarte duplicado:**
- Files: `rat_form_screen.dart`, `company_edit_profile_screen.dart` (diferentes implementacoes)
- Solution: Create `showDiscardDialog()` in shared/widgets/
- Status: Parcialmente implementado, revisar pendencias

**UI-09 - AlertDialogs de confirmacao espalhados:**
- Files: 8+ arquivos com `showDialog<bool>` + `AlertDialog` boilerplate
- Solution: Create `showTechReportConfirmationDialog()` helper
- Status: Pendente

**UI-12 - Convite cards duplicados:**
- Files: `admin_empresa_area.dart` e `app_admin_company_detail_screen.dart`
- Widgets: `_ConviteCard`, `_ConviteShareSheet` praticamente idnticos
- Solution: Extrair para `company_admin/presentation/widgets/`
- Status: Pendente

**UI-13 - Chips/toggles de admin duplicados:**
- Files: `admin_empresa_area.dart` e `app_admin_company_detail_screen.dart`
- Widgets: `_TecnicoActions`, `_AdminCard` com chips/toggles repetidos
- Solution: Extrair `AdminUserActionChips` para shared widgets
- Status: Pendente

**CODE-01 - PDF duplicado no mesmo servico:**
- File: `rat_pdf_share_service.dart`
- Issue: `buildPreviewBytes()` e `_buildPdf()` montam mesma estrutura
- Solution: Extrair metodo unico `_renderRatPdfBytes()`
- Status: Pendente

**CODE-02 - AlertDialog booleano espalhado:**
- Files: Mltiplos arquivos com mesmo padrao de confirmacao
- Solution: Evoluir UI-09 para wrapper reutilizavel
- Status: Pendente

**Already resolved from Sprint 9.4:**
- UI-03: `_EmptyRatState` removido, usa `TechReportStateView.empty`
- UI-04: `_SettingsCard` + `ProfileCard` removidos, usa `LocalInfoCard`
- UI-01 (partial): `LocalHomeScreen` agora usa `TechReportStateView.error`
- UI-05 (partial): `LocalSettingsScreen` usa `TechReportSectionHeader`

**Reference:** `docs/sprint9.4/specs/` contains specs for each pending item.