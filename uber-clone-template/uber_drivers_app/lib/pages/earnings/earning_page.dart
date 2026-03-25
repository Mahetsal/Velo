import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/registration_provider.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String _formatDueDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return "Not available";
    return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    // Fetch the earnings as soon as the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RegistrationProvider>(context, listen: false)
          .fetchDriverEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                color: Colors.black,
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/totalearnings.png",
                        width: 120,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        "Total Earnings:",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      Consumer<RegistrationProvider>(
                        builder: (context, provider, child) {
                          // Check if data is still being fetched
                          if (provider.driverEarnings == null) {
                            return const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            );
                          } else {
                            return Text(
                              "JOD ${provider.driverEarnings}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Consumer<RegistrationProvider>(
                        builder: (context, provider, child) {
                          final subText = provider.isSubscriptionActive
                              ? "Sub is active till ${_formatDueDate(provider.subscriptionNextDueDate)}"
                              : "Subscription is inactive";
                          return Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                subText,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
