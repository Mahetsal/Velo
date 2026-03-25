import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserProvider with ChangeNotifier {
  Future<void> issueWalletBalance({
    required String userId,
    required double amount,
    required String reason,
  }) async {
    final userRes = await http.get(
      Uri.parse("$_awsApiBaseUrl/users/$userId"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (userRes.statusCode != 200) {
      throw Exception("Failed to load user.");
    }
    final payload = jsonDecode(userRes.body) as Map<String, dynamic>;
    if ((payload["exists"] ?? false) != true || payload["item"] == null) {
      throw Exception("User not found.");
    }
    final item = Map<String, dynamic>.from(payload["item"] as Map);
    final currentBalance =
        double.tryParse(item["walletBalance"]?.toString() ?? "0") ?? 0.0;
    final nextBalance = currentBalance + amount;
    final txs = List<Map<String, dynamic>>.from(
      ((item["walletTransactions"] ?? []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    txs.insert(0, {
      "type": "credit",
      "amount": amount.toStringAsFixed(2),
      "reason": reason,
      "issuedBy": "admin",
      "createdAt": DateTime.now().toIso8601String(),
    });
    await http.put(
      Uri.parse("$_awsApiBaseUrl/users/$userId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer public-migration-token"
      },
      body: jsonEncode({
        "walletBalance": nextBalance.toStringAsFixed(2),
        "walletTransactions": txs,
      }),
    );
    notifyListeners();
  }

  Future<void> createPromoCode({
    required String code,
    required String description,
    required String discountType,
    required String discountValue,
    String? maxDiscountAmount,
    required String validTillIso,
    required String scope,
  }) async {
    final promoId = DateTime.now().millisecondsSinceEpoch.toString();
    final response = await http.post(
      Uri.parse("$_awsApiBaseUrl/promos"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer public-migration-token"
      },
      body: jsonEncode({
        "id": promoId,
        "code": code.trim().toUpperCase(),
        "description": description.trim(),
        "discountType": discountType,
        "discountValue": discountValue,
        "maxDiscountAmount": (maxDiscountAmount ?? "").trim().isEmpty
            ? "0"
            : maxDiscountAmount!.trim(),
        "scope": scope,
        "validFrom": DateTime.now().toIso8601String(),
        "validTill": validTillIso,
        "isActive": true,
        "usageLimit": 0,
        "usedCount": 0,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to create promo code.");
    }
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchPromos() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/promos"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return [];
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload["items"] as List<dynamic>? ?? []);
    return items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((p) => p["deleted"] != true)
        .toList();
  }

  Future<void> updatePromo(String promoId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$_awsApiBaseUrl/promos/$promoId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer public-migration-token"
      },
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to update promo.");
    }
    notifyListeners();
  }

  Future<void> deletePromo(String promoId) async {
    final response = await http.delete(
      Uri.parse("$_awsApiBaseUrl/promos/$promoId"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to delete promo.");
    }
    notifyListeners();
  }

  Future<void> bulkAssignPromoTarget({
    required String promoCode,
    required String targetType,
    String specificUserIdsCsv = "",
  }) async {
    final promos = await fetchPromos();
    final promo = promos.firstWhere(
      (p) => (p["code"]?.toString().toUpperCase() ?? "") == promoCode.toUpperCase(),
      orElse: () => <String, dynamic>{},
    );
    if (promo.isEmpty) {
      throw Exception("Promo not found.");
    }
    List<String> eligible = [];
    if (targetType == "specific") {
      eligible = specificUserIdsCsv
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (targetType == "new_users") {
      final usersResp = await http.get(
        Uri.parse("$_awsApiBaseUrl/users"),
        headers: {"Authorization": "Bearer public-migration-token"},
      );
      if (usersResp.statusCode == 200) {
        final usersPayload = jsonDecode(usersResp.body) as Map<String, dynamic>;
        final users = (usersPayload["items"] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        for (final user in users) {
          final uid = user["id"]?.toString() ?? "";
          if (uid.isEmpty) continue;
          final tripsResp = await http.get(
            Uri.parse("$_awsApiBaseUrl/trips/by-user/$uid"),
            headers: {"Authorization": "Bearer public-migration-token"},
          );
          if (tripsResp.statusCode != 200) continue;
          final tripsPayload = jsonDecode(tripsResp.body) as Map<String, dynamic>;
          final trips = (tripsPayload["items"] as List<dynamic>? ?? []);
          if (trips.isEmpty) eligible.add(uid);
        }
      }
    }
    await updatePromo(
      promo["id"].toString(),
      {
        "targetType": targetType,
        "eligibleUserIds": eligible,
      },
    );
  }

  Future<String> buildWalletTransactionsCsv() async {
    final usersResp = await http.get(
      Uri.parse("$_awsApiBaseUrl/users"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    final driversResp = await http.get(
      Uri.parse("$_awsApiBaseUrl/drivers"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (usersResp.statusCode != 200 || driversResp.statusCode != 200) {
      throw Exception("Failed to fetch wallets.");
    }
    final users = (jsonDecode(usersResp.body)["items"] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final drivers = (jsonDecode(driversResp.body)["items"] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final rows = <String>[
      "entityType,entityId,nameOrEmail,txType,amount,reason,issuedBy,createdAt"
    ];
    for (final u in users) {
      final txs = (u["walletTransactions"] as List?) ?? [];
      for (final raw in txs) {
        final tx = Map<String, dynamic>.from(raw as Map);
        rows.add(
          "user,${u["id"] ?? ""},${(u["email"] ?? "").toString().replaceAll(',', ' ')},${tx["type"] ?? ""},${tx["amount"] ?? ""},${(tx["reason"] ?? "").toString().replaceAll(',', ' ')},${tx["issuedBy"] ?? ""},${tx["createdAt"] ?? ""}",
        );
      }
    }
    for (final d in drivers) {
      final txs = (d["walletTransactions"] as List?) ?? [];
      for (final raw in txs) {
        final tx = Map<String, dynamic>.from(raw as Map);
        rows.add(
          "driver,${d["id"] ?? ""},${((d["firstName"] ?? "").toString() + " " + (d["secondName"] ?? "").toString()).replaceAll(',', ' ')},${tx["type"] ?? ""},${tx["amount"] ?? ""},${(tx["reason"] ?? "").toString().replaceAll(',', ' ')},${tx["issuedBy"] ?? ""},${tx["createdAt"] ?? ""}",
        );
      }
    }
    return rows.join("\n");
  }

  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";

  Future<void> setUserActiveStatus(String userId, bool isActive) async {
    await http.put(Uri.parse("$_awsApiBaseUrl/users/$userId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode({
      "blockStatus": isActive ? "no" : "yes",
      "activeStatus": isActive ? "active" : "inactive",
    }));
    notifyListeners();
  }

  // Method to update block status (block/unblock)
  Future<void> toggleBlockStatus(String userId, String currentStatus) async {
    // Toggle between "yes" and "no"
    String newStatus = currentStatus == "no" ? "yes" : "no";

    await http.put(Uri.parse("$_awsApiBaseUrl/users/$userId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode({
      "blockStatus": newStatus,
      "activeStatus": newStatus == "no" ? "active" : "inactive",
    }));

    notifyListeners(); // Notify listeners to rebuild the UI
  }

  Future<void> bulkSetUserActiveStatus(List<String> userIds, bool isActive) async {
    for (final id in userIds) {
      await http.put(Uri.parse("$_awsApiBaseUrl/users/$id"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
          body: jsonEncode({
            "blockStatus": isActive ? "no" : "yes",
            "activeStatus": isActive ? "active" : "inactive",
          }));
    }
    notifyListeners();
  }
}
