import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_admin_panel/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows Velo Admin login when not logged in', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Velo Admin'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign in to manage operations'), findsOneWidget);
  });
}
