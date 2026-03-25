import 'package:flutter_test/flutter_test.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/models/direction_details.dart';

void main() {
  late CommonMethods methods;

  setUp(() {
    methods = CommonMethods();
  });

  DirectionDetails _details({required int meters, required int seconds}) {
    final d = DirectionDetails();
    d.distanceValueDigit = meters;
    d.durationValueDigit = seconds;
    return d;
  }

  group('calculateFareAmountInJOD', () {
    test('minimum fare is 1.00 JOD for very short trips', () {
      final result = methods.calculateFareAmountInJOD(
        _details(meters: 200, seconds: 60),
      );
      expect(double.parse(result), 1.00);
    });

    test('fare scales with distance and time', () {
      final short = double.parse(methods.calculateFareAmountInJOD(
        _details(meters: 3000, seconds: 300),
      ));
      final long = double.parse(methods.calculateFareAmountInJOD(
        _details(meters: 15000, seconds: 1200),
      ));
      expect(long, greaterThan(short));
    });

    test('surge multiplier increases fare', () {
      final details = _details(meters: 10000, seconds: 600);
      final normal = double.parse(
        methods.calculateFareAmountInJOD(details, surgeMultiplier: 1.0),
      );
      final surged = double.parse(
        methods.calculateFareAmountInJOD(details, surgeMultiplier: 1.5),
      );
      expect(surged, greaterThan(normal));
    });

    test('rider discount reduces fare', () {
      final details = _details(meters: 10000, seconds: 600);
      final noDiscount = double.parse(
        methods.calculateFareAmountInJOD(details, riderDiscountPercent: 0),
      );
      final withDiscount = double.parse(
        methods.calculateFareAmountInJOD(details, riderDiscountPercent: 10),
      );
      expect(withDiscount, lessThan(noDiscount));
    });

    test('result is formatted to 2 decimal places', () {
      final result = methods.calculateFareAmountInJOD(
        _details(meters: 8000, seconds: 900),
      );
      expect(result, matches(RegExp(r'^\d+\.\d{2}$')));
    });
  });

  group('shortenAddress', () {
    test('returns first two parts for comma-separated address', () {
      expect(
        CommonMethods.shortenAddress("King Abdullah II St, Amman, Jordan"),
        "King Abdullah II St, Amman",
      );
    });

    test('returns full string if fewer than 2 parts', () {
      expect(CommonMethods.shortenAddress("Amman"), "Amman");
    });
  });

  group('formatTime', () {
    test('minutes only when under 60', () {
      expect(methods.formatTime(45), "45 mins");
    });

    test('hours and minutes when 60+', () {
      expect(methods.formatTime(90), "1 hours 30 mins");
    });
  });
}
