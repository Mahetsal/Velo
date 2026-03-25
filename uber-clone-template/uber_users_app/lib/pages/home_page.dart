import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/authentication/register_screen.dart';
import 'package:uber_users_app/pages/search_destination_place.dart';
import 'package:uber_users_app/widgets/custome_drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global/global_var.dart';
import '../global/trip_var.dart';
import '../methods/common_methods.dart';
import '../methods/manage_drivers_methods.dart';
import '../methods/push_notification_service.dart';
import '../models/direction_details.dart';
import '../models/address_models.dart';
import '../models/online_nearby_drivers.dart';
import '../widgets/info_dialog.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/velo_floating_sheet.dart';
import '../utils/map_marker_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  GoogleMapController? mapController;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 230;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polylineCoOrdinates = [];
  final Map<String, LatLng> markerCoordinates = {};
  final Map<String, LatLng> circleCoordinates = {};
  bool isDrawerOpened = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriversKeysLoaded = false;
  String? currentTripId;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  Timer? tripPollTimer;
  bool requestingDirectionDetailsInfo = false;
  String selectedPaymentMethod = "Cash"; // Default selection
  double actualFareAmountCar = 0.0; // To store the actual fare amount
  String selectedVehicle = "Economy";
  String estimatedTimeCar = "";
  double actualFareAmount = 0.0;
  String estimatedTime = "";
  Map<String, dynamic>? appliedPromo;
  double promoDiscountAmount = 0.0;

  /// Nearby drivers on map (GeoFire live updates) — no personal info shown.
  StreamSubscription<dynamic>? _geoFireSubscription;
  BitmapDescriptor? _carMarkerIcon;
  LatLngBounds? _visibleMapBounds;
  Timer? _cameraIdleDebounce;
  bool _geoListenerPaused = false;
  double _lastGeoCenterLat = 0;
  double _lastGeoCenterLng = 0;
  double _lastGeoRadiusKm = 30;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _carMarkerIcon = await createCarMarkerBitmapDescriptor();
      if (mounted) setState(() {});
      await getCurrentLiveLocationOfUser();
    });
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMethod = prefs.getString("default_payment_method");
    final savedPromo = prefs.getString("default_promo_code") ?? "";
    if (!mounted) return;
    setState(() {
      if (savedMethod == "Wallet") {
        selectedPaymentMethod = "Wallet";
      } else {
        selectedPaymentMethod = "Cash";
      }
    });
    if (savedPromo.isNotEmpty) {
      unawaited(applyPromoCode(savedPromo, silent: true));
    }
  }

  getCurrentLiveLocationOfUser() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    final inJordan = positionOfUser.latitude >= 29.0 &&
        positionOfUser.latitude <= 33.5 &&
        positionOfUser.longitude >= 34.0 &&
        positionOfUser.longitude <= 39.5;
    currentPositionOfUser = inJordan
        ? positionOfUser
        : Position(
            longitude: 35.9106,
            latitude: 31.9539,
            timestamp: DateTime.now(),
            accuracy: 1,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
    final positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: positionOfUserInLatLng, zoom: 15),
      ),
    );

    await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
        currentPositionOfUser!, context);

    await getUserInfoAndCheckBlockStatus();

    _lastGeoCenterLat = currentPositionOfUser!.latitude;
    _lastGeoCenterLng = currentPositionOfUser!.longitude;
    await _startGeoFireQuery(
      currentPositionOfUser!.latitude,
      currentPositionOfUser!.longitude,
      30,
    );
  }

  getUserInfoAndCheckBlockStatus() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/users/$userID"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) {
      if (!mounted) return;
      Provider.of<AuthenticationProvider>(context, listen: false)
          .signOut(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (c) => const RegisterScreen()));
      return;
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final item = (payload["item"] ?? {}) as Map;
    if ((payload["exists"] ?? false) != true || item.isEmpty) {
      if (!mounted) return;
      Provider.of<AuthenticationProvider>(context, listen: false)
          .signOut(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (c) => const RegisterScreen()));
      return;
    }
    final blockStatus = item["blockStatus"]?.toString() ?? "no";
    if (blockStatus != "no") {
      if (!mounted) return;
      Provider.of<AuthenticationProvider>(context, listen: false)
          .signOut(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (c) => const RegisterScreen()));
      cMethods.displaySnackBar(
          "You are blocked. Contact admin: gulzarsoft@gmail.com", context);
      return;
    }
    if (mounted) {
      setState(() {
        userName = item["name"]?.toString() ?? "";
        userPhone = item["phone"]?.toString() ?? "";
        userEmail = item["email"]?.toString() ?? "";
      });
    }
  }

  displayUserRideDetailsContainer() async {
    ///Directions API
    await retrieveDirectionDetails();
    if (mounted) {
      setState(() {
        searchContainerHeight = 0;
        bottomMapPadding = 240;
        rideDetailsContainerHeight = MediaQuery.of(context).size.height * 0.72;
        isDrawerOpened = false;
      });
    }
  }

  retrieveDirectionDetails() async {
    var pickUpLocation =
        Provider.of<AppInfoClass>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfoClass>(context, listen: false).dropOffLocation;

    final pickupGeoGraphicCoOrdinates = ll.LatLng(
        pickUpLocation!.latitudePosition!, pickUpLocation.longitudePosition!);
    final dropOffDestinationGeoGraphicCoOrdinates = ll.LatLng(
        dropOffDestinationLocation!.latitudePosition!,
        dropOffDestinationLocation.longitudePosition!);
    final pickupMapLatLng = LatLng(
      pickUpLocation.latitudePosition!,
      pickUpLocation.longitudePosition!,
    );
    final dropOffMapLatLng = LatLng(
      dropOffDestinationLocation.latitudePosition!,
      dropOffDestinationLocation.longitudePosition!,
    );

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Getting direction..."),
    );

    ///Directions API
    var detailsFromDirectionAPI =
        await CommonMethods.getDirectionDetailsFromAPI(
            pickupGeoGraphicCoOrdinates,
            dropOffDestinationGeoGraphicCoOrdinates);
    if (mounted) {
      setState(() {
        tripDirectionDetailsInfo = detailsFromDirectionAPI;
      });
    }

    Navigator.pop(context);

    //draw route from pickup to dropOffDestination
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination =
        pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

    polylineCoOrdinates.clear();
    if (latLngPointsFromPickUpToDestination.isNotEmpty) {
      latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
        polylineCoOrdinates
            .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
      });
    }

    // center map between pickup and destination
    final center = LatLng(
      (pickupGeoGraphicCoOrdinates.latitude +
              dropOffDestinationGeoGraphicCoOrdinates.latitude) /
          2,
      (pickupGeoGraphicCoOrdinates.longitude +
              dropOffDestinationGeoGraphicCoOrdinates.longitude) /
          2,
    );
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: 12.5),
      ),
    );
    if (mounted) {
      setState(() {
        markerCoordinates["pickUpPointMarkerID"] = pickupMapLatLng;
        markerCoordinates["dropOffDestinationPointMarkerID"] = dropOffMapLatLng;
        circleCoordinates["pickupCircleID"] = pickupMapLatLng;
        circleCoordinates["dropOffDestinationCircleID"] = dropOffMapLatLng;
      });
    }
  }

  resetAppNow() {
    setState(() {
      polylineCoOrdinates.clear();
      markerCoordinates.clear();
      circleCoordinates.clear();
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 230;
      bottomMapPadding = 300;
      isDrawerOpened = true;

      status = "";
      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      carDetailsDriver = "";
      tripStatusDisplay = 'Driver is Arriving';
    });
    _geoListenerPaused = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || mapController == null) return;
      final pos = currentPositionOfUser;
      if (pos != null) {
        _lastGeoCenterLat = pos.latitude;
        _lastGeoCenterLng = pos.longitude;
        await _startGeoFireQuery(pos.latitude, pos.longitude, _lastGeoRadiusKm);
      } else {
        await _onMapCameraIdle();
      }
    });
  }

  cancelRideRequest() {
    if (currentTripId != null) {
      http.put(
        Uri.parse("$_awsApiBaseUrl/trips/$currentTripId"),
        headers: {
          "Authorization": "Bearer public-migration-token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"status": "cancelled"}),
      );
    }
    tripPollTimer?.cancel();
    tripPollTimer = null;
    currentTripId = null;
    if (mounted) {
      setState(() {
        stateOfApp = "normal";
      });
    }
  }

  displayRequestContainer() {
    if (mounted) {
      setState(() {
        rideDetailsContainerHeight = 0;
        requestContainerHeight = 220;
        bottomMapPadding = 200;
        isDrawerOpened = true;
      });
    }

    //send ride request
    makeTripRequest();
  }

  bool _isInVisibleMap(LatLng p) {
    final b = _visibleMapBounds;
    if (b == null) return true;
    return b.contains(p);
  }

  double _radiusKmFromBounds(LatLngBounds b) {
    final ne = b.northeast;
    final sw = b.southwest;
    final latKm = (ne.latitude - sw.latitude).abs() * 111.0;
    final midLat = (ne.latitude + sw.latitude) / 2;
    final lngKm = (ne.longitude - sw.longitude).abs() *
        111.0 *
        math.cos(midLat * math.pi / 180);
    final halfDiag = math.sqrt(latKm * latKm + lngKm * lngKm) / 2;
    return halfDiag.clamp(5.0, 50.0);
  }

  double _metersBetween(LatLng a, LatLng b) {
    final d = ll.Distance();
    return d.distance(
      ll.LatLng(a.latitude, a.longitude),
      ll.LatLng(b.latitude, b.longitude),
    ).toDouble();
  }

  Future<void> _onMapCameraIdle() async {
    if (!mounted || mapController == null || _geoListenerPaused) return;
    try {
      final bounds = await mapController!.getVisibleRegion();
      if (!mounted) return;
      setState(() => _visibleMapBounds = bounds);
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      final radiusKm = _radiusKmFromBounds(bounds);
      final moved = _lastGeoCenterLat == 0 && _lastGeoCenterLng == 0
          ? true
          : _metersBetween(
                  LatLng(_lastGeoCenterLat, _lastGeoCenterLng), center) >
              800;
      final zoomChanged = (radiusKm - _lastGeoRadiusKm).abs() > 8;
      if (moved || zoomChanged) {
        _lastGeoCenterLat = center.latitude;
        _lastGeoCenterLng = center.longitude;
        _lastGeoRadiusKm = radiusKm;
        await _startGeoFireQuery(center.latitude, center.longitude, radiusKm);
      } else {
        updateAvailableNearbyOnlineDriversOnMap();
      }
    } catch (_) {
      updateAvailableNearbyOnlineDriversOnMap();
    }
  }

  void _scheduleOnCameraIdle() {
    _cameraIdleDebounce?.cancel();
    _cameraIdleDebounce =
        Timer(const Duration(milliseconds: 350), () async {
      await _onMapCameraIdle();
    });
  }

  Future<void> _startGeoFireQuery(double lat, double lng, double radiusKm) async {
    if (_geoListenerPaused) return;
    await _geoFireSubscription?.cancel();
    _geoFireSubscription = null;
    Geofire.stopListener();
    Geofire.initialize("onlineDrivers");
    ManageDriversMethods.nearbyOnlineDriversList.clear();
    nearbyOnlineDriversKeysLoaded = false;

    _geoFireSubscription = Geofire.queryAtLocation(lat, lng, radiusKm)?.listen(
      (driverEvent) {
        if (driverEvent != null) {
          var onlineDriverChild = driverEvent["callBack"];

          switch (onlineDriverChild) {
            case Geofire.onKeyEntered:
              if (driverEvent["key"] != null &&
                  driverEvent["latitude"] != null &&
                  driverEvent["longitude"] != null) {
                OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
                onlineNearbyDrivers.uidDriver = driverEvent["key"];
                onlineNearbyDrivers.latDriver = driverEvent["latitude"];
                onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
                ManageDriversMethods.nearbyOnlineDriversList
                    .add(onlineNearbyDrivers);

                if (nearbyOnlineDriversKeysLoaded == true) {
                  updateAvailableNearbyOnlineDriversOnMap();
                }
              }
              break;

            case Geofire.onKeyExited:
              if (driverEvent["key"] != null) {
                ManageDriversMethods.removeDriverFromList(driverEvent["key"]);
                updateAvailableNearbyOnlineDriversOnMap();
              }
              break;

            case Geofire.onKeyMoved:
              if (driverEvent["key"] != null &&
                  driverEvent["latitude"] != null &&
                  driverEvent["longitude"] != null) {
                OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
                onlineNearbyDrivers.uidDriver = driverEvent["key"];
                onlineNearbyDrivers.latDriver = driverEvent["latitude"];
                onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
                ManageDriversMethods.updateOnlineNearbyDriversLocation(
                    onlineNearbyDrivers);
                updateAvailableNearbyOnlineDriversOnMap();
              }
              break;

            case Geofire.onGeoQueryReady:
              nearbyOnlineDriversKeysLoaded = true;
              updateAvailableNearbyOnlineDriversOnMap();
              break;
          }
        }
      },
    );
  }

  updateAvailableNearbyOnlineDriversOnMap() {
    if (!mounted) return;
    setState(() {
      markerCoordinates.removeWhere((key, _) => key.contains("driver ID = "));
      for (OnlineNearbyDrivers eachOnlineNearbyDriver
          in ManageDriversMethods.nearbyOnlineDriversList) {
        if (eachOnlineNearbyDriver.latDriver == null ||
            eachOnlineNearbyDriver.lngDriver == null) {
          continue;
        }
        final pos = LatLng(
          eachOnlineNearbyDriver.latDriver!,
          eachOnlineNearbyDriver.lngDriver!,
        );
        if (!_isInVisibleMap(pos)) continue;
        final key = "driver ID = ${eachOnlineNearbyDriver.uidDriver}";
        markerCoordinates[key] = pos;
      }
    });
  }

  makeTripRequest() {
    currentTripId = "trip-${DateTime.now().millisecondsSinceEpoch}";

    var pickUpLocation =
        Provider.of<AppInfoClass>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfoClass>(context, listen: false).dropOffLocation;

    // Guard against null locations
    if (pickUpLocation == null || dropOffDestinationLocation == null) {
      print('Error: Pickup or Drop-off location is null.');
      return;
    }

    Map<String, String> pickUpCoOrdinatesMap = {
      "latitude": pickUpLocation.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };

    Map<String, String> dropOffDestinationCoOrdinatesMap = {
      "latitude": dropOffDestinationLocation.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map<String, String> driverCoOrdinates = {
      "latitude": "",
      "longitude": "",
    };

    Map<String, dynamic> dataMap = {
      "tripID": currentTripId ?? "",
      "publishDateTime": DateTime.now().toString(),
      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickUpCoOrdinatesMap,
      "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
      "pickUpAddress": pickUpLocation.placeName,
      "dropOffAddress": dropOffDestinationLocation.placeName,
      "driverId": "waiting",
      "carDetails": "",
      "driverLocation": driverCoOrdinates,
      "driverName": "",
      "driverPhone": "",
      "driverPhoto": "",
      "fareAmount": _effectiveFare().toStringAsFixed(2),
      "status": "new",
      "vehicleType": selectedVehicle.toString(),
      "paymentMethod": selectedPaymentMethod,
      "promoCode": appliedPromo?["code"]?.toString() ?? "",
      "promoDiscountAmount": promoDiscountAmount.toStringAsFixed(2),
    };
    http.post(
      Uri.parse("$_awsApiBaseUrl/trips"),
      headers: {
        "Authorization": "Bearer public-migration-token",
        "Content-Type": "application/json"
      },
      body: jsonEncode(dataMap),
    );

    tripPollTimer?.cancel();
    tripPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (currentTripId == null) {
        timer.cancel();
        return;
      }
      final response = await http.get(
        Uri.parse("$_awsApiBaseUrl/trips/$currentTripId"),
        headers: {"Authorization": "Bearer public-migration-token"},
      );
      if (response.statusCode != 200) return;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (payload["item"] ?? {}) as Map;
      if ((payload["exists"] ?? false) != true || data.isEmpty) return;

      nameDriver = data["driverName"] ?? nameDriver;
      phoneNumberDriver = data["driverPhone"] ?? phoneNumberDriver;
      photoDriver = data["driverPhoto"] ?? photoDriver;
      carDetailsDriver = data["carDetails"] ?? carDetailsDriver;
      status = data["status"] ?? status;
      if (data["driverLocation"] != null) {
        var latitudeString = data["driverLocation"]["latitude"].toString();
        var longitudeString = data["driverLocation"]["longitude"].toString();

        // Ensure the latitude and longitude are not empty and valid numbers
        if (latitudeString.isNotEmpty && longitudeString.isNotEmpty) {
          try {
            double driverLatitude = double.parse(latitudeString);
            double driverLongitude = double.parse(longitudeString);

            // Update driver's current location
            LatLng driverCurrentLocationLatLng =
                LatLng(driverLatitude, driverLongitude);

            // Update status based on trip phase
            if (status == "accepted") {
              updateFromDriverCurrentLocationToPickUp(
                  driverCurrentLocationLatLng);
            } else if (status == "arrived") {
              setState(() {
                tripStatusDisplay = 'Driver has Arrived';
              });
            } else if (status == "ontrip") {
              updateFromDriverCurrentLocationToDropOffDestination(
                  driverCurrentLocationLatLng);
            }
          } catch (e) {
            // Log an error if parsing fails
            print('Error parsing driver location: $e');
          }
        } else {
          print('Driver latitude or longitude is empty.');
        }
      }

      if (status == "accepted") {
        displayTripDetailsContainer();
        _geoListenerPaused = true;
        unawaited(_geoFireSubscription?.cancel());
        _geoFireSubscription = null;
        Geofire.stopListener();

        setState(() {
          markerCoordinates.removeWhere((key, _) => key.contains("driver"));
        });
      }

      if (status == "ended") {
        // Parse the actual fare amount from the trip data
        double fareAmount = double.parse(data["fareAmount"].toString());

        var responseFromPaymentDialog = await showDialog(
          context: context,
          builder: (BuildContext context) => PaymentDialog(
            fareAmount: fareAmount.toString(),
            tripId: (data["tripID"] ?? currentTripId ?? "").toString(),
            userId: userID,
            preferredPaymentMethod:
                (data["paymentMethod"] ?? selectedPaymentMethod).toString(),
            promoCode: (data["promoCode"] ?? "").toString(),
          ),
        );

        if (responseFromPaymentDialog == "paid") {
          tripPollTimer?.cancel();
          tripPollTimer = null;
          currentTripId = null;

          resetAppNow();
        }
      }
    });
  }

  displayTripDetailsContainer() {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 295;
      bottomMapPadding = 281;
    });
  }

  updateFromDriverCurrentLocationToPickUp(
      LatLng driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      // Check if currentPositionOfUser is null
      if (currentPositionOfUser == null) {
        requestingDirectionDetailsInfo = false;
        return; // Early return to avoid further execution
      }

      final userPickUpLocationLatLng = ll.LatLng(
        currentPositionOfUser!.latitude,
        currentPositionOfUser!.longitude,
      );

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              ll.LatLng(
                driverCurrentLocationLatLng.latitude,
                driverCurrentLocationLatLng.longitude,
              ),
              userPickUpLocationLatLng);

      if (directionDetailsPickup == null) {
        requestingDirectionDetailsInfo =
            false; // Reset the flag in case of null
        return;
      }

      setState(() {
        tripStatusDisplay =
            "Driver is Coming ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  updateFromDriverCurrentLocationToDropOffDestination(
      LatLng driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      // Check if dropOffLocation is null
      var dropOffLocation =
          Provider.of<AppInfoClass>(context, listen: false).dropOffLocation;

      if (dropOffLocation == null) {
        requestingDirectionDetailsInfo = false;
        return; // Early return to avoid further execution
      }

      final userDropOffLocationLatLng = ll.LatLng(
        dropOffLocation.latitudePosition!,
        dropOffLocation.longitudePosition!,
      );

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              ll.LatLng(
                driverCurrentLocationLatLng.latitude,
                driverCurrentLocationLatLng.longitude,
              ),
              userDropOffLocationLatLng);

      if (directionDetailsPickup == null) {
        requestingDirectionDetailsInfo =
            false; // Reset the flag in case of null
        return;
      }

      setState(() {
        tripStatusDisplay =
            "Drop Off Location ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  noDriverAvailable() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => InfoDialog(
        title: "No Driver Available",
        description:
            "No driver found in the nearby location. Please try again shortly.",
      ),
    );
  }

  searchDriver() {
    if (availableNearbyOnlineDriversList!.length == 0) {
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }

    var currentDriver = availableNearbyOnlineDriversList![0];

    //send notification to this currentDriver - currentDriver means selected driver
    sendNotificationToDriver(currentDriver);

    availableNearbyOnlineDriversList!.removeAt(0);
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    if (currentTripId == null || currentDriver.uidDriver == null) {
      print("Error: tripRequestRef or driver UID is null.");
      return;
    }
    http.get(
      Uri.parse("$_awsApiBaseUrl/drivers/${currentDriver.uidDriver}"),
      headers: {"Authorization": "Bearer public-migration-token"},
    ).then((resp) {
      if (resp.statusCode != 200) return;
      final payload = jsonDecode(resp.body) as Map<String, dynamic>;
      final item = (payload["item"] ?? {}) as Map;
      final deviceToken = item["deviceToken"]?.toString() ?? "";
      if (deviceToken.isNotEmpty) {
        PushNotificationService.sendNotificationToSelectedDriver(
          deviceToken,
          context,
          currentTripId!,
        );
      }

      const oneTickPerSec = Duration(seconds: 1);
      Timer? timer;

      try {
        timer = Timer.periodic(oneTickPerSec, (timer) {
          requestTimeoutDriver = requestTimeoutDriver - 1;

          // When trip request is canceled or state changes
          if (stateOfApp != "requesting") {
            timer.cancel();
            requestTimeoutDriver = 40;
          }

          // If timeout occurs after 40 seconds, notify the next available driver
          if (requestTimeoutDriver == 0) {
            timer.cancel();
            requestTimeoutDriver = 40;

            // Search for the next available driver
            searchDriver();
          }
        });
      } catch (e) {
        print("Error during timer execution: $e");
        timer?.cancel();
      }
    }).catchError((error) {
      print("Error fetching driver's device token: $error");
    });
  }

  CommonMethods commonMethods = CommonMethods();

  @override
  void dispose() {
    tripPollTimer?.cancel();
    _cameraIdleDebounce?.cancel();
    _geoFireSubscription?.cancel();
    Geofire.stopListener();
    super.dispose();
  }

  double _effectiveFare() {
    final multipliers = {"Economy": 1.0, "Comfort": 1.18, "XL": 1.35};
    final base = actualFareAmountCar * (multipliers[selectedVehicle] ?? 1.0);
    final discounted = base - promoDiscountAmount;
    return discounted > 0 ? discounted : 0;
  }

  double _competitorReferenceFare() {
    // We position Velo as 5% cheaper than comparable market fares.
    final fare = _effectiveFare();
    if (fare <= 0) return 0;
    return fare / 0.95;
  }

  Future<void> applyPromoCode(String promoCode, {bool silent = false}) async {
    final code = promoCode.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      appliedPromo = null;
      promoDiscountAmount = 0;
    });
    try {
      final response = await http.get(
        Uri.parse(
            "$_awsApiBaseUrl/promos/by-code/${Uri.encodeComponent(code)}"),
        headers: {"Authorization": "Bearer public-migration-token"},
      );
      if (response.statusCode != 200) {
        return;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final exists = (payload["exists"] ?? false) == true;
      if (!exists || payload["item"] == null) {
        return;
      }
      final promo = Map<String, dynamic>.from(payload["item"] as Map);
      final targetType = (promo["targetType"] ?? "all").toString();
      final List<String> eligibleUserIds =
          ((promo["eligibleUserIds"] ?? []) as List)
              .map((e) => e.toString())
              .toList();
      if (targetType == "specific" && !eligibleUserIds.contains(userID)) {
        return;
      }
      final userResponse = await http.get(
        Uri.parse("$_awsApiBaseUrl/users/$userID"),
        headers: {"Authorization": "Bearer public-migration-token"},
      );
      if (userResponse.statusCode == 200) {
        final userPayload =
            jsonDecode(userResponse.body) as Map<String, dynamic>;
        final userItem = (userPayload["item"] ?? {}) as Map;
        final usedCodes = ((userItem["usedPromoCodes"] ?? []) as List)
            .map((e) => e.toString().toUpperCase())
            .toList();
        if (usedCodes.contains(code)) {
          return;
        }
      }
      final isActive = promo["isActive"] == true;
      final validTill = DateTime.tryParse(promo["validTill"]?.toString() ?? "");
      if (!isActive ||
          (validTill != null && DateTime.now().isAfter(validTill))) {
        return;
      }
      final usageLimit =
          int.tryParse((promo["usageLimit"] ?? "0").toString()) ?? 0;
      final usedCount =
          int.tryParse((promo["usedCount"] ?? "0").toString()) ?? 0;
      if (usageLimit > 0 && usedCount >= usageLimit) {
        return;
      }

      final base =
          selectedVehicle == "Car" ? actualFareAmountCar : actualFareAmount;
      double discount = 0.0;
      final discountType = (promo["discountType"] ?? "percent").toString();
      final discountValue =
          double.tryParse((promo["discountValue"] ?? "0").toString()) ?? 0.0;
      if (discountType == "fixed") {
        discount = discountValue;
      } else {
        discount = (base * discountValue) / 100;
        final maxCap =
            double.tryParse((promo["maxDiscountAmount"] ?? "0").toString()) ??
                0.0;
        if (maxCap > 0 && discount > maxCap) {
          discount = maxCap;
        }
      }
      if (discount > base) discount = base;
      setState(() {
        appliedPromo = promo;
        promoDiscountAmount = discount;
      });
      if (!silent && mounted) {
        cMethods.displaySnackBar(
          "Promo applied. You saved JOD ${discount.toStringAsFixed(2)}",
          context,
        );
      }
    } finally {
      // no-op
    }
  }

  Future<bool> _hasEnoughWalletBalance(double amount) async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/users/$userID"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) return false;
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final item = (payload["item"] ?? {}) as Map;
    final wallet =
        double.tryParse(item["walletBalance"]?.toString() ?? "0") ?? 0;
    return wallet >= amount;
  }

  Future<void> _selectPointFromMap(LatLng point) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text("Set as pickup"),
              onTap: () => Navigator.pop(context, "pickup"),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Set as dropoff"),
              onTap: () => Navigator.pop(context, "dropoff"),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final address = AddressModel(
      placeName:
          "${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}",
      humanReadableAddress:
          "${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}",
      latitudePosition: point.latitude,
      longitudePosition: point.longitude,
      placeID: "${point.latitude},${point.longitude}",
    );
    if (choice == "pickup") {
      Provider.of<AppInfoClass>(context, listen: false)
          .updatePickUpLocation(address);
      cMethods.displaySnackBar("Pickup location updated from map.", context);
    } else {
      Provider.of<AppInfoClass>(context, listen: false)
          .updateDropOffLocation(address);
      cMethods.displaySnackBar("Dropoff location updated from map.", context);
      await displayUserRideDetailsContainer();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userAddress = Provider.of<AppInfoClass>(context, listen: false)
                .pickUpLocation !=
            null
        ? (Provider.of<AppInfoClass>(context, listen: false)
                    .pickUpLocation!
                    .placeName!
                    .length >
                35
            ? "${Provider.of<AppInfoClass>(context, listen: false).pickUpLocation!.placeName!.substring(0, 35)}..."
            : Provider.of<AppInfoClass>(context, listen: false)
                .pickUpLocation!
                .placeName)
        : 'Fetching Your Current Location.';

    if (tripDirectionDetailsInfo != null) {
      var fareString = cMethods.calculateFareAmountInJOD(
        tripDirectionDetailsInfo!,
      ); // Save the fare amount
      actualFareAmountCar = double.tryParse(fareString) ?? 0.0;
      estimatedTimeCar =
          tripDirectionDetailsInfo!.durationTextString.toString();
    }

    void calculateFareAndTime() {
      setState(() {
        actualFareAmount = _effectiveFare();
        estimatedTime = estimatedTimeCar;
      });
    }

    if (tripDirectionDetailsInfo != null) {
      calculateFareAndTime();
    }

    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    final appProvider = Provider.of<AppInfoClass>(context, listen: false);

    return SafeArea(
      child: Scaffold(
        key: sKey,
        drawer: CustomDrawer(userName: userName, authProvider: authProvider),
        body: Stack(
          children: [
            ///map area
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              initialCameraPosition:
                  CameraPosition(target: initialMapCenter, zoom: 13),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _scheduleOnCameraIdle();
              },
              onCameraIdle: _scheduleOnCameraIdle,
              onLongPress: _selectPointFromMap,
              polylines: {
                if (polylineCoOrdinates.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId("main_route"),
                    points: polylineCoOrdinates,
                    width: 5,
                    color: const Color(0xFF6366F1),
                  ),
              },
              circles: circleCoordinates.entries
                  .map(
                    (entry) => Circle(
                      circleId: CircleId(entry.key),
                      center: entry.value,
                      radius: 70,
                      fillColor: const Color(0x336366F1),
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF6366F1),
                    ),
                  )
                  .toSet(),
              markers: markerCoordinates.entries.map((entry) {
                final isDriver = entry.key.contains("driver ID = ");
                final BitmapDescriptor icon;
                if (isDriver) {
                  icon = _carMarkerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure);
                } else {
                  icon =
                      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
                }
                return Marker(
                  markerId: MarkerId(entry.key),
                  position: entry.value,
                  icon: icon,
                  anchor: isDriver ? const Offset(0.5, 0.5) : const Offset(0.5, 1.0),
                  flat: false,
                  infoWindow: const InfoWindow(),
                );
              }).toSet(),
            ),

            ///drawer button
            Positioned(
              top: 20,
              left: 20,
              child: Material(
                elevation: 12,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (isDrawerOpened == true) {
                      sKey.currentState!.openDrawer();
                    } else {
                      resetAppNow();
                    }
                  },
                  child: Ink(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Icon(
                      isDrawerOpened == true
                          ? Icons.menu_rounded
                          : Icons.close_rounded,
                      color: const Color(0xFF0F172A),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSize(
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 280),
                child: searchContainerHeight == 0
                    ? const SizedBox.shrink()
                    : VeloFloatingSheet(
                        dark: false,
                        showHandle: false,
                        child: SizedBox(
                          height: searchContainerHeight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final responseFromSearchPage =
                                        await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) =>
                                            const SearchDestinationPlace
                                                .forPickup(),
                                      ),
                                    );
                                    if (responseFromSearchPage ==
                                            "placeSelected" &&
                                        mounted) {
                                      setState(() {});
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.add_location_alt_outlined,
                                        color: Color(0xFFD90429),
                                      ),
                                      const SizedBox(
                                        width: 13,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "From",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87),
                                          ),
                                          Text(
                                            userAddress!,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(color: Color(0x22000000)),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.add_location_alt_outlined,
                                      color: Color(0xFFD90429),
                                    ),
                                    const SizedBox(
                                      width: 13,
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        var responseFromSearchPage =
                                            await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (c) =>
                                                        const SearchDestinationPlace
                                                            .forDropOff()));

                                        if (responseFromSearchPage ==
                                            "placeSelected") {
                                          displayUserRideDetailsContainer();
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "To",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87),
                                          ),
                                          Text(
                                            appProvider.dropOffLocation
                                                    ?.placeName ??
                                                "Where would you like to go?",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                const Divider(color: Color(0x22000000)),
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.savings_outlined,
                                        size: 16,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Always 5% cheaper than comparable apps",
                                          style: TextStyle(
                                            color: Color(0xFF1E40AF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: const Color(0xFFD90429),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      "Select Destination",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () async {
                                      var responseFromSearchPage =
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (c) =>
                                                      const SearchDestinationPlace
                                                          .forDropOff()));

                                      if (responseFromSearchPage ==
                                          "placeSelected") {
                                        displayUserRideDetailsContainer();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            ///ride details container
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: rideDetailsContainerHeight == 0
                  ? const SizedBox.shrink()
                  : VeloFloatingSheet(
                      dark: true,
                      showHandle: true,
                      child: SizedBox(
                        height: rideDetailsContainerHeight,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Choose Tier",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  for (final tier in const [
                                    "Economy",
                                    "Comfort",
                                    "XL"
                                  ])
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(tier),
                                          selected: selectedVehicle == tier,
                                          onSelected: (_) {
                                            setState(
                                                () => selectedVehicle = tier);
                                            calculateFareAndTime();
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: [
                                  FittedBox(
                                    child: Image.asset(
                                      "assets/images/initial.png",
                                      width: 20,
                                      height: 40,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      // First check if pickUpLocation is null, then access placeName
                                      (appProvider.pickUpLocation != null &&
                                              appProvider.pickUpLocation!
                                                      .placeName !=
                                                  null)
                                          ? appProvider
                                              .pickUpLocation!.placeName
                                              .toString()
                                          : "Location not available", // Fallback text if null
                                      style:
                                          const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  FittedBox(
                                    child: Image.asset(
                                      "assets/images/final.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      // First check if dropOffLocation and placeName are not null
                                      (appProvider.dropOffLocation != null &&
                                              appProvider.dropOffLocation!
                                                      .placeName !=
                                                  null)
                                          ? appProvider
                                              .dropOffLocation!.placeName
                                              .toString()
                                          : "Location not available", // Fallback text if null
                                      style:
                                          const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Verified drivers",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.support_agent_outlined,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "24/7 support",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              const Divider(
                                thickness: 2.0,
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.travel_explore_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Total Distance",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          (tripDirectionDetailsInfo != null)
                                              ? tripDirectionDetailsInfo!
                                                  .distanceTextString!
                                              : "",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.time_to_leave,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Estimated Time",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          estimatedTimeCar,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              const Divider(
                                thickness: 2.0,
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.money_sharp,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Fare Fee",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Text(
                                                  "JOD ${_effectiveFare().toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          appliedPromo == null
                                              ? "Includes 5% rider discount"
                                              : "Promo ${appliedPromo!["code"]}: -JOD ${promoDiscountAmount.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          "You save JOD ${(_competitorReferenceFare() - _effectiveFare()).toStringAsFixed(2)} vs market estimate",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Promo can be managed in Account > Promotions",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.payment,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Payment Method",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Row(
                                                  children: [
                                                    ChoiceChip(
                                                      label: const Text("Cash"),
                                                      selected:
                                                          selectedPaymentMethod ==
                                                              "Cash",
                                                      onSelected: (_) {
                                                        setState(() {
                                                          selectedPaymentMethod =
                                                              "Cash";
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ChoiceChip(
                                                      label:
                                                          const Text("Wallet"),
                                                      selected:
                                                          selectedPaymentMethod ==
                                                              "Wallet",
                                                      onSelected: (_) {
                                                        setState(() {
                                                          selectedPaymentMethod =
                                                              "Wallet";
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: const Color(0xFFD90429),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    "Find Driver",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
                                    if (selectedPaymentMethod == "Wallet") {
                                      final enough =
                                          await _hasEnoughWalletBalance(
                                              _effectiveFare());
                                      if (!enough) {
                                        if (!context.mounted) return;
                                        commonMethods.displaySnackBar(
                                          "Insufficient wallet balance for this trip.",
                                          context,
                                        );
                                        return;
                                      }
                                    }
                                    setState(() {
                                      stateOfApp = "requesting";
                                      displayRequestContainer();
                                      availableNearbyOnlineDriversList =
                                          ManageDriversMethods
                                              .nearbyOnlineDriversList;
                                      searchDriver();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            ///request container
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: requestContainerHeight == 0
                  ? const SizedBox.shrink()
                  : VeloFloatingSheet(
                      dark: true,
                      showHandle: true,
                      child: SizedBox(
                        height: requestContainerHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 12,
                              ),
                              const Text(
                                "Searching for nearby drivers...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              SizedBox(
                                width: 200,
                                child: LoadingAnimationWidget.flickr(
                                  leftDotColor: Colors.greenAccent,
                                  rightDotColor: Colors.pinkAccent,
                                  size: 50,
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              GestureDetector(
                                onTap: () {
                                  resetAppNow();
                                  cancelRideRequest();
                                },
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white70,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                        width: 1.5, color: Colors.grey),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black,
                                    size: 25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            ///trip details container
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: tripContainerHeight == 0
                  ? const SizedBox.shrink()
                  : VeloFloatingSheet(
                      dark: true,
                      showHandle: true,
                      child: SizedBox(
                        height: tripContainerHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 5,
                              ),
                              //trip status display text
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tripStatusDisplay,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      color: Colors.white,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 19,
                              ),

                              const Divider(
                                height: 1,
                                color: Colors.white,
                                thickness: 1,
                              ),

                              const SizedBox(
                                height: 19,
                              ),

                              //image - driver name and driver car details
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      photoDriver == ''
                                          ? "https://firebasestorage.googleapis.com/v0/b/everyone-2de50.appspot.com/o/avatarman.png?alt=media&token=702d209c-9f99-46b2-832f-5bb986bc5eac"
                                          : photoDriver,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nameDriver,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        carDetailsDriver,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 15,
                              ),

                              const Divider(
                                height: 1,
                                color: Colors.white,
                                thickness: 1,
                              ),

                              const SizedBox(
                                height: 15,
                              ),

                              //call driver btn
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      launchUrl(Uri.parse(
                                          "tel://$phoneNumberDriver"));
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 50,
                                          width: 50,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(25)),
                                            border: Border.all(
                                              width: 1,
                                              color: Colors.white,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.phone,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 11,
                                        ),
                                        const Text(
                                          "Call",
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
