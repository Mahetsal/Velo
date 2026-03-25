import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GodModePage extends StatefulWidget {
  static const String id = "/godModePage";

  const GodModePage({super.key});

  @override
  State<GodModePage> createState() => _GodModePageState();
}

class _GodModePageState extends State<GodModePage> {
  late Future<List<Map<String, dynamic>>> _rowsFuture;

  @override
  void initState() {
    super.initState();
    _rowsFuture = _fetchGodModeRows();
  }

  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  static const String _firebaseBaseUrl =
      "https://everyone-2de50-default-rtdb.firebaseio.com";

  Future<List<Map<String, dynamic>>> _fetchGodModeRows() async {
    final driversResponse = await http.get(
      Uri.parse("$_awsApiBaseUrl/drivers"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    final onlineDriversResponse =
        await http.get(Uri.parse("$_firebaseBaseUrl/onlineDrivers.json"));

    if (driversResponse.statusCode != 200) return [];

    final driversPayload = jsonDecode(driversResponse.body) as Map<String, dynamic>;
    final items = (driversPayload["items"] as List<dynamic>? ?? []);
    final drivers = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final Map<String, dynamic> onlineDriversMap =
        (onlineDriversResponse.statusCode == 200 &&
                onlineDriversResponse.body.trim().isNotEmpty &&
                onlineDriversResponse.body.trim() != "null")
            ? Map<String, dynamic>.from(
                jsonDecode(onlineDriversResponse.body) as Map,
              )
            : <String, dynamic>{};

    final rows = <Map<String, dynamic>>[];
    for (final driver in drivers) {
      final id = driver["id"]?.toString() ?? "";
      if (id.isEmpty) continue;
      final bool isBlocked = (driver["blockStatus"]?.toString() ?? "no") != "no";
      final bool isApproved =
          (driver["approvalStatus"]?.toString() ?? "pending") == "approved";
      final online = onlineDriversMap[id];
      final bool isOnline = online != null;
      final double? lat = online == null ? null : double.tryParse("${online["l"][0]}");
      final double? lng = online == null ? null : double.tryParse("${online["l"][1]}");

      if (!isBlocked && isApproved && isOnline) {
        rows.add({
          "id": id,
          "name":
              "${driver["firstName"] ?? ""} ${driver["secondName"] ?? ""}".trim(),
          "phone": driver["phoneNumber"]?.toString() ?? "-",
          "vehicle": ((driver["vehicleInfo"] ?? {})["type"] ?? "-").toString(),
          "lat": lat,
          "lng": lng,
        });
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _rowsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Failed to load god mode data."));
            }
            final rows = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "God Mode",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "Live active drivers: ${rows.length}",
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rowsFuture = _fetchGodModeRows();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Live Data"),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(
                          child: Text("No active online drivers right now."),
                        )
                      : ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return Card(
                              child: ListTile(
                                title: Text(row["name"].toString().isEmpty
                                    ? "Unnamed Driver"
                                    : row["name"].toString()),
                                subtitle: Text(
                                  "ID: ${row["id"]} | ${row["vehicle"]} | ${row["phone"]}",
                                ),
                                trailing: Text(
                                  "${((row["lat"] as double?) ?? 0.0).toStringAsFixed(5)}, ${((row["lng"] as double?) ?? 0.0).toStringAsFixed(5)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
