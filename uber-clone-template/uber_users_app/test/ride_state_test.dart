import 'package:flutter_test/flutter_test.dart';
import 'package:uber_users_app/state/ride_state.dart';

void main() {
  late RideState state;

  setUp(() {
    state = RideState();
  });

  test('initial phase is idle', () {
    expect(state.phase, RidePhase.idle);
  });

  test('setPhase transitions and notifies', () {
    int notifyCount = 0;
    state.addListener(() => notifyCount++);

    state.setPhase(RidePhase.requesting);
    expect(state.phase, RidePhase.requesting);
    expect(notifyCount, 1);

    // Same phase — no notification.
    state.setPhase(RidePhase.requesting);
    expect(notifyCount, 1);
  });

  test('updateDriver updates selected fields', () {
    state.updateDriver(name: 'Ali', phone: '+962700000000');
    expect(state.driverName, 'Ali');
    expect(state.driverPhone, '+962700000000');
    expect(state.driverPhoto, isEmpty);
  });

  test('reset clears all fields', () {
    state.setPhase(RidePhase.active);
    state.updateDriver(name: 'Sami', carDetails: 'Toyota');
    state.reset();

    expect(state.phase, RidePhase.idle);
    expect(state.driverName, isEmpty);
    expect(state.carDetails, isEmpty);
    expect(state.requestTimeoutSeconds, 40);
  });

  test('tickTimeout decrements', () {
    expect(state.requestTimeoutSeconds, 40);
    state.tickTimeout();
    expect(state.requestTimeoutSeconds, 39);
  });
}
