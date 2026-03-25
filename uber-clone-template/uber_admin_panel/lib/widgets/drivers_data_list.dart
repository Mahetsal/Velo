import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uber_admin_panel/methods/common_methods.dart';
import 'package:uber_admin_panel/pages/driver_data_screen.dart';

import '../provider/driver_provider.dart';

class DriversDataList extends StatefulWidget {
  const DriversDataList({super.key});

  @override
  State<DriversDataList> createState() => _DriversDataListState();
}

class _DriversDataListState extends State<DriversDataList> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  CommonMethods commonMethods = CommonMethods();
  final Set<String> _selectedDriverIds = {};
  bool _selectAll = false;

  void _syncSelectAllState(int totalDrivers) {
    setState(() {
      _selectAll = totalDrivers > 0 && _selectedDriverIds.length == totalDrivers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchDrivers(),
      builder: (BuildContext context, snapshotData) {
        if (snapshotData.hasError) {
          print("Error: ${snapshotData.error}");
          return const Center(
            child: Text(
              "Error occurred. Try later",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          );
        }
        if (snapshotData.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshotData.connectionState == ConnectionState.none) {
          return const Center(
            child: Text(
              "No connection. Please check your internet.",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          );
        }
        
        if (!snapshotData.hasData || snapshotData.data!.isEmpty) {
          return const Center(
            child: Text(
              "No data available",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          );
        }

        final listItems = snapshotData.data!;

        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: _selectedDriverIds.isEmpty
                        ? null
                        : () {
                            Provider.of<DriverProvider>(context, listen: false)
                                .bulkSetDriverApprovalStatus(
                                    _selectedDriverIds.toList(), true);
                          },
                    child: const Text("Approve Selected"),
                  ),
                  ElevatedButton(
                    onPressed: _selectedDriverIds.isEmpty
                        ? null
                        : () {
                            Provider.of<DriverProvider>(context, listen: false)
                                .bulkSetDriverActiveStatus(
                                    _selectedDriverIds.toList(), false);
                          },
                    child: const Text("Deactivate Selected"),
                  ),
                  ElevatedButton(
                    onPressed: _selectedDriverIds.isEmpty
                        ? null
                        : () {
                            Provider.of<DriverProvider>(context, listen: false)
                                .bulkSetDriverSubscriptionStatus(
                                    _selectedDriverIds.toList(), true);
                          },
                    child: const Text("Start Cash Sub Selected"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Checkbox(
                    value: _selectAll,
                    onChanged: (value) {
                      setState(() {
                        _selectAll = value ?? false;
                        _selectedDriverIds.clear();
                        if (_selectAll) {
                          for (final item in listItems) {
                            _selectedDriverIds.add(item["id"].toString());
                          }
                        }
                      });
                    },
                  ),
                ),
                const Text("Select All"),
              ],
            ),
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 5),
              itemCount: listItems.length,
              shrinkWrap: true,
              itemBuilder: ((context, index) {
            final driver = listItems[index];
            final String driverId = driver["id"]?.toString() ?? "";
            final String firstName = driver["firstName"]?.toString() ?? "";
            final String secondName = driver["secondName"]?.toString() ?? "";
            final Map<String, dynamic> vehicleInfo =
                ((driver["vehicleInfo"] ?? {}) as Map).cast<String, dynamic>();
            final String vehicleDetails =
                "${vehicleInfo["brand"] ?? ""} ${vehicleInfo["color"] ?? ""} ${vehicleInfo["productionYear"] ?? ""}"
                    .trim();
            final String phone = driver["phoneNumber"]?.toString() ?? "-";
            final dynamic earningsRaw = driver["earnings"];
            final double earnings = double.tryParse("$earningsRaw") ?? 0.0;
            final String blockStatus = driver["blockStatus"]?.toString() ?? "no";
            final bool isActive = blockStatus == "no";
            final Map<String, dynamic> monthlySubscription =
                ((driver["monthlySubscription"] ?? {}) as Map)
                    .cast<String, dynamic>();
            final bool isSubscriptionActive =
                monthlySubscription["isActive"] == true;
            final String paymentMethod =
                monthlySubscription["paymentMethod"]?.toString() ?? "-";
            final String approvalStatus =
                driver["approvalStatus"]?.toString() ?? "pending";
            final bool isApproved = approvalStatus == "approved";

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 34,
                  child: Checkbox(
                    value: _selectedDriverIds.contains(driverId),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedDriverIds.add(driverId);
                        } else {
                          _selectedDriverIds.remove(driverId);
                        }
                      });
                      _syncSelectAllState(listItems.length);
                    },
                  ),
                ),
                commonMethods.data(
                  1,
                  Text(
                    "$firstName $secondName",
                  ),
                ),
                commonMethods.data(
                  1,
                  Text(
                    vehicleDetails.isEmpty ? "-" : vehicleDetails,
                  ),
                ),
                commonMethods.data(
                  1,
                  Text(
                    phone,
                  ),
                ),
                commonMethods.data(
                  1,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("JOD ${earnings.toStringAsFixed(2)}"),
                      const SizedBox(height: 4),
                      Text(
                        isSubscriptionActive
                            ? "Sub: Active ($paymentMethod)"
                            : "Sub: Inactive",
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive ? "Status: Active" : "Status: Deactivated",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Approval: ${isApproved ? "Approved" : "Pending"}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                commonMethods.data(
                  1,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isApproved
                                ? Colors.orange.shade700
                                : Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Provider.of<DriverProvider>(context, listen: false)
                                .setDriverApprovalStatus(driverId, !isApproved);
                          },
                          child: Text(
                            isApproved ? "Set Pending" : "Approve",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Provider.of<DriverProvider>(context, listen: false)
                                .setDriverActiveStatus(driverId, !isActive);
                          },
                          child: Text(
                            isActive ? "Deactivate" : "Activate",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSubscriptionActive
                                ? Colors.orange.shade700
                                : const Color.fromARGB(221, 39, 57, 99),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            final provider =
                                Provider.of<DriverProvider>(context, listen: false);
                            if (isSubscriptionActive) {
                              provider.stopMonthlySubscription(driverId);
                            } else {
                              provider.startMonthlySubscriptionCash(driverId);
                            }
                          },
                          child: Text(
                            isSubscriptionActive
                                ? "Stop Sub"
                                : "Start Cash Sub",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                commonMethods.data(
                  1,
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(221, 39, 57, 99),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => DriverDataScreen(driverId: driverId),
                          ),
                        );
                      },
                      child: const Text(
                        "View More",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchDrivers() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/drivers"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) {
      return [];
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload["items"] as List<dynamic>? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

