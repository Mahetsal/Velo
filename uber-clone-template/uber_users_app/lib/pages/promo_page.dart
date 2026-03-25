import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/global/global_var.dart';

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  final TextEditingController _promoController = TextEditingController();
  bool _saving = false;
  String _status = "";

  @override
  void initState() {
    super.initState();
    _loadPromo();
  }

  Future<void> _loadPromo() async {
    final prefs = await SharedPreferences.getInstance();
    _promoController.text = prefs.getString("default_promo_code") ?? "";
  }

  Future<void> _savePromo() async {
    final code = _promoController.text.trim().toUpperCase();
    setState(() {
      _saving = true;
      _status = "";
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("default_promo_code", code);

    // Best effort save to profile on backend if endpoint supports extra fields.
    try {
      await http.put(
        Uri.parse("$_awsApiBaseUrl/users/$userID"),
        headers: {
          "Authorization": "Bearer public-migration-token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"defaultPromoCode": code}),
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _saving = false;
      _status = code.isEmpty
          ? "Default promo cleared."
          : "Default promo saved. It will auto-apply on next trips.";
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Promotions")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set your default promo code once. Velo will auto-apply it on your next trip quote.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promoController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Promo code",
                hintText: "e.g. VELO10",
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _savePromo,
                child: Text(_saving ? "Saving..." : "Save Promo"),
              ),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _status,
                style: const TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
