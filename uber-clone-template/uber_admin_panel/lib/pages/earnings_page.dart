import 'package:flutter/material.dart';
import '../methods/common_methods.dart';
import '../widgets/trips_data_list.dart'; // We can reuse or create a specific one

class EarningsPage extends StatefulWidget {
  static const String id = "/webPageEarnings";

  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  CommonMethods cMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: const Text(
                  "Manage Earnings",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Row(
                children: [
                  cMethods.header(2, "TRIP ID"),
                  cMethods.header(1, "TIMING"),
                  cMethods.header(1, "FARE"),
                  cMethods.header(1, "DRIVER"),
                  cMethods.header(1, "USER"),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              // We can reuse TripsDataList or create a custom one with different columns
              const TripsDataList(), // Reusing for now, as it shows fare and fits the requirement.
            ],
          ),
        ),
      ),
    );
  }
}
