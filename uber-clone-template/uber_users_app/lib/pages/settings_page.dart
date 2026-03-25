import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _languageKey = "app_language";
  static const String _notificationsKey = "notifications_enabled";
  static const String _defaultPaymentKey = "default_payment_method";

  bool _loading = true;
  String _language = "en";
  bool _notificationsEnabled = true;
  String _defaultPaymentMethod = "Cash";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _language = prefs.getString(_languageKey) ?? "en";
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      final method = prefs.getString(_defaultPaymentKey) ?? "Cash";
      _defaultPaymentMethod = (method == "Wallet") ? "Wallet" : "Cash";
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _language);
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
    await prefs.setString(_defaultPaymentKey, _defaultPaymentMethod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "App Preferences",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_outlined),
                  title: const Text("Language"),
                  subtitle: const Text("English or Arabic"),
                  trailing: DropdownButton<String>(
                    value: _language,
                    items: const [
                      DropdownMenuItem(value: "en", child: Text("English")),
                      DropdownMenuItem(value: "ar", child: Text("Arabic")),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _language = value);
                      await _save();
                    },
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Notifications"),
                  subtitle: const Text("Trip updates and service alerts"),
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _notificationsEnabled = value);
                    await _save();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text("Default payment method"),
                  trailing: DropdownButton<String>(
                    value: _defaultPaymentMethod,
                    items: const [
                      DropdownMenuItem(value: "Cash", child: Text("Cash")),
                      DropdownMenuItem(value: "Wallet", child: Text("Wallet")),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _defaultPaymentMethod = value);
                      await _save();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Note: Language selection is saved now and ready for full translation rollout.",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
    );
  }
}
