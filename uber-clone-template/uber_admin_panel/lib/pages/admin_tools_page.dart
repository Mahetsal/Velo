import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uber_admin_panel/provider/driver_provider.dart';
import 'package:uber_admin_panel/provider/user_provider.dart';

class AdminToolsPage extends StatefulWidget {
  static const String id = "/adminToolsPage";
  const AdminToolsPage({super.key});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  final _promoCode = TextEditingController();
  final _promoDesc = TextEditingController();
  final _promoDiscount = TextEditingController(text: "10");
  final _promoMaxCap = TextEditingController();
  final _promoValidDays = TextEditingController(text: "30");

  final _walletUserId = TextEditingController();
  final _walletDriverId = TextEditingController();
  final _walletAmount = TextEditingController(text: "5");
  final _walletReason = TextEditingController(text: "Manual admin credit");
  final _targetPromoCode = TextEditingController();
  final _specificUserIds = TextEditingController();
  String _promoScope = "rider";
  String _promoType = "percent";
  String _targetType = "all";

  @override
  void dispose() {
    _promoCode.dispose();
    _promoDesc.dispose();
    _promoDiscount.dispose();
    _promoMaxCap.dispose();
    _promoValidDays.dispose();
    _walletUserId.dispose();
    _walletDriverId.dispose();
    _walletAmount.dispose();
    _walletReason.dispose();
    _targetPromoCode.dispose();
    _specificUserIds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Admin Tools",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Create Promo Code",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _promoCode,
                      decoration: const InputDecoration(labelText: "Promo code"),
                    ),
                    TextField(
                      controller: _promoDesc,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoDiscount,
                            decoration: InputDecoration(
                              labelText: _promoType == "percent"
                                  ? "Discount %"
                                  : "Fixed Amount (JOD)",
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _promoValidDays,
                            decoration: const InputDecoration(
                              labelText: "Valid for days",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _promoType,
                      items: const [
                        DropdownMenuItem(
                            value: "percent", child: Text("Percentage")),
                        DropdownMenuItem(value: "fixed", child: Text("Fixed")),
                      ],
                      onChanged: (v) =>
                          setState(() => _promoType = v ?? "percent"),
                      decoration:
                          const InputDecoration(labelText: "Discount Type"),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promoMaxCap,
                      decoration: const InputDecoration(
                        labelText: "Max cap (JOD, optional for percentage)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _promoScope,
                      items: const [
                        DropdownMenuItem(value: "rider", child: Text("Rider")),
                        DropdownMenuItem(value: "driver", child: Text("Driver")),
                        DropdownMenuItem(value: "both", child: Text("Both")),
                      ],
                      onChanged: (v) => setState(() => _promoScope = v ?? "rider"),
                      decoration: const InputDecoration(labelText: "Scope"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final days = int.tryParse(_promoValidDays.text.trim()) ?? 30;
                          final validTill =
                              DateTime.now().add(Duration(days: days)).toIso8601String();
                          await context.read<UserProvider>().createPromoCode(
                                code: _promoCode.text.trim(),
                                description: _promoDesc.text.trim(),
                                discountType: _promoType,
                                discountValue: _promoDiscount.text.trim(),
                                maxDiscountAmount: _promoMaxCap.text.trim(),
                                validTillIso: validTill,
                                scope: _promoScope,
                              );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Promo code created.")),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: const Text("Create Promo"),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bulk Promo Targeting",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    TextField(
                      controller: _targetPromoCode,
                      decoration: const InputDecoration(labelText: "Promo code"),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _targetType,
                      items: const [
                        DropdownMenuItem(value: "all", child: Text("All users")),
                        DropdownMenuItem(value: "new_users", child: Text("New users (no trips)")),
                        DropdownMenuItem(value: "specific", child: Text("Specific user IDs")),
                      ],
                      onChanged: (v) => setState(() => _targetType = v ?? "all"),
                      decoration: const InputDecoration(labelText: "Target type"),
                    ),
                    if (_targetType == "specific")
                      TextField(
                        controller: _specificUserIds,
                        decoration: const InputDecoration(
                          labelText: "User IDs (comma separated)",
                        ),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await context.read<UserProvider>().bulkAssignPromoTarget(
                                promoCode: _targetPromoCode.text.trim(),
                                targetType: _targetType,
                                specificUserIdsCsv: _specificUserIds.text.trim(),
                              );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Promo target updated.")),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: const Text("Apply Targeting"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Issue Wallet Balance",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    TextField(
                      controller: _walletAmount,
                      decoration: const InputDecoration(labelText: "Amount (JOD)"),
                    ),
                    TextField(
                      controller: _walletReason,
                      decoration: const InputDecoration(labelText: "Reason"),
                    ),
                    TextField(
                      controller: _walletUserId,
                      decoration: const InputDecoration(labelText: "User ID (rider)"),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final amount =
                              double.tryParse(_walletAmount.text.trim()) ?? 0.0;
                          await context.read<UserProvider>().issueWalletBalance(
                                userId: _walletUserId.text.trim(),
                                amount: amount,
                                reason: _walletReason.text.trim(),
                              );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Balance issued to rider wallet."),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: const Text("Issue to Rider"),
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: _walletDriverId,
                      decoration: const InputDecoration(labelText: "Driver ID"),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final amount =
                              double.tryParse(_walletAmount.text.trim()) ?? 0.0;
                          await context.read<DriverProvider>().issueWalletBalance(
                                driverId: _walletDriverId.text.trim(),
                                amount: amount,
                                reason: _walletReason.text.trim(),
                              );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Balance issued to driver wallet."),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: const Text("Issue to Driver"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Wallet Transactions Export",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final csv =
                              await context.read<UserProvider>().buildWalletTransactionsCsv();
                          if (!mounted) return;
                          await Clipboard.setData(ClipboardData(text: csv));
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("CSV Generated"),
                              content: SizedBox(
                                width: 700,
                                child: SingleChildScrollView(
                                  child: SelectableText(csv),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: const Text("Generate CSV and Copy"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
