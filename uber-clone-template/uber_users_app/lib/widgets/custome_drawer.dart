import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/pages/account_page.dart';
import 'package:uber_users_app/pages/about_page.dart';
import 'package:uber_users_app/pages/promo_page.dart';
import 'package:uber_users_app/pages/settings_page.dart';
import 'package:uber_users_app/pages/support_page.dart';
import 'package:uber_users_app/pages/terms_page.dart';
import 'package:uber_users_app/pages/trips_history_page.dart';
import 'package:uber_users_app/widgets/sign_out_dialog.dart';

class CustomDrawer extends StatelessWidget {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  final String userName;
  final AuthenticationProvider authProvider;

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.authProvider,
  });

  Future<String> _fetchWalletBalance() async {
    if (userID.isEmpty) return "0.00";
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/users/$userID"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return "0.00";
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final item = (payload["item"] ?? {}) as Map;
    final wallet = double.tryParse(item["walletBalance"]?.toString() ?? "0") ?? 0;
    return wallet.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<String>(
            future: _fetchWalletBalance(),
            builder: (_, snapshot) {
              final wallet = snapshot.data ?? "0.00";
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage("assets/images/avatarman.png"),
                ),
                accountName: Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                accountEmail: Text(
                  "$userEmail\nWallet: JOD $wallet\nAlways 5% cheaper fares",
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_box, color: Colors.black),
            title: const Text("Account", style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.black),
            title: const Text("History", style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TripsHistoryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer, color: Colors.black),
            title: const Text("Promotions", style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PromoPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.black),
            title: const Text("About", style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: Colors.black),
            title: const Text("Support", style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.black),
            title: const Text("Settings", style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.black),
            title: const Text("Terms & Conditions",
                style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black),
            title: const Text("Logout", style: TextStyle(color: Colors.black)),
            onTap: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SignOutDialog(
                    title: 'Logout',
                    description: 'Are you sure you want to logout?',
                    onSignOut: () async {
                      await authProvider.signOut(context);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
