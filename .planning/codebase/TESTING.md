# Testing Patterns

**Analysis Date:** 2025-01-20

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK built-in)
- Version: determined by Flutter SDK (`^3.11.4` based on pubspec.yaml)

**Test Configuration:**
- No additional test configuration files (jest.config, vitest.config, etc.)
- Standard Flutter test setup

**Run Commands:**
```bash
flutter test                    # Run all tests
flutter test test/path/         # Run specific test file
flutter test --reporter expanded # Detailed output
```

## Test File Organization

**Location:**
- Tests mirror the `lib/` structure under `test/`
- Each feature has its own test directory

**Naming:**
- Test files use `_test.dart` suffix (e.g., `rat_form_view_model_test.dart`)
- Test classes are not required (tests can be in `void main()` blocks)

**Directory Structure:**
```
test/
  app/
    navigation/
      app_bootstrap_view_model_test.dart
    theme/
      app_theme_view_model_test.dart
      metric_slate_tokens_test.dart
      metric_slate_component_themes_test.dart
  features/
    company_auth/
      presentation/
        screens/
          company_sign_in_screen_test.dart
    rat/
      domain/
        utils/
          rat_number_formatter_test.dart
      presentation/
        screens/
          rat_list_screen_test.dart
        view_models/
          rat_form_view_model_test.dart
          rat_list_view_model_test.dart
        widgets/
          rat_list_item_card_test.dart
    sync/
      usecases/
        process_sync_queue_test.dart
        process_assinatura_sync_test.dart
        enqueue_assinatura_sync_test.dart
  shared/
    infra/
      database/
        open_encrypted_database_test.dart
      security/
        database_key_store_test.dart
        local_pin_secret_store_test.dart
    presentation/
      widgets/
        tech_report_widgets_test.dart
```

## Test Structure

**Unit Tests (ViewModels):**
```dart
void main() {
  late _StubRatRepository ratRepo;
  late _StubAssinaturaRepository assinaturaRepo;

  setUp(() {
    ratRepo = _StubRatRepository();
    assinaturaRepo = _StubAssinaturaRepository();
  });

  RatFormViewModel buildVm({Rat? initialRat, SessaoRemota? remoteSession}) {
    return RatFormViewModel(
      assinaturaRepository: assinaturaRepo,
      ratRepository: ratRepo,
      initialRat: initialRat,
      remoteSession: remoteSession,
    );
  }

  group('validate()', () {
    test('retorna erro para cliente vazio', () {
      final sut = buildVm();

      final result = sut.validate();

      expect(result, isNotNull);
      expect(result, contains('cliente'));
    });
  });
}
```

**Widget Tests:**
```dart
void main() {
  Widget buildCard({required Rat rat, bool hasSignature = false}) {
    return MaterialApp(
      home: Scaffold(
        body: RatListItemCard(
          rat: rat,
          hasSignature: hasSignature,
          onTap: () {},
          onPreviewPdf: () {},
        ),
      ),
    );
  }

  group('RatListItemCard', () {
    testWidgets('exibe nome do cliente e numero do RAT', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCard(rat: _fixtureRat));

      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('RAT-2024-001'), findsOneWidget);
    });
  });
}
```

## Mocking Patterns

**Stub classes** implement interfaces with minimal behavior:

```dart
class _StubRatRepository implements RatRepository {
  Rat? savedRat;
  bool shouldThrowOnSave = false;

  @override
  Future<Rat?> getById(String id) async => null;

  @override
  Future<void> save(Rat rat) async {
    if (shouldThrowOnSave) {
      throw Exception('Save failed');
    }
    savedRat = rat;
  }
}
```

**Key characteristics:**
- Stub classes are prefixed with `_` (private to test file)
- Stubs track state for assertions (e.g., `savedRat`, `syncedIds`)
- Flags like `shouldThrowOnSave` control error behavior
- Collections track calls (e.g., `processingIds`, `failedCalls`)

**Factory helpers** create test fixtures:

```dart
Rat _makeValidRat({
  String id = 'rat-1',
  String clienteNome = 'Cliente Teste',
  DateTime? dataVisita,
}) {
  final now = DateTime.now();
  return Rat(
    id: id,
    authorId: 'author-1',
    empresaId: 'emp-1',
    // ...
  );
}
```

## Test Group Organization

Tests are organized into logical groups using `group()`:

**Group naming conventions:**
- Portuguese descriptions (Brazilian codebase)
- Group by method name: `group('validate()', ...)`
- Group by feature: `group('RAT upsert', ...)`
- Group by scenario: `group('falha e retry', ...)`

**Typical group structure:**
```dart
group('validate()', () { /* validation tests */ });
group('save()', () { /* save operation tests */ });
group('loadSignatureStatus()', () { /* signature loading tests */ });
group('notifyListeners', () { /* listener notification tests */ });
```

## Common Test Patterns

**Testing state changes:**
```dart
test('isSaved vira true apos save bem-sucedido', () async {
  final sut = buildVm();
  // setup valid form...

  expect(sut.isSaved, isFalse);

  await sut.save();

  expect(sut.isSaved, isTrue);
});
```

**Testing loading state:**
```dart
test('load() seta isLoading durante execucao', () async {
  var isLoadingDuringLoad = false;
  sut.addListener(() {
    if (sut.isLoading) isLoadingDuringLoad = true;
  });

  await sut.load();

  expect(isLoadingDuringLoad, isTrue);
  expect(sut.isLoading, isFalse);
});
```

**Testing error handling:**
```dart
test('retorna false quando save do repository lanca excecao', () async {
  ratRepo.shouldThrowOnSave = true;
  // setup valid form...

  final result = await sut.save();

  expect(result, isFalse);
});
```

**Testing listener notifications:**
```dart
test('setClienteNome dispara notifyListeners', () {
  final sut = buildVm();
  var notified = false;
  sut.addListener(() => notified = true);

  sut.setClienteNome('Novo Cliente');

  expect(notified, isTrue);
});
```

## Test Coverage Areas

**Covered:**
- ViewModels: validation, save, delete, state transitions
- Widgets: rendering, user interactions (tap, button press)
- Use cases: business logic, error handling, retry logic
- Entities: formatting utilities
- Infrastructure: database key store, encrypted database

**Not detected (gaps):**
- Repository implementations (drift/local implementations)
- Screen integration tests (limited widget tests only)
- E2E tests (not present)
- Synchronization edge cases

## Widget Test Helpers

**Wrap widget for testing:**
```dart
Widget wrap(Widget child) {
  return MaterialApp(
    theme: MetricSlateTheme.light(),
    home: Scaffold(body: child),
  );
}
```

**Test widget interactions:**
```dart
await tester.tap(find.byType(InkWell).first);
expect(tapped, isTrue);

await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
expect(pdfTapped, isTrue);
```

## Assertion Patterns

**Common assertions:**
- `expect(result, isNull)` - successful validation
- `expect(result, isNotNull)` - validation error
- `expect(result, contains('texto'))` - error message contains text
- `expect(sut.rats, hasLength(3))` - list length
- `expect(queueRepo.syncedIds, contains('sync-1'))` - collection contains
- `expect(ratRepo.savedRat!.syncStatus, RatSyncStatus.synced)` - enum value

---

*Testing analysis: 2025-01-20*
