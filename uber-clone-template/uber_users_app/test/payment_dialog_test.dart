import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/widgets/payment_dialog.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

/// Opens a [PaymentDialog] via showDialog and pumps until settled.
Future<void> _openDialog(
  WidgetTester tester, {
  required String fareAmount,
  String preferredPaymentMethod = 'Cash',
  String promoCode = '',
}) async {
  await tester.pumpWidget(_buildApp(
    Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showDialog<String>(
            context: ctx,
            builder: (_) => PaymentDialog(
              fareAmount: fareAmount,
              tripId: 'trip-1',
              userId: 'user-1',
              preferredPaymentMethod: preferredPaymentMethod,
              promoCode: promoCode,
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ApiClient.httpClientOverride = MockClient((request) async {
      if (request.url.path.contains('/users/')) {
        return http.Response(
          jsonEncode({
            'exists': true,
            'item': {
              'walletBalance': '50.00',
              'walletTransactions': <Map<String, dynamic>>[],
            },
          }),
          200,
        );
      }
      return http.Response('{}', 200);
    });
  });

  tearDown(() {
    ApiClient.httpClientOverride = null;
    ApiClient.setAuthToken(null);
  });

  group('PaymentDialog', () {
    testWidgets('shows fare amount and cash button', (tester) async {
      await _openDialog(tester, fareAmount: '3.50');

      expect(find.text('JOD 3.50'), findsOneWidget);
      expect(find.text('PAY WITH CASH'), findsOneWidget);
    });

    testWidgets('shows wallet button for wallet payment method',
        (tester) async {
      await _openDialog(
        tester,
        fareAmount: '5.00',
        preferredPaymentMethod: 'Wallet',
      );

      expect(find.text('PAY WITH WALLET'), findsOneWidget);
      expect(find.text('PAY WITH CASH'), findsNothing);
    });

    testWidgets('OK button dismisses dialog', (tester) async {
      await _openDialog(tester, fareAmount: '2.00');

      expect(find.text('JOD 2.00'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('JOD 2.00'), findsNothing);
    });

    testWidgets('cash payment dismisses dialog', (tester) async {
      await _openDialog(tester, fareAmount: '4.00');

      await tester.tap(find.text('PAY WITH CASH'));
      await tester.pumpAndSettle();
      expect(find.text('JOD 4.00'), findsNothing);
    });

    testWidgets('wallet payment with sufficient balance dismisses dialog',
        (tester) async {
      await _openDialog(
        tester,
        fareAmount: '5.00',
        preferredPaymentMethod: 'Wallet',
      );

      await tester.tap(find.text('PAY WITH WALLET'));
      await tester.pumpAndSettle();
      expect(find.text('JOD 5.00'), findsNothing);
    });

    testWidgets('unsupported payment method shows fallback message',
        (tester) async {
      await _openDialog(
        tester,
        fareAmount: '1.50',
        preferredPaymentMethod: 'CreditCard',
      );

      expect(find.text('PAY WITH CASH'), findsNothing);
      expect(find.text('PAY WITH WALLET'), findsNothing);
      expect(
        find.text('Only Cash and Wallet are currently supported.'),
        findsOneWidget,
      );
    });
  });
}
