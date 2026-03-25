import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms & Conditions")),
      body: FutureBuilder<http.Response>(
        future: http.get(
          Uri.parse("$_awsApiBaseUrl/settings/legal_terms"),
          headers: {"Authorization": "Bearer public-migration-token"},
        ),
        builder: (context, snapshot) {
          String content = "Terms not available.";
          if (snapshot.hasData && snapshot.data!.statusCode == 200) {
            try {
              final payload =
                  jsonDecode(snapshot.data!.body) as Map<String, dynamic>;
              final item = (payload["item"] ?? {}) as Map;
              content = item["content"]?.toString() ?? content;
            } catch (_) {}
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          );
        },
      ),
    );
  }
}
