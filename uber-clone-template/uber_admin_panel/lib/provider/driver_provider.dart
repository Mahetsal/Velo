import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DriverProvider with ChangeNotifier {
  Future<void> issueWalletBalance({
    required String driverId,
    required double amount,
    required String reason,
  }) async {
    final driverRes = await http.get(
      Uri.parse("$_awsApiBaseUrl/drivers/$driverId"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (driverRes.statusCode != 200) {
      throw Exception("Failed to load driver.");
    }
    final payload = jsonDecode(driverRes.body) as Map<String, dynamic>;
    if ((payload["exists"] ?? false) != true || payload["item"] == null) {
      throw Exception("Driver not found.");
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
      Uri.parse("$_awsApiBaseUrl/drivers/$driverId"),
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

  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";

  Future<void> createDriverManually({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String vehicleType,
  }) async {
    final existingUserPhone = await http.get(Uri.parse(
        "$_awsApiBaseUrl/users/by-phone/${Uri.encodeComponent(phoneNumber.trim())}"));
    if (existingUserPhone.statusCode == 200 &&
        (jsonDecode(existingUserPhone.body)["exists"] ?? false) == true) {
      throw Exception("Phone already exists in users.");
    }
    final existingDriverPhone = await http.get(Uri.parse(
        "$_awsApiBaseUrl/drivers/by-phone/${Uri.encodeComponent(phoneNumber.trim())}"));
    if (existingDriverPhone.statusCode == 200 &&
        (jsonDecode(existingDriverPhone.body)["exists"] ?? false) == true) {
      throw Exception("Phone already exists in drivers.");
    }

    final now = DateTime.now();
    final names = fullName.trim().split(" ");
    final firstName = names.isNotEmpty ? names.first : fullName.trim();
    final secondName = names.length > 1 ? names.sublist(1).join(" ") : "";

    final id = now.millisecondsSinceEpoch.toString();
    await http.post(Uri.parse("$_awsApiBaseUrl/drivers"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode({
      "id": id,
      "firstName": firstName,
      "secondName": secondName,
      "email": email.trim(),
      "phoneNumber": phoneNumber.trim(),
      "address": "",
      "dob": "",
      "profilePicture": "",
      "cnicNumber": "",
      "cnicFrontImage": "",
      "cnicBackImage": "",
      "driverFaceWithCnic": "",
      "drivingLicenseNumber": "",
      "drivingLicenseFrontImage": "",
      "drivingLicenseBackImage": "",
      "blockStatus": "no",
      "activeStatus": "active",
      "approvalStatus": "approved",
      "approvedAt": now.toIso8601String(),
      "deviceToken": "",
      "earnings": "0",
      "driverRattings": "0",
      "vehicleInfo": {
        "type": vehicleType,
        "brand": "",
        "color": "",
        "productionYear": "",
        "vehiclePicture": "",
        "registrationPlateNumber": "",
        "registrationCertificateFrontImage": "",
        "registrationCertificateBackImage": "",
      },
      "monthlySubscription": {
        "isActive": true,
        "plan": "monthly",
        "status": "paid",
        "paymentMethod": "cash",
        "startDate": now.toIso8601String(),
        "lastPaymentDate": now.toIso8601String(),
        "nextDueDate": now.add(const Duration(days: 30)).toIso8601String(),
      },
    }));

    notifyListeners();
  }

  Future<void> setDriverActiveStatus(String driverId, bool isActive) async {
    await http.put(Uri.parse("$_awsApiBaseUrl/drivers/$driverId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode({
      "blockStatus": isActive ? "no" : "yes",
      "activeStatus": isActive ? "active" : "inactive",
    }));
    notifyListeners();
  }

  Future<void> setDriverApprovalStatus(String driverId, bool isApproved) async {
    await http.put(Uri.parse("$_awsApiBaseUrl/drivers/$driverId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode({
      "approvalStatus": isApproved ? "approved" : "pending",
      "approvedAt": isApproved ? DateTime.now().toIso8601String() : null,
    }));
    notifyListeners();
  }

  // Method to update block status (block/unblock)
  Future<void> toggleBlockStatus(String driverId, String currentStatus) async {
    // Toggle between "yes" and "no"
    String newStatus = currentStatus == "no" ? "yes" : "no";

    await http.put(Uri.parse("$_awsApiBaseUrl/drivers/$driverId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode({
      "blockStatus": newStatus,
      "activeStatus": newStatus == "no" ? "active" : "inactive",
    }));

    notifyListeners(); // Notify listeners to rebuild the UI
  }

  Future<void> startMonthlySubscriptionCash(String driverId) async {
    final now = DateTime.now();
    final nextDueDate = now.add(const Duration(days: 30));
    await http.put(Uri.parse("$_awsApiBaseUrl/drivers/$driverId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode({"monthlySubscription": {
      "isActive": true,
      "plan": "monthly",
      "status": "paid",
      "paymentMethod": "cash",
      "startDate": now.toIso8601String(),
      "lastPaymentDate": now.toIso8601String(),
      "nextDueDate": nextDueDate.toIso8601String(),
    }}));
    notifyListeners();
  }

  Future<void> stopMonthlySubscription(String driverId) async {
    await http.put(Uri.parse("$_awsApiBaseUrl/drivers/$driverId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode({"monthlySubscription": {
      "isActive": false,
      "status": "inactive",
    }}));
    notifyListeners(); // Notify listeners to rebuild the UI
  }

  Future<void> bulkSetDriverActiveStatus(
      List<String> driverIds, bool isActive) async {
    for (final id in driverIds) {
      await http.put(Uri.parse("$_awsApiBaseUrl/drivers/$id"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
          body: jsonEncode({
            "blockStatus": isActive ? "no" : "yes",
            "activeStatus": isActive ? "active" : "inactive",
          }));
    }
    notifyListeners();
  }

  Future<void> bulkSetDriverApprovalStatus(
      List<String> driverIds, bool isApproved) async {
    for (final id in driverIds) {
      await http.put(Uri.parse("$_awsApiBaseUrl/drivers/$id"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
          body: jsonEncode({
            "approvalStatus": isApproved ? "approved" : "pending",
            "approvedAt": isApproved ? DateTime.now().toIso8601String() : null,
          }));
    }
    notifyListeners();
  }

  Future<void> bulkSetDriverSubscriptionStatus(
      List<String> driverIds, bool isActive) async {
    final now = DateTime.now();
    for (final id in driverIds) {
      await http.put(Uri.parse("$_awsApiBaseUrl/drivers/$id"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
          body: jsonEncode({
            "monthlySubscription": {
              "isActive": isActive,
              "plan": "monthly",
              "status": isActive ? "paid" : "inactive",
              "paymentMethod": isActive ? "cash" : "",
              "startDate": isActive ? now.toIso8601String() : "",
              "lastPaymentDate": isActive ? now.toIso8601String() : "",
              "nextDueDate": isActive
                  ? now.add(const Duration(days: 30)).toIso8601String()
                  : "",
            }
          }));
    }
    notifyListeners();
  }
}
