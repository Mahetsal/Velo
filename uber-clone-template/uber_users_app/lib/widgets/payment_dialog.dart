import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';

class PaymentDialog extends StatefulWidget {
  final String fareAmount;
  final String tripId;
  final String userId;
  final String preferredPaymentMethod;
  final String promoCode;

  const PaymentDialog({
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
            Text(
              context.l10n.tripPayment,
              style: const TextStyle(
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
                context.l10n.paymentYouPayDriver(widget.fareAmount),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                context.l10n.paymentBuiltInDiscount,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 31),
            if (widget.preferredPaymentMethod == "Cash") ...[
              Semantics(
                button: true,
                label: context.l10n.payWithCash,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await _markTripPayment("Cash");
                    await _consumePromoIfAny();
                    if (!context.mounted) return;
                    Navigator.pop(context, "paid");
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: Text(context.l10n.payWithCash,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ] else if (widget.preferredPaymentMethod == "Wallet") ...[
              Semantics(
                button: true,
                label: context.l10n.payWithWallet,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await payWithWallet();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: Text(context.l10n.payWithWallet,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.l10n.onlyCashWalletSupported,
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
              child: Text(context.l10n.ok, style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 31),
          ],
        ),
      ),
    );
  }

  Future<void> payWithWallet() async {
    final l10n = context.l10n;
    try {
      final amount = double.tryParse(widget.fareAmount) ?? 0.0;
      final userRes = await ApiClient.get("/users/${widget.userId}");
      if (userRes.statusCode != 200) {
        throw Exception(l10n.failedToLoadWallet);
      }
      final payload = jsonDecode(userRes.body) as Map<String, dynamic>;
      if ((payload["exists"] ?? false) != true || payload["item"] == null) {
        throw Exception(l10n.userNotFound);
      }
      final user = Map<String, dynamic>.from(payload["item"] as Map);
      final currentBalance =
          double.tryParse(user["walletBalance"]?.toString() ?? "0") ?? 0.0;
      if (currentBalance < amount) {
        throw Exception(l10n.insufficientWalletBalance);
      }
      final nextBalance = currentBalance - amount;
      final txs = List<Map<String, dynamic>>.from(
        ((user["walletTransactions"] ?? []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      txs.insert(0, {
        "type": "debit",
        "amount": amount.toStringAsFixed(2),
        "reason": l10n.walletTripPayment(widget.tripId),
        "issuedBy": "system",
        "createdAt": DateTime.now().toIso8601String(),
      });
      await ApiClient.put("/users/${widget.userId}", body: {
        "walletBalance": nextBalance.toStringAsFixed(2),
        "walletTransactions": txs,
      });
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
    await ApiClient.put("/trips/${widget.tripId}", body: {
      "paymentMethod": method,
      "paymentStatus": "paid",
      "paidAt": DateTime.now().toIso8601String(),
    });
  }

  Future<void> _consumePromoIfAny() async {
    final code = widget.promoCode.trim();
    if (code.isEmpty) return;
    await ApiClient.post("/promos/consume", body: {
      "code": code,
      "userId": widget.userId,
    });
  }
}
