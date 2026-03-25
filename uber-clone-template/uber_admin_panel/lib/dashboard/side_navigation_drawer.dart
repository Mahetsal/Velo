import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:uber_admin_panel/core/admin_session.dart';
import 'package:uber_admin_panel/dashboard/dashboard.dart';
import 'package:uber_admin_panel/pages/driver_page.dart';
import 'package:uber_admin_panel/pages/trips_page.dart';
import 'package:uber_admin_panel/pages/user_page.dart';
import 'package:uber_admin_panel/pages/earnings_page.dart';
import 'package:uber_admin_panel/pages/god_mode_page.dart';
import 'package:uber_admin_panel/pages/admin_tools_page.dart';
import 'package:uber_admin_panel/pages/promo_management_page.dart';
import 'package:uber_admin_panel/pages/legal_compliance_page.dart';

class SideNavigationDrawer extends StatefulWidget {
  const SideNavigationDrawer({super.key});

  @override
  State<SideNavigationDrawer> createState() => _SideNavigationDrawerState();
}

class _SideNavigationDrawerState extends State<SideNavigationDrawer> {
  Widget chosenScreen = const Dashboard();
  String _selectedRoute = Dashboard.id;

  void sendAdminTo(AdminMenuItem selectedPage) {
    switch (selectedPage.route) {
      case Dashboard.id:
        setState(() {
          chosenScreen = const Dashboard();
          _selectedRoute = Dashboard.id;
        });
        break;
      case DriverPage.id:
        setState(() {
          chosenScreen = const DriverPage();
          _selectedRoute = DriverPage.id;
        });
        break;
      case UserPage.id:
        setState(() {
          chosenScreen = const UserPage();
          _selectedRoute = UserPage.id;
        });
        break;
      case TripsPage.id:
        setState(() {
          chosenScreen = const TripsPage();
          _selectedRoute = TripsPage.id;
        });
        break;
      case EarningsPage.id:
        setState(() {
          chosenScreen = const EarningsPage();
          _selectedRoute = EarningsPage.id;
        });
        break;
      case GodModePage.id:
        setState(() {
          chosenScreen = const GodModePage();
          _selectedRoute = GodModePage.id;
        });
        break;
      case AdminToolsPage.id:
        setState(() {
          chosenScreen = const AdminToolsPage();
          _selectedRoute = AdminToolsPage.id;
        });
        break;
      case PromoManagementPage.id:
        setState(() {
          chosenScreen = const PromoManagementPage();
          _selectedRoute = PromoManagementPage.id;
        });
        break;
      case LegalCompliancePage.id:
        setState(() {
          chosenScreen = const LegalCompliancePage();
          _selectedRoute = LegalCompliancePage.id;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color(0xFF121E38),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF1E3A8A),
              child: Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
            ),
            SizedBox(width: 10),
            Text(
              "Velo Admin",
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Chip(
                label: Text("Live Ops"),
                backgroundColor: Color(0xFF1E3A8A),
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      sideBar: SideBar(
        backgroundColor: const Color(0xFF0F172A),
        textStyle: const TextStyle(color: Colors.white70),
        activeBackgroundColor: const Color(0xFF1E3A8A),
        activeTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        header: Container(
          height: 86,
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0x223B82F6)),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF1D4ED8),
                  child: Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 18),
                ),
                SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Admin Console",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "Control center",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        items: const [
          AdminMenuItem(
            title: "Dashboard",
            route: Dashboard.id,
            icon: CupertinoIcons.desktopcomputer,
          ),
          AdminMenuItem(
            title: "Drivers",
            route: DriverPage.id,
            icon: CupertinoIcons.car_detailed,
          ),
          AdminMenuItem(
            title: "Users",
            route: UserPage.id,
            icon: CupertinoIcons.person_2_fill,
          ),
          AdminMenuItem(
            title: "Trips",
            route: TripsPage.id,
            icon: CupertinoIcons.location_fill,
          ),
          AdminMenuItem(
            title: "Earnings",
            route: EarningsPage.id,
            icon: CupertinoIcons.money_dollar,
          ),
          AdminMenuItem(
            title: "God Mode",
            route: GodModePage.id,
            icon: CupertinoIcons.scope,
          ),
          AdminMenuItem(
            title: "Admin Tools",
            route: AdminToolsPage.id,
            icon: CupertinoIcons.settings_solid,
          ),
          AdminMenuItem(
            title: "Promos",
            route: PromoManagementPage.id,
            icon: CupertinoIcons.tag,
          ),
          AdminMenuItem(
            title: "Legal",
            route: LegalCompliancePage.id,
            icon: CupertinoIcons.doc_text,
          ),
        ],
        selectedRoute: _selectedRoute,
        onSelected: (itemSelected) {
          sendAdminTo(itemSelected);
        },
        footer: Column(
          children: [
            TextButton.icon(
              onPressed: () async {
                await AdminSession.clear();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, "/login");
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: chosenScreen,
    );
  }
}
