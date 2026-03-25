import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/models/address_models.dart';

import '../models/direction_details.dart';

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return;
      displaySnackBar(
          "Your Internet is not Available. Check your connection. Try Again.",
          context);
    }
  }

  displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(
      Uri.parse(apiUrl),
      headers: const {"User-Agent": "velo-users-app/1.0"},
    );

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        print('error');
        return "error";
      }
    } catch (errorMsg) {
      print(errorMsg);
      return "error";
    }
  }

  ///Reverse GeoCoding
  static Future<String> convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
      Position position, BuildContext context) async {
    String humanReadableAddress = "";
    final inJordan = position.latitude >= 29.0 &&
        position.latitude <= 33.5 &&
        position.longitude >= 34.0 &&
        position.longitude <= 39.5;
    if (!inJordan) {
      // Force a Jordan-friendly fallback when emulator/device location is out of country.
      humanReadableAddress = "Amman, Jordan";
      AddressModel model = AddressModel();
      model.humanReadableAddress = humanReadableAddress;
      model.placeName = humanReadableAddress;
      model.longitudePosition = 35.9106;
      model.latitudePosition = 31.9539;
      Provider.of<AppInfoClass>(context, listen: false).updatePickUpLocation(model);
      return humanReadableAddress;
    }
    final apiGeoCodingUrl =
        "https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=jsonv2&accept-language=en";

    var responseFromAPI = await sendRequestToAPI(apiGeoCodingUrl);

    if (responseFromAPI != "error" && responseFromAPI["display_name"] != null) {
      humanReadableAddress = responseFromAPI["display_name"].toString();

      AddressModel model = AddressModel();
      model.humanReadableAddress = humanReadableAddress;
      model.placeName = humanReadableAddress;
      model.longitudePosition = position.longitude;
      model.latitudePosition = position.latitude;

      Provider.of<AppInfoClass>(context, listen: false)
          .updatePickUpLocation(model);
    }

    return humanReadableAddress;
  }

  /// This method shortens the full address by extracting key parts.
  static String shortenAddress(String fullAddress) {
    // Split the address by commas
    List<String> parts = fullAddress.split(',');

    // Return a shorter version of the address: e.g., "Street Name, City"
    if (parts.length >= 2) {
      return "${parts[0].trim()}, ${parts[1].trim()}";
    }

    // If the address has fewer parts, return it as is
    return fullAddress;
  }

  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      ll.LatLng source, ll.LatLng destination) async {
    final urlDirectionAPI =
        "https://router.project-osrm.org/route/v1/driving/${source.longitude},${source.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=polyline";

    var responseFromDirectionAPI = await sendRequestToAPI(urlDirectionAPI);

    if (responseFromDirectionAPI == "error") {
      return null;
    }

    if (responseFromDirectionAPI["routes"] == null ||
        responseFromDirectionAPI["routes"].isEmpty) {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();
    try {
      final route = responseFromDirectionAPI["routes"][0] as Map<String, dynamic>;
      final distanceMeters =
          double.tryParse(route["distance"]?.toString() ?? "0") ?? 0;
      final durationSeconds =
          double.tryParse(route["duration"]?.toString() ?? "0") ?? 0;
      directionDetails.distanceValueDigit = distanceMeters.toInt();
      directionDetails.durationValueDigit = durationSeconds.toInt();
      directionDetails.distanceTextString =
          "${(distanceMeters / 1000).toStringAsFixed(1)} km";
      final minutes = (durationSeconds / 60).round();
      directionDetails.durationTextString = minutes >= 60
          ? "${minutes ~/ 60} hours ${minutes % 60} mins"
          : "$minutes mins";
      directionDetails.encodedPoints = route["geometry"]?.toString() ?? "";
    } catch (e) {
      return null;
    }
    return directionDetails;
  }

  calculateFareAmountInJOD(
    DirectionDetails directionDetails, {
    double surgeMultiplier = 1.0,
    double riderDiscountPercent = 5.0,
  }) {
    // Jordan local pricing baseline (JOD)
    const double distancePerKmAmountJOD = 0.35;
    const double durationPerMinuteAmountJOD = 0.08;
    const double baseFareAmountJOD = 0.50;
    const double bookingFeeJOD = 0.20;
    const double minimumFareJOD = 1.00;

    // Calculate fare based on distance and time
    double totalDistanceTravelledFareAmountJOD =
        (directionDetails.distanceValueDigit! / 1000) * distancePerKmAmountJOD;
    double totalDurationSpendFareAmountJOD =
        (directionDetails.durationValueDigit! / 60) *
            durationPerMinuteAmountJOD;

    // Total fare before applying surge
    double totalFareBeforeSurgeJOD = baseFareAmountJOD +
        totalDistanceTravelledFareAmountJOD +
        totalDurationSpendFareAmountJOD +
        bookingFeeJOD;

    // Apply surge pricing
    double overAllTotalFareAmountJOD =
        totalFareBeforeSurgeJOD * surgeMultiplier;

    // Apply minimum fare
    if (overAllTotalFareAmountJOD < minimumFareJOD) {
      overAllTotalFareAmountJOD = minimumFareJOD;
    }

    final discountFactor = (100 - riderDiscountPercent) / 100;
    overAllTotalFareAmountJOD = overAllTotalFareAmountJOD * discountFactor;

    if (overAllTotalFareAmountJOD < minimumFareJOD) {
      overAllTotalFareAmountJOD = minimumFareJOD;
    }

    return overAllTotalFareAmountJOD.toStringAsFixed(2);
  }

  // Utility function to format time from total minutes into "X hours Y mins"
  String formatTime(int totalMinutes) {
    int hours = totalMinutes ~/ 60; // Get the number of full hours
    int minutes = totalMinutes % 60; // Get the remaining minutes
    if (hours > 0) {
      return "$hours hours $minutes mins";
    } else {
      return "$minutes mins"; // If there are no hours, just show minutes
    }
  }
}
