import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/pages/about_page.dart';
import 'package:uber_users_app/pages/promo_page.dart';
import 'package:uber_users_app/pages/settings_page.dart';
import 'package:uber_users_app/pages/support_page.dart';
import 'package:uber_users_app/pages/terms_page.dart';
import 'package:uber_users_app/pages/trips_history_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  String _defaultPaymentMethod = "Cash";
  String _defaultPromoCode = "";

  @override
  void initState() {
    super.initState();
    _loadLocalPrefs();
  }

  Future<void> _loadLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _defaultPaymentMethod = prefs.getString("default_payment_method") ?? "Cash";
      _defaultPromoCode = prefs.getString("default_promo_code") ?? "";
    });
  }

  Future<void> _setDefaultPayment(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("default_payment_method", method);
    if (!mounted) return;
    setState(() => _defaultPaymentMethod = method);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Default payment changed to $method.")),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName.isEmpty ? "Velo Customer" : userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEEF2FF),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
          title: const Text("Account"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Profile"),
              Tab(text: "Payments"),
              Tab(text: "Promos"),
              Tab(text: "Settings"),
              Tab(text: "Help"),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _headerCard(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ProfileTab(onOpenHistory: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TripsHistoryPage()),
                    );
                  }),
                  _PaymentsTab(
                    awsApiBaseUrl: _awsApiBaseUrl,
                    defaultPaymentMethod: _defaultPaymentMethod,
                    onSetDefaultPayment: _setDefaultPayment,
                  ),
                  _PromosTab(
                    defaultPromoCode: _defaultPromoCode,
                    onOpenPromo: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PromoPage()),
                      );
                      _loadLocalPrefs();
                    },
                  ),
                  _SettingsTab(),
                  _HelpTab(),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final VoidCallback onOpenHistory;
  const _ProfileTab({required this.onOpenHistory});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(userName.isEmpty ? "No name yet" : userName),
            subtitle: Text(userPhone),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text("Email"),
            subtitle: Text(userEmail.isEmpty ? "No email yet" : userEmail),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Trip history"),
            subtitle: const Text("View all completed rides"),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenHistory,
          ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final String awsApiBaseUrl;
  final String defaultPaymentMethod;
  final ValueChanged<String> onSetDefaultPayment;
  const _PaymentsTab({
    required this.awsApiBaseUrl,
    required this.defaultPaymentMethod,
    required this.onSetDefaultPayment,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse("$awsApiBaseUrl/users/$userID"),
            headers: {"Authorization": "Bearer public-migration-token"},
          ),
          builder: (_, snapshot) {
            String walletText = "JOD 0.00";
            if (snapshot.hasData && snapshot.data!.statusCode == 200) {
              try {
                final payload =
                    jsonDecode(snapshot.data!.body) as Map<String, dynamic>;
                final item = (payload["item"] ?? {}) as Map;
                final walletRaw = item["walletBalance"]?.toString() ?? "0";
                final wallet = double.tryParse(walletRaw) ?? 0;
                walletText = "JOD ${wallet.toStringAsFixed(2)}";
              } catch (_) {}
            }
            return Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text("Wallet Balance"),
                subtitle: Text(walletText),
              ),
            );
          },
        ),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                value: "Cash",
                groupValue: defaultPaymentMethod,
                onChanged: (v) {
                  if (v != null) onSetDefaultPayment(v);
                },
                title: const Text("Cash"),
              ),
              RadioListTile<String>(
                value: "Wallet",
                groupValue: defaultPaymentMethod,
                onChanged: (v) {
                  if (v != null) onSetDefaultPayment(v);
                },
                title: const Text("Wallet"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromosTab extends StatelessWidget {
  final String defaultPromoCode;
  final VoidCallback onOpenPromo;
  const _PromosTab({
    required this.defaultPromoCode,
    required this.onOpenPromo,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_offer_outlined),
            title: const Text("Default promo code"),
            subtitle: Text(
              defaultPromoCode.isEmpty ? "No promo saved" : defaultPromoCode,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenPromo,
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text("Auto-apply enabled"),
            subtitle: Text(
              "Saved promo is applied automatically on the next trip quote.",
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text("App Settings"),
            subtitle: const Text("Language, notifications and defaults"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text("Terms & Conditions"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsPage()),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About Velo"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HelpTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text("Support Center"),
            subtitle: const Text("Call, WhatsApp and email support"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportPage()),
              );
            },
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.safety_check_outlined),
            title: Text("Safety"),
            subtitle: Text("Use live support immediately for urgent trip issues."),
          ),
        ),
      ],
    );
  }
}
