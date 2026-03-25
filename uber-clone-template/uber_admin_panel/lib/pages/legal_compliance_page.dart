import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LegalCompliancePage extends StatefulWidget {
  static const String id = "/legalCompliance";
  const LegalCompliancePage({super.key});

  @override
  State<LegalCompliancePage> createState() => _LegalCompliancePageState();
}

class _LegalCompliancePageState extends State<LegalCompliancePage> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  final TextEditingController _version = TextEditingController(text: "1.0");
  final TextEditingController _content = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/settings/legal_terms"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return;
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final item = (payload["item"] ?? {}) as Map;
    if (!mounted) return;
    setState(() {
      _version.text = item["version"]?.toString().isNotEmpty == true
          ? item["version"].toString()
          : "1.0";
      _content.text = item["content"]?.toString() ?? _defaultTerms();
    });
  }

  String _defaultTerms() {
    return "Terms and Conditions\n\nTo the maximum extent permitted by law, "
        "the platform acts as a technology intermediary and disclaims liability "
        "for indirect, incidental, consequential, or punitive damages. "
        "All users and drivers are responsible for lawful and safe conduct.";
  }

  Future<void> _save() async {
    await http.put(
      Uri.parse("$_awsApiBaseUrl/settings/legal_terms"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer public-migration-token"
      },
      body: jsonEncode({
        "id": "legal_terms",
        "title": "Terms and Conditions",
        "version": _version.text.trim(),
        "content": _content.text,
        "updatedAt": DateTime.now().toIso8601String(),
      }),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Legal terms updated.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Legal Compliance",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _version,
              decoration: const InputDecoration(labelText: "Terms version"),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _content,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: "Terms content",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _save, child: const Text("Save Terms")),
          ],
        ),
      ),
    );
  }
}
