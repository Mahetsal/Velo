import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../methods/common_methods.dart';

class TripsDataList extends StatefulWidget {
  const TripsDataList({super.key});

  @override
  State<TripsDataList> createState() => _TripsDataListState();
}

class _TripsDataListState extends State<TripsDataList> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  CommonMethods cMethods = CommonMethods();

  launchGoogleMapFromSourceToDestination(
    pickUpLat,
    pickUpLng,
    dropOffLat,
    dropOffLng,
  ) async {
    String directionAPIUrl =
        "https://www.google.com/maps/dir/?api=1&origin=$pickUpLat,$pickUpLng&destination=$dropOffLat,$dropOffLng&dir_action=navigate";

    if (await canLaunchUrl(Uri.parse(directionAPIUrl))) {
      await launchUrl(Uri.parse(directionAPIUrl));
    } else {
      throw "Could not lauch google map";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTrips(),
      builder: (BuildContext context, snapshotData) {
        if (snapshotData.hasError) {
          return const Center(
            child: Text(
              "Error Occurred. Try Later.",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          );
        }

        if (snapshotData.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final itemsList = snapshotData.data ?? [];

        final completedTrips =
            itemsList.where((item) => item["status"]?.toString() == "ended").toList();

        return ListView.builder(
          shrinkWrap: true,
          itemCount: completedTrips.length,
          itemBuilder: ((context, index) {
            final trip = completedTrips[index];
            final fare = trip["fareAmount"]?.toString() ?? "0";
            final dateTime = trip["publishDateTime"]?.toString() ?? "-";
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  cMethods.data(
                    2,
                    Text(
                      trip["tripID"]?.toString() ?? "-",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  cMethods.data(
                    1,
                    Text(trip["userName"]?.toString() ?? "-", style: const TextStyle(fontSize: 12)),
                  ),
                  cMethods.data(
                    1,
                    Text(trip["driverName"]?.toString() ?? "-", style: const TextStyle(fontSize: 12)),
                  ),
                  cMethods.data(
                    1,
                    Text(trip["carDetails"]?.toString() ?? "-", style: const TextStyle(fontSize: 12)),
                  ),
                  cMethods.data(
                    1,
                    Text(dateTime, style: const TextStyle(fontSize: 12)),
                  ),
                  cMethods.data(
                    1,
                    Text(
                      "JOD $fare",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  cMethods.data(
                    1,
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          String pickUpLat = trip["pickUpLatLng"]["latitude"];
                          String pickUpLng = trip["pickUpLatLng"]["longitude"];
                          String dropOffLat = trip["dropOffLatLng"]["latitude"];
                          String dropOffLng = trip["dropOffLatLng"]["longitude"];
                          launchGoogleMapFromSourceToDestination(
                            pickUpLat,
                            pickUpLng,
                            dropOffLat,
                            dropOffLng,
                          );
                        },
                        child: const Text(
                          "Open Route",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTrips() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/trips"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return [];
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload["items"] as List<dynamic>? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
