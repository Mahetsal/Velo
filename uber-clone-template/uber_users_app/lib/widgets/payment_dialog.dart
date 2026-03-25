import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentDialog extends StatefulWidget {
  final String fareAmount;
  final String tripId;
  final String userId;
  final String preferredPaymentMethod;
  final String promoCode;

  PaymentDialog({
    super.key,
    required this.fareAmount,
    required this.tripId,
    required this.userId,
    required this.preferredPaymentMethod,
    required this.promoCode,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 21),
            const Text(
              "Trip Payment",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 21),
            const Divider(height: 1.5, color: Colors.black54, thickness: 1.0),
            const SizedBox(height: 16),
            Text(
              "JOD ${widget.fareAmount}",
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "This is fare amount ( JOD ${widget.fareAmount} ) you have to pay to the driver.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Velo applies a built-in 5% rider discount versus comparable market fares.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 31),
            if (widget.preferredPaymentMethod == "Cash") ...[
              ElevatedButton(
                onPressed: () async {
                  await _markTripPayment("Cash");
                  await _consumePromoIfAny();
                  if (mounted) Navigator.pop(context, "paid");
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text("PAY WITH CASH",
                    style: TextStyle(color: Colors.white)),
              ),
            ] else if (widget.preferredPaymentMethod == "Wallet") ...[
              ElevatedButton(
                onPressed: () async {
                  await payWithWallet();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text("PAY WITH WALLET",
                    style: TextStyle(color: Colors.white)),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Only Cash and Wallet are currently supported.",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 41),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, "paid");
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 31),
          ],
        ),
      ),
    );
  }

  Future<void> payWithWallet() async {
    try {
      final amount = double.tryParse(widget.fareAmount) ?? 0.0;
      final userRes = await http.get(
        Uri.parse("$_awsApiBaseUrl/users/${widget.userId}"),
        headers: {"Authorization": "Bearer public-migration-token"},
      );
      if (userRes.statusCode != 200) {
        throw Exception("Failed to load wallet.");
      }
      final payload = jsonDecode(userRes.body) as Map<String, dynamic>;
      if ((payload["exists"] ?? false) != true || payload["item"] == null) {
        throw Exception("User not found.");
      }
      final user = Map<String, dynamic>.from(payload["item"] as Map);
      final currentBalance =
          double.tryParse(user["walletBalance"]?.toString() ?? "0") ?? 0.0;
      if (currentBalance < amount) {
        throw Exception("Insufficient wallet balance.");
      }
      final nextBalance = currentBalance - amount;
      final txs = List<Map<String, dynamic>>.from(
        ((user["walletTransactions"] ?? []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      txs.insert(0, {
        "type": "debit",
        "amount": amount.toStringAsFixed(2),
        "reason": "Trip payment ${widget.tripId}",
        "issuedBy": "system",
        "createdAt": DateTime.now().toIso8601String(),
      });
      await http.put(
        Uri.parse("$_awsApiBaseUrl/users/${widget.userId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer public-migration-token",
        },
        body: jsonEncode({
          "walletBalance": nextBalance.toStringAsFixed(2),
          "walletTransactions": txs,
        }),
      );
      await _markTripPayment("Wallet");
      await _consumePromoIfAny();
      if (mounted) {
        Navigator.pop(context, "paid");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _markTripPayment(String method) async {
    if (widget.tripId.isEmpty) return;
    await http.put(
      Uri.parse("$_awsApiBaseUrl/trips/${widget.tripId}"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer public-migration-token",
      },
      body: jsonEncode({
        "paymentMethod": method,
        "paymentStatus": "paid",
        "paidAt": DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<void> _consumePromoIfAny() async {
    final code = widget.promoCode.trim();
    if (code.isEmpty) return;
    await http.post(
      Uri.parse("$_awsApiBaseUrl/promos/consume"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer public-migration-token",
      },
      body: jsonEncode({
        "code": code,
        "userId": widget.userId,
      }),
    );
  }
}
