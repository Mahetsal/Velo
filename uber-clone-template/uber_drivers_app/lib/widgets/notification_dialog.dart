import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../global/global.dart';
import '../methods/common_method.dart';
import '../models/trip_details.dart';
import '../pages/newTrip/new_trip_page.dart';
import 'loading_dialog.dart';

class NotificationDialog extends StatefulWidget {
  final TripDetails? tripDetailsInfo;
  final String? fareAmount;
  final String? bidAmount;

  NotificationDialog({
    super.key,
    this.tripDetailsInfo,
    this.fareAmount,
    this.bidAmount,
  });

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  String tripRequestStatus = "";
  CommonMethods cMethods = CommonMethods();
  late Timer timer;

  cancelNotificationDialogAfter20Sec() {
    const oneTickPerSecond = Duration(seconds: 1);

    timer = Timer.periodic(oneTickPerSecond, (timer) {
      driverTripRequestTimeout = driverTripRequestTimeout - 1;

      if (tripRequestStatus == "accepted") {
        timer.cancel();
        driverTripRequestTimeout = 40;
        return;
      }

      if (driverTripRequestTimeout == 0) {
        timer.cancel();
        driverTripRequestTimeout = 40;
        audioPlayer.stop();

        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    cancelNotificationDialogAfter20Sec();
  }

  @override
  void dispose() {
    timer.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  checkAvailabilityOfTripRequest(BuildContext context) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => const LoadingDialog(
        messageText: 'Please wait...',
      ),
    );

    final tripId = widget.tripDetailsInfo?.tripID ?? "";
    final getResp = await http.get(
      Uri.parse("$_awsApiBaseUrl/trips/$tripId"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
    if (getResp.statusCode != 200) {
      cMethods.displaySnackBar("Trip Request removed. Not Found.", context);
      return;
    }
    final payload = jsonDecode(getResp.body) as Map<String, dynamic>;
    final exists = (payload["exists"] ?? false) == true;
    final item = (payload["item"] ?? {}) as Map;
    if (!exists || item.isEmpty) {
      cMethods.displaySnackBar("Trip Request removed. Not Found.", context);
      return;
    }
    final status = item["status"]?.toString() ?? "new";
    final assigned = item["driverId"]?.toString() ?? "waiting";
    if (status == "new" || assigned == "waiting" || assigned == driverUid) {
      await http.put(
        Uri.parse("$_awsApiBaseUrl/trips/$tripId"),
        headers: {
          "Authorization": "Bearer public-migration-token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"status": "accepted", "driverId": driverUid}),
      );
      cMethods.turnOffLocationUpdatesForHomePage();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo),
        ),
      );
      return;
    }
    cMethods.displaySnackBar("Trip Request is no longer available.", context);
  }

  @override
  Widget build(BuildContext context) {
    // Null safety and string handling
    final String fareAmount = widget.fareAmount ?? "N/A";
    final String bidAmount =
        widget.bidAmount == "null" || widget.bidAmount == null
            ? "No Bid"
            : "Rs ${widget.bidAmount}";

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white54,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15.0),

            Image.asset(
              "assets/images/uberexec.png",
              width: 140,
            ),

            const SizedBox(height: 15.0),

            const Text(
              "NEW TRIP REQUEST",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 20.0),

            const Divider(height: 1, color: Colors.black, thickness: 1),

            const SizedBox(height: 10.0),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset("assets/images/initial.png",
                          height: 16, width: 16),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo?.pickupAddress ?? "Unknown",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset("assets/images/final.png",
                          height: 16, width: 16),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo?.dropOffAddress ?? "Unknown",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15.0),
            // Fare and Bid Amount at the Start
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Actual Fare Amount: Rs $fareAmount",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Bidded Amount: $bidAmount",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            const Divider(height: 1, color: Colors.black, thickness: 1),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        audioPlayer.stop();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink),
                      child: const Text(
                        "DECLINE",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        audioPlayer.stop();
                        setState(() {
                          tripRequestStatus = "accepted";
                        });
                        await checkAvailabilityOfTripRequest(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text(
                        "ACCEPT",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
