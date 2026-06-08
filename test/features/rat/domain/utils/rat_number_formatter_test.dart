import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/rat/domain/utils/rat_number_formatter.dart';

void main() {
  group('ratDisplayNumber', () {
    test('RAT-123 → 123', () {
      expect(ratDisplayNumber('RAT-123'), '123');
    });

    test('RAT 123 → 123', () {
      expect(ratDisplayNumber('RAT 123'), '123');
    });

    test('rat-123 → 123', () {
      expect(ratDisplayNumber('rat-123'), '123');
    });

    test('123 → 123', () {
      expect(ratDisplayNumber('123'), '123');
    });

    test('string com espacos → trim correto', () {
      expect(ratDisplayNumber('  RAT-456  '), '456');
    });
  });
}
