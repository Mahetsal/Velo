import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserDataScreen extends StatefulWidget {
  final String userId;
  const UserDataScreen({super.key, required this.userId});

  @override
  State<UserDataScreen> createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";

  Future<Map<String, dynamic>?> _fetchUser() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/users/${widget.userId}"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return null;
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if ((payload["exists"] ?? false) != true || payload["item"] == null) {
      return null;
    }
    return Map<String, dynamic>.from(payload["item"] as Map);
  }

  Future<List<Map<String, dynamic>>> _fetchUserTrips() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/trips/by-user/${widget.userId}"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return [];
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload["items"] as List<dynamic>? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rider Details & History")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUser(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = userSnap.data;
          if (user == null) {
            return const Center(child: Text("User not found."));
          }
          final wallet = user["walletBalance"]?.toString() ?? "0";
          final txs = (user["walletTransactions"] as List?) ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: ${user["name"] ?? "-"}"),
                Text("Email: ${user["email"] ?? "-"}"),
                Text("Phone: ${user["phone"] ?? "-"}"),
                const SizedBox(height: 8),
                Text(
                  "Wallet: JOD $wallet",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Wallet History",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...txs.take(10).map(
                      (e) => ListTile(
                        dense: true,
                        title: Text(
                          "JOD ${(e as Map)["amount"] ?? "0"} - ${e["reason"] ?? "-"}",
                        ),
                        subtitle: Text("${e["createdAt"] ?? ""}"),
                      ),
                    ),
                const Divider(height: 24),
                const Text(
                  "Trip History",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchUserTrips(),
                  builder: (context, tripsSnap) {
                    if (tripsSnap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      );
                    }
                    final trips = tripsSnap.data ?? [];
                    if (trips.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text("No trips yet."),
                      );
                    }
                    return Column(
                      children: trips.take(20).map((trip) {
                        return Card(
                          child: ListTile(
                            title: Text("Trip ${trip["tripID"] ?? trip["id"]}"),
                            subtitle: Text(
                              "${trip["status"] ?? "-"} | ${trip["publishDateTime"] ?? "-"}",
                            ),
                            trailing: Text(
                              "JOD ${trip["fareAmount"] ?? "0"}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
