import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uber_drivers_app/global/global.dart';
import 'package:uber_drivers_app/providers/registration_provider.dart';
import 'package:uber_drivers_app/methods/common_method.dart';

import '../../methods/map_theme_methods.dart';
import '../../pushNotifications/push_notification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfDriver;
  Color colorToShow = Colors.green;
  String titleToShow = "GO ONLINE NOW";
  bool isDriverAvailable = false;
  bool newTripStatusRegistered = false;
  MapThemeMethods themeMethods = MapThemeMethods();
  CommonMethods commonMethods = CommonMethods();

  getCurrentLiveLocationOfDriver() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfDriver = positionOfUser;
    driverCurrentPosition = currentPositionOfDriver;

    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfDriver!.latitude, currentPositionOfDriver!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _loadDriverStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDriverAvailable = prefs.getBool('isDriverAvailable') ?? false;
      if (isDriverAvailable) {
        colorToShow = Colors.pink;
        titleToShow = "GO OFFLINE NOW";
      } else {
        colorToShow = Colors.green;
        titleToShow = "GO ONLINE NOW";
      }
    });
  }

  _saveDriverStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDriverAvailable', status);
  }

  Future<bool> _isEligibleToGoOnline() async {
    final uid = driverUid.isEmpty ? null : driverUid;
    if (uid == null) {
      return false;
    }
    final response =
        await http.get(Uri.parse("$_awsApiBaseUrl/drivers/$uid"));
    if (response.statusCode != 200) return false;
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if ((payload["exists"] ?? false) != true || payload["item"] == null) {
      return false;
    }
    final data = (payload["item"] as Map).cast<dynamic, dynamic>();
    final String blockStatus = data["blockStatus"]?.toString() ?? "no";
    final String approvalStatus = data["approvalStatus"]?.toString() ?? "pending";
    final Map subscription =
        ((data["monthlySubscription"] ?? {}) as Map).cast<dynamic, dynamic>();
    final bool isSubscriptionActive = subscription["isActive"] == true;
    final String nextDueDateRaw = subscription["nextDueDate"]?.toString() ?? "";

    if (blockStatus != "no") {
      commonMethods.displaySnackBar(
        "Your account is deactivated by admin.",
        context,
      );
      return false;
    }

    if (approvalStatus != "approved") {
      commonMethods.displaySnackBar(
        "Your account is pending admin approval.",
        context,
      );
      return false;
    }

    if (!isSubscriptionActive) {
      commonMethods.displaySnackBar(
        "Monthly subscription is not active. Contact admin.",
        context,
      );
      return false;
    }

    if (nextDueDateRaw.isNotEmpty) {
      final DateTime? nextDueDate = DateTime.tryParse(nextDueDateRaw);
      if (nextDueDate != null && DateTime.now().isAfter(nextDueDate)) {
        commonMethods.displaySnackBar(
          "Subscription expired. Please renew with admin.",
          context,
        );
        return false;
      }
    }

    return true;
  }

  goOnlineNow() {
    //all drivers who are Available for new trip requests
    Geofire.initialize("onlineDrivers");

    Geofire.setLocation(
      driverUid,
      currentPositionOfDriver!.latitude,
      currentPositionOfDriver!.longitude,
    );

    http.put(
      Uri.parse("$_awsApiBaseUrl/drivers/$driverUid"),
      headers: {
        "Authorization": "Bearer public-migration-token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({"newTripStatus": "waiting"}),
    );
    newTripStatusRegistered = true;
  }

  setAndGetLocationUpdates() {
    positionStreamHomePage =
        Geolocator.getPositionStream().listen((Position position) {
      currentPositionOfDriver = position;

      if (isDriverAvailable == true) {
        Geofire.setLocation(
          driverUid,
          currentPositionOfDriver!.latitude,
          currentPositionOfDriver!.longitude,
        );
      }

      LatLng positionLatLng = LatLng(position.latitude, position.longitude);
      controllerGoogleMap!
          .animateCamera(CameraUpdate.newLatLng(positionLatLng));
    });
  }

  goOfflineNow() {
    //stop sharing driver live location updates
    Geofire.removeLocation(driverUid);

    if (newTripStatusRegistered) {
      http.put(
        Uri.parse("$_awsApiBaseUrl/drivers/$driverUid"),
        headers: {
          "Authorization": "Bearer public-migration-token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"newTripStatus": "offline"}),
      );
      newTripStatusRegistered = false;
    }
  }

  initializePushNotificationSystem() {
    PushNotificationSystem notificationSystem = PushNotificationSystem();
    notificationSystem.generateDeviceRegistrationToken();
    notificationSystem.startListeningForNewNotification(context);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadDriverStatus();
    initializePushNotificationSystem();
    Provider.of<RegistrationProvider>(context, listen: false)
        .retrieveCurrentDriverInfo();
    
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            ///google map
            GoogleMap(
              padding: const EdgeInsets.only(top: 136),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              initialCameraPosition: googlePlexInitialPosition,
              onMapCreated: (GoogleMapController mapController) {
                controllerGoogleMap = mapController;
                themeMethods.updateMapTheme(controllerGoogleMap!);

                googleMapCompleterController.complete(controllerGoogleMap);

                getCurrentLiveLocationOfDriver();
              },
            ),

            Container(
              height: 136,
              width: double.infinity,
              //color: Colors.black12,
            ),

            ///go online offline button
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDriverAvailable
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 14,
                              color: isDriverAvailable
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDriverAvailable
                                  ? "Status: Online"
                                  : "Status: Offline",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              isDismissible: false,
                              builder: (BuildContext context) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F172A),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  height: 230,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 18),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 11,
                                        ),
                                    Text(
                                      (!isDriverAvailable)
                                          ? "GO ONLINE NOW"
                                          : "GO OFFLINE NOW",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 21,
                                    ),
                                    Text(
                                      (!isDriverAvailable)
                                          ? "You are about to go online, you will become available to receive trip requests from users."
                                          : "You are about to go offline, you will stop receiving new trip requests from users.",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                        const SizedBox(
                                          height: 25,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFE2E8F0),
                                                ),
                                                child: const Text(
                                                  "BACK",
                                                  style: TextStyle(
                                                      color: Color(0xFF0F172A)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 16,
                                            ),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  if (!isDriverAvailable) {
                                                    _isEligibleToGoOnline().then(
                                                      (isEligible) {
                                                        if (!isEligible) {
                                                          Navigator.pop(context);
                                                          return;
                                                        }
                                                        goOnlineNow();
                                                        setAndGetLocationUpdates();
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          colorToShow =
                                                              Colors.pink;
                                                          titleToShow =
                                                              "GO OFFLINE NOW";
                                                          isDriverAvailable =
                                                              true;
                                                        });
                                                        _saveDriverStatus(true);
                                                      },
                                                    );
                                                  } else {
                                                    goOfflineNow();
                                                    Navigator.pop(context);
                                                    setState(() {
                                                      colorToShow = Colors.green;
                                                      titleToShow =
                                                          "GO ONLINE NOW";
                                                      isDriverAvailable = false;
                                                    });
                                                    _saveDriverStatus(false);
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      (!isDriverAvailable)
                                                          ? const Color(
                                                              0xFF16A34A)
                                                          : const Color(
                                                              0xFFDC2626),
                                                ),
                                                child: const Text(
                                                  "CONFIRM",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorToShow,
                        ),
                        child: Text(
                          titleToShow,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



