import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uber_admin_panel/provider/driver_provider.dart';

class DriverDataScreen extends StatefulWidget {
  final String driverId;

  const DriverDataScreen({super.key, required this.driverId});

  @override
  _DriverDataScreenState createState() => _DriverDataScreenState();
}

class _DriverDataScreenState extends State<DriverDataScreen> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchDriver(),
      builder: (BuildContext context, snapshotData) {
        if (snapshotData.hasError) {
          return const Center(
            child: Text(
              "Error occurred. Try later",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
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
        if (!snapshotData.hasData || snapshotData.data == null) {
          return const Center(
            child: Text(
              "No data available",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          );
        }

        Map dataMap = snapshotData.data!;
        final String blockStatus = dataMap["blockStatus"]?.toString() ?? "no";
        final bool isActive = blockStatus == "no";
        final Map monthlySubscription =
            (dataMap["monthlySubscription"] ?? {}) as Map;
        final bool isSubActive = monthlySubscription["isActive"] == true;
        final String approvalStatus =
            dataMap["approvalStatus"]?.toString() ?? "pending";
        final bool isApproved = approvalStatus == "approved";

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color.fromARGB(221, 39, 57, 99),
            centerTitle: true,
            title: const Text(
              "Driver Details",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isApproved
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                      onPressed: () {
                        Provider.of<DriverProvider>(context, listen: false)
                            .setDriverApprovalStatus(
                                widget.driverId, !isApproved);
                      },
                      child: Text(isApproved ? "Set Pending" : "Approve Driver"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive ? Colors.red.shade600 : Colors.green.shade600,
                      ),
                      onPressed: () {
                        Provider.of<DriverProvider>(context, listen: false)
                            .setDriverActiveStatus(widget.driverId, !isActive);
                      },
                      child:
                          Text(isActive ? "Deactivate Driver" : "Activate Driver"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubActive
                            ? Colors.orange.shade700
                            : const Color.fromARGB(221, 39, 57, 99),
                      ),
                      onPressed: () {
                        final provider =
                            Provider.of<DriverProvider>(context, listen: false);
                        if (isSubActive) {
                          provider.stopMonthlySubscription(widget.driverId);
                        } else {
                          provider.startMonthlySubscriptionCash(widget.driverId);
                        }
                      },
                      child: Text(isSubActive
                          ? "Stop Monthly Subscription"
                          : "Start Monthly Subscription (Cash)"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProfileSection(dataMap),
                const SizedBox(height: 20),
                const Divider(),
                _buildCNICSection(dataMap),
                const SizedBox(height: 20),
                const Divider(),
                _buildLicenseSection(dataMap),
                const SizedBox(height: 20),
                const Divider(),
                _buildVehicleInfoSection(dataMap),
                const SizedBox(height: 20),
                const Divider(),
                _buildWalletAndHistorySection(dataMap),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchDriver() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/drivers/${widget.driverId}"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return null;
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if ((payload["exists"] ?? false) != true) return null;
    return (payload["item"] as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> _fetchDriverTrips() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/trips/by-driver/${widget.driverId}"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return [];
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload["items"] as List<dynamic>? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Widget _buildProfileSection(Map dataMap) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dataMap.containsKey('profilePicture'))
          ClipOval(
            child: Image.network(
              dataMap['profilePicture'],
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(width: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Name: ${dataMap['firstName']} ${dataMap['secondName']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Phone: ${dataMap['phoneNumber']}"),
            Text("Email: ${dataMap['email']}"),
            Text("CNIC Number: ${dataMap['cnicNumber']}"),
            Text("Address: ${dataMap['address']}"),
            Text("Date of Birth: ${dataMap['dob']}"),
          ],
        ),
      ],
    );
  }

  Widget _buildCNICSection(Map dataMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CNIC Information:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildImage(dataMap['cnicFrontImage'], "Front CNIC"),
            _buildImage(dataMap['cnicBackImage'], "Back CNIC"),
            _buildImage(dataMap['driverFaceWithCnic'], "Selfie with CNIC"),
          ],
        ),
      ],
    );
  }

  Widget _buildLicenseSection(Map dataMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Driving License:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('Driving License Number: ${dataMap['drivingLicenseNumber']}'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildImage(dataMap['drivingLicenseFrontImage'], "Front License"),
            _buildImage(dataMap['drivingLicenseBackImage'], "Back License"),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleInfoSection(Map dataMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vehicle Information:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text("Vehicle Type: ${dataMap['vehicleInfo']['type']}"),
        Text("Brand: ${dataMap['vehicleInfo']['brand']}"),
        Text("Color: ${dataMap['vehicleInfo']['color']}"),
        Text("Year: ${dataMap['vehicleInfo']['productionYear']}"),
        Text(
            "Plate Number: ${dataMap['vehicleInfo']['registrationPlateNumber']}"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildImage(
                dataMap['vehicleInfo']['registrationCertificateFrontImage'],
                "Front Certificate"),
            _buildImage(
                dataMap['vehicleInfo']['registrationCertificateBackImage'],
                "Back Certificate"),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletAndHistorySection(Map dataMap) {
    final wallet = dataMap["walletBalance"]?.toString() ?? "0";
    final txs = (dataMap["walletTransactions"] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Wallet: JOD $wallet",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Wallet History:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (txs.isEmpty)
          const Text("No wallet transactions.")
        else
          ...txs.take(10).map(
                (e) => ListTile(
                  dense: true,
                  title: Text(
                    "JOD ${(e as Map)["amount"] ?? "0"} - ${e["reason"] ?? "-"}",
                  ),
                  subtitle: Text("${e["createdAt"] ?? ""}"),
                ),
              ),
        const SizedBox(height: 14),
        const Text(
          "Trip History:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchDriverTrips(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            final trips = snapshot.data ?? [];
            if (trips.isEmpty) return const Text("No trips yet.");
            return Column(
              children: trips.take(20).map((trip) {
                return Card(
                  child: ListTile(
                    title: Text("Trip ${trip["tripID"] ?? trip["id"]}"),
                    subtitle: Text(
                      "${trip["status"] ?? "-"} | ${trip["publishDateTime"] ?? "-"}",
                    ),
                    trailing: Text(
                      "JOD ${trip["fareAmount"] ?? "0"}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImage(String url, String label) {
    return Column(
      children: [
        Image.network(
          url,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
