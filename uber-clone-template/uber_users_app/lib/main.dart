import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/authentication/register_screen.dart';
import 'package:uber_users_app/firebase_options.dart';
import 'package:uber_users_app/methods/push_notification_service.dart';
import 'package:uber_users_app/pages/blocked_screen.dart';
import 'package:uber_users_app/pages/user_root_page.dart';
import 'package:uber_users_app/state/ride_state.dart';
import 'package:uber_users_app/theme/app_theme.dart';

late Size mq;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService.setupAfterFirebaseInit();
  } catch (e, st) {
    debugPrint('Firebase / push setup skipped: $e\n$st');
  }
  // permission_handler does not implement locationWhenInUse on web.
  if (!kIsWeb) {
    await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
      if (valueOfPermission) {
        Permission.locationWhenInUse.request();
      }
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfoClass()),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => RideState()),
      ],
      child: Consumer<AppInfoClass>(
        builder: (context, appInfo, _) {
          return MaterialApp(
            title: 'Velo User App',
            debugShowCheckedModeBanner: false,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: appInfo.locale,
            localeResolutionCallback: (locale, supported) {
              // Keep user's explicit choice; fall back to device only if unset.
              if (appInfo.prefsLoaded) return appInfo.locale;
              if (locale == null) return const Locale('en');
              final code = supported
                  .map((e) => e.languageCode)
                  .contains(locale.languageCode)
                  ? locale.languageCode
                  : "en";
              return Locale(code);
            },
            theme: AppTheme.veloLight(),
            darkTheme: AppTheme.veloDark(),
            themeMode: appInfo.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 280),
            home: const AuthCheck(),
          );
        },
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the AuthenticationProvider via Provider
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    return FutureBuilder<void>(
      future: authProvider.loadSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ); // Show loading indicator
        }

        // If user is not logged in, navigate to RegisterScreen
        if (authProvider.uid == null) {
          return const RegisterScreen();
        }

        // If user is logged in, first check if the driver is blocked
        return FutureBuilder<bool>(
          future: authProvider
              .checkIfUserIsBlocked(), // Check if the driver is blocked
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SafeArea(
                child: Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data == true) {
              // If the driver is blocked, show an appropriate message
              return const BlockedScreen();
            }
            // If the driver is not blocked, check for profile completeness
            return FutureBuilder<bool>(
              future: authProvider
                  .checkUserFieldsFilled(), // Check if the profile fields are filled
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SafeArea(
                    child: Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data == true) {
                  // If profile is complete, navigate to the dashboard
                  return const UserRootPage();
                } else {
                  // If profile is incomplete, navigate to the registration screen
                  return const RegisterScreen();
                }
              },
            );
          },
        );
      },
    );
  }
}
