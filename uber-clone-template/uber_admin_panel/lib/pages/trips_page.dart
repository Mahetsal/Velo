import 'package:flutter/material.dart';

import '../methods/common_methods.dart';
import '../widgets/trips_data_list.dart';

class TripsPage extends StatefulWidget {
  static const String id = "/webPageTrips";

  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manage Trips",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Completed trip ledger and route drilldown",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    cMethods.header(2, "TRIP ID"),
                    cMethods.header(1, "USER NAME"),
                    cMethods.header(1, "DRIVER NAME"),
                    cMethods.header(1, "CAR DETAILS"),
                    cMethods.header(1, "TIMING"),
                    cMethods.header(1, "FARE"),
                    cMethods.header(1, "VIEW DETAILS"),
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              //display data
              const TripsDataList(),
            ],
          ),
        ),
      ),
    );
  }
}
