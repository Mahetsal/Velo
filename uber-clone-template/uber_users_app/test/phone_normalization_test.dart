import 'package:flutter_test/flutter_test.dart';
import 'package:uber_users_app/methods/phone_utils.dart';

void main() {
  group('normalizeJordanPhone', () {
    test('local 07X format → +962...', () {
      expect(normalizeJordanPhone('0791234567'), '+962791234567');
    });

    test('9-digit without prefix → +962...', () {
      expect(normalizeJordanPhone('791234567'), '+962791234567');
    });

    test('country code without plus → +962...', () {
      expect(normalizeJordanPhone('962791234567'), '+962791234567');
    });

    test('already international +962 → unchanged', () {
      expect(normalizeJordanPhone('+962791234567'), '+962791234567');
    });

    test('spaces and dashes are stripped', () {
      expect(normalizeJordanPhone('07 9123-4567'), '+962791234567');
    });

    test('parentheses are stripped', () {
      expect(normalizeJordanPhone('(079) 123 4567'), '+962791234567');
    });

    test('non-Jordan international number with + passes through', () {
      expect(normalizeJordanPhone('+14155551234'), '+14155551234');
    });

    test('leading/trailing whitespace trimmed for + numbers', () {
      expect(normalizeJordanPhone('  +962791234567  '), '+962791234567');
    });
  });
}
