import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uber_users_app/widgets/active_ride/ride_tier_sheet.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

RideTierSheet _sheet({
  String selectedTier = 'Economy',
  ValueChanged<String>? onSelectTier,
  VoidCallback? onConfirm,
  VoidCallback? onTogglePayment,
  String paymentLabel = 'Cash',
  String pickupText = 'Point A',
  String destinationText = 'Point B',
}) {
  return RideTierSheet(
    pickupText: pickupText,
    destinationText: destinationText,
    selectedTier: selectedTier,
    onSelectTier: onSelectTier ?? (_) {},
    etaText: '5 min',
    fareByTier: const {
      'Economy': 'JOD 1.00',
      'Comfort': 'JOD 2.00',
      'XL': 'JOD 3.00',
    },
    paymentLabel: paymentLabel,
    onConfirm: onConfirm ?? () {},
    onTogglePayment: onTogglePayment ?? () {},
  );
}

void main() {
  group('RideTierSheet', () {
    testWidgets('renders all three tier tiles', (tester) async {
      await tester.pumpWidget(_buildApp(_sheet()));
      await tester.pumpAndSettle();

      expect(find.text('Velo Economy'), findsOneWidget);
      expect(find.text('Velo Comfort'), findsOneWidget);
      expect(find.text('Velo XL'), findsOneWidget);
    });

    testWidgets('displays fare prices per tier', (tester) async {
      await tester.pumpWidget(_buildApp(_sheet()));
      await tester.pumpAndSettle();

      expect(find.text('JOD 1.00'), findsOneWidget);
      expect(find.text('JOD 2.00'), findsOneWidget);
      expect(find.text('JOD 3.00'), findsOneWidget);
    });

    testWidgets('tapping a tier fires onSelectTier with tier name',
        (tester) async {
      String? selected;
      await tester.pumpWidget(
        _buildApp(_sheet(onSelectTier: (t) => selected = t)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Velo Comfort'));
      expect(selected, 'Comfort');
    });

    testWidgets('confirm button fires onConfirm', (tester) async {
      bool confirmed = false;
      await tester.pumpWidget(
        _buildApp(_sheet(onConfirm: () => confirmed = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Booking'));
      expect(confirmed, isTrue);
    });

    testWidgets('shows pickup and destination text', (tester) async {
      await tester.pumpWidget(_buildApp(
        _sheet(pickupText: 'Abdali Boulevard', destinationText: 'Airport'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Abdali Boulevard'), findsOneWidget);
      expect(find.text('Airport'), findsOneWidget);
    });

    testWidgets('shows payment label and change button fires callback',
        (tester) async {
      bool toggled = false;
      await tester.pumpWidget(_buildApp(
        _sheet(paymentLabel: 'Wallet', onTogglePayment: () => toggled = true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Wallet'), findsOneWidget);
      await tester.tap(find.text('Change'));
      expect(toggled, isTrue);
    });
  });
}
