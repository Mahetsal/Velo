import 'package:flutter_test/flutter_test.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/models/direction_details.dart';

void main() {
  final cm = CommonMethods();

  DirectionDetails trip({required int meters, required int seconds}) =>
      DirectionDetails(distanceValueDigit: meters, durationValueDigit: seconds);

  // Fare formula reference (from CommonMethods):
  //   distancePerKm  = 0.35 JOD
  //   durationPerMin = 0.08 JOD
  //   baseFare       = 0.50 JOD
  //   bookingFee     = 0.20 JOD
  //   minimumFare    = 1.00 JOD

  group('calculateFareAmountInJOD', () {
    test('10 km / 10 min with default 5% discount', () {
      // 0.50 + (10 * 0.35) + (10 * 0.08) + 0.20 = 5.00
      // surge 1.0 → 5.00, discount 5% → 4.75
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 10000, seconds: 600),
        surgeMultiplier: 1.0,
        riderDiscountPercent: 5.0,
      );
      expect(fare, '4.75');
    });

    test('zero discount preserves full fare', () {
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 10000, seconds: 600),
        surgeMultiplier: 1.0,
        riderDiscountPercent: 0.0,
      );
      expect(fare, '5.00');
    });

    test('very short trip hits minimum fare floor', () {
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 100, seconds: 60),
        surgeMultiplier: 1.0,
        riderDiscountPercent: 0.0,
      );
      expect(fare, '1.00');
    });

    test('surge 2x doubles before-discount fare', () {
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 10000, seconds: 600),
        surgeMultiplier: 2.0,
        riderDiscountPercent: 0.0,
      );
      expect(fare, '10.00');
    });

    test('heavy discount floors at minimum', () {
      // ~1.64 before discount, 80% off → ~0.33 → floor 1.00
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 2000, seconds: 180),
        surgeMultiplier: 1.0,
        riderDiscountPercent: 80.0,
      );
      expect(fare, '1.00');
    });

    test('half discount on standard trip', () {
      // 5.00 * 0.50 = 2.50
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 10000, seconds: 600),
        surgeMultiplier: 1.0,
        riderDiscountPercent: 50.0,
      );
      expect(fare, '2.50');
    });

    test('1 km / 2 min no discount', () {
      // 0.50 + 0.35 + 0.16 + 0.20 = 1.21
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 1000, seconds: 120),
        surgeMultiplier: 1.0,
        riderDiscountPercent: 0.0,
      );
      expect(fare, '1.21');
    });

    test('surge 1.5x with 5% discount', () {
      // 5.00 * 1.5 = 7.50, * 0.95 = 7.125 → "7.12" or "7.13"
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 10000, seconds: 600),
        surgeMultiplier: 1.5,
        riderDiscountPercent: 5.0,
      );
      expect(double.parse(fare), closeTo(7.125, 0.01));
    });

    test('result always has exactly two decimal places', () {
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 5000, seconds: 300),
        surgeMultiplier: 1.0,
        riderDiscountPercent: 5.0,
      );
      expect(fare, matches(RegExp(r'^\d+\.\d{2}$')));
    });

    test('minimum fare re-applied after discount pushes below floor', () {
      // short trip → floor at 1.00, then 10% discount → 0.90 → re-floor at 1.00
      final fare = cm.calculateFareAmountInJOD(
        trip(meters: 200, seconds: 60),
        surgeMultiplier: 1.0,
        riderDiscountPercent: 10.0,
      );
      expect(fare, '1.00');
    });
  });
}
