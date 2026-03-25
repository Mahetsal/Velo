import 'package:flutter_test/flutter_test.dart';
import 'package:uber_users_app/methods/common_methods.dart';

void main() {
  group('CommonMethods.shortenAddress', () {
    test('keeps first two comma-separated parts', () {
      expect(
        CommonMethods.shortenAddress('King Abdullah St, Amman, Jordan'),
        'King Abdullah St, Amman',
      );
    });

    test('returns full string when no comma', () {
      expect(CommonMethods.shortenAddress('Amman'), 'Amman');
    });

    test('trims whitespace around parts', () {
      expect(
        CommonMethods.shortenAddress('  Part A  ,  Part B , Part C'),
        'Part A, Part B',
      );
    });

    test('returns empty string for empty input', () {
      expect(CommonMethods.shortenAddress(''), '');
    });

    test('handles exactly two parts', () {
      expect(
        CommonMethods.shortenAddress('Street, City'),
        'Street, City',
      );
    });
  });

  group('CommonMethods.formatTime', () {
    final cm = CommonMethods();

    test('minutes only when under an hour', () {
      expect(cm.formatTime(45), '45 mins');
    });

    test('hours and minutes for 90 min', () {
      expect(cm.formatTime(90), '1 hours 30 mins');
    });

    test('exactly one hour', () {
      expect(cm.formatTime(60), '1 hours 0 mins');
    });

    test('zero minutes', () {
      expect(cm.formatTime(0), '0 mins');
    });

    test('multiple hours', () {
      expect(cm.formatTime(125), '2 hours 5 mins');
    });
  });
}
