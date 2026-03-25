import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uber_drivers_app/global/global.dart';

class TripProvider with ChangeNotifier {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  String currentDriverTotalTripsCompleted = "";
  bool isLoading = true;
  List<Map<String, dynamic>> completedTrips = [];

  // Method to fetch the total trips completed by the current driver
  Future<void> getCurrentDriverTotalNumberOfTripsCompleted() async {
    try {
      isLoading = true;
      notifyListeners();
      final uid = driverUid.isEmpty ? null : driverUid;
      if (uid == null) {
        currentDriverTotalTripsCompleted = "0";
        return;
      }
      final response =
          await http.get(Uri.parse("$_awsApiBaseUrl/trips/by-driver/$uid"));
      if (response.statusCode != 200) {
        currentDriverTotalTripsCompleted = "0";
        return;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (payload["items"] as List<dynamic>? ?? []);
      final ended = items.where((e) => (e as Map)["status"] == "ended").length;
      currentDriverTotalTripsCompleted = ended.toString();
    } catch (error) {
      print("Error fetching trips: $error");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Method to fetch completed trips
  Future<void> getCompletedTrips() async {
    try {
      isLoading = true;
      notifyListeners();

      final uid = driverUid.isEmpty ? null : driverUid;
      if (uid == null) {
        completedTrips = [];
        return;
      }
      final response =
          await http.get(Uri.parse("$_awsApiBaseUrl/trips/by-driver/$uid"));
      if (response.statusCode != 200) {
        completedTrips = [];
        return;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (payload["items"] as List<dynamic>? ?? []);
      completedTrips = items
          .where((e) => (e as Map)["status"] == "ended")
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (error) {
      print("Error fetching completed trips: $error");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
