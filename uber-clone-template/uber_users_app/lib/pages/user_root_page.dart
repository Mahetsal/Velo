import 'package:flutter/material.dart';
import 'package:uber_users_app/methods/push_notification_service.dart';
import 'package:uber_users_app/pages/account_page.dart';
import 'package:uber_users_app/pages/home_page.dart';
import 'package:uber_users_app/pages/trips_history_page.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';

class UserRootPage extends StatefulWidget {
  const UserRootPage({super.key});

  @override
  State<UserRootPage> createState() => _UserRootPageState();
}

class _UserRootPageState extends State<UserRootPage> {
  int _index = 0;

  final List<Widget> _pages = const [
    HomePage(),
    TripsHistoryPage(),
    AccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.registerDeviceTokenWithBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: context.l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            label: context.l10n.trips,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: context.l10n.account,
          ),
        ],
      ),
    );
  }
}
