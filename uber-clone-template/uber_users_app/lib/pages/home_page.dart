import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/observability/analytics_service.dart';
import 'package:uber_users_app/pages/search_destination_place.dart';
import 'package:uber_users_app/pages/support_page.dart';
import 'package:uber_users_app/widgets/post_trip_feedback_sheet.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';
import 'package:uber_users_app/widgets/custome_drawer.dart';
import 'package:uber_users_app/widgets/active_ride/active_trip_sheet.dart';
import 'package:uber_users_app/widgets/active_ride/in_trip_safety_sheet.dart';
import 'package:uber_users_app/widgets/active_ride/requesting_driver_sheet.dart';
import 'package:uber_users_app/widgets/active_ride/ride_tier_sheet.dart';
import '../global/global_var.dart';
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
  // Trip/driver state (migrated from global/trip_var.dart)
  String nameDriver = '';
  String photoDriver = '';
  String phoneNumberDriver = '';
  String carDetailsDriver = '';
  String plateDriver = '';
  int requestTimeoutDriver = 40;
  String status = '';
  String tripStatusDisplay = 'Driver is Arriving';

  GoogleMapController? mapController;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 360;
  double bottomMapPadding = 360;
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
  List<OnlineNearbyDrivers> availableNearbyOnlineDriversList = <OnlineNearbyDrivers>[];
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
  bool _recalcQueued = false;
  bool _homeSheetExpanded = false;
  bool _tripActiveFunnelLogged = false;
  String? _mapPickTarget; // "pickup" | "dropoff" | null
  // GeoFire driver map updates are optional; keep off to avoid crashes on
  // misconfigured Firebase/GeoFire setups.
  // Note: ride-requesting depends on a non-empty nearby drivers list.
  // We keep the GeoFire startup wrapped in try/catch elsewhere so enabling this
  // won't crash the app even if RTDB/GeoFire is misconfigured.
  static const bool _enableNearbyDrivers = true;

  void _recalculateFareAndTime() {
    if (!mounted) return;
    setState(() {
      actualFareAmountCar = 0.0;
      estimatedTimeCar = "";
      if (tripDirectionDetailsInfo != null) {
        final fareString = cMethods.calculateFareAmountInJOD(tripDirectionDetailsInfo!);
        actualFareAmountCar = double.tryParse(fareString) ?? 0.0;
        estimatedTimeCar = tripDirectionDetailsInfo!.durationTextString?.toString() ?? "";
      }
      actualFareAmount = _effectiveFare();
      estimatedTime = estimatedTimeCar;
    });
  }

  void _queueRecalculateFareAndTime() {
    if (_recalcQueued) return;
    _recalcQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalcQueued = false;
      _recalculateFareAndTime();
    });
  }

  /// Nearby drivers on map (GeoFire live updates) — no personal info shown.
  StreamSubscription<dynamic>? _geoFireSubscription;
  BitmapDescriptor? _carMarkerIcon;
  LatLngBounds? _visibleMapBounds;
  Timer? _cameraIdleDebounce;
  bool _geoListenerPaused = false;
  double _lastGeoCenterLat = 0;
  double _lastGeoCenterLng = 0;
  double _lastGeoRadiusKm = 30;

  // Debug-only: allow a demo driver to accept rides automatically so you can
  // navigate active ride / arrived / ontrip screens without real drivers.
  static const bool _enableDemoDriver = kDebugMode;
  Timer? _demoArrivedTimer;
  Timer? _demoOnTripTimer;
  Timer? _demoEndedTimer;

  void _cancelDemoDriverTimers() {
    _demoArrivedTimer?.cancel();
    _demoOnTripTimer?.cancel();
    _demoEndedTimer?.cancel();
    _demoArrivedTimer = null;
    _demoOnTripTimer = null;
    _demoEndedTimer = null;
  }

  Future<void> _startDemoDriverFlow() async {
    if (!mounted) return;
    _cancelDemoDriverTimers();

    // Immediately "accept" so the trip UI becomes available.
    setState(() {
      status = "accepted";
      nameDriver = "Test Driver";
      phoneNumberDriver = "0790000000";
      photoDriver = "";
      carDetailsDriver = "Velo Demo • White Sedan";
      plateDriver = "DEMO-77";
      tripStatusDisplay = "Driver is Coming (demo)";
    });

    displayTripDetailsContainer();

    // Then step through phases so you can view each state.
    _demoArrivedTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || stateOfApp != "requesting") return;
      setState(() {
        status = "arrived";
        tripStatusDisplay = "Driver has Arrived (demo)";
      });
    });

    _demoOnTripTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || stateOfApp != "requesting") return;
      setState(() {
        status = "ontrip";
        tripStatusDisplay = "On trip (demo)";
      });
    });

    _demoEndedTimer = Timer(const Duration(seconds: 22), () async {
      if (!mounted || stateOfApp != "requesting") return;
      setState(() {
        status = "ended";
        tripStatusDisplay = "Trip ended (demo)";
      });

      // Show the existing payment flow so you can reach post-trip UI.
      if (!mounted) return;
      final responseFromPaymentDialog = await showDialog(
        context: context,
        builder: (context) => PaymentDialog(
          fareAmount: _effectiveFare().toStringAsFixed(2),
          tripId: currentTripId ?? "demo-trip",
          userId: userID,
          preferredPaymentMethod: selectedPaymentMethod,
          promoCode: appliedPromo?["code"]?.toString() ?? "",
        ),
      );

      if (!mounted) return;
      if (responseFromPaymentDialog == "paid") {
        await _handleTripPaid(selectedPaymentMethod);
      }
    });
  }

  Future<void> _handleTripPaid(String paymentMethod) async {
    await AnalyticsService.logPaymentCompleted(method: paymentMethod);
    final savedDriverName = nameDriver;
    final savedDriverPhoto = photoDriver;
    final savedTripId = currentTripId;
    tripPollTimer?.cancel();
    tripPollTimer = null;
    currentTripId = null;
    _cancelDemoDriverTimers();
    resetAppNow();
    if (!mounted) return;
    await PostTripFeedbackSheet.show(
      context,
      driverName: savedDriverName,
      driverPhotoUrl: savedDriverPhoto,
      tripId: savedTripId,
    );
  }

  Future<void> _openSafetySheet() async {
    unawaited(AnalyticsService.logSafetySheetOpened());
    if (!mounted) return;
    final result = await InTripSafetySheet.show(context);
    if (!mounted) return;
    if (result == "share") {
      unawaited(AnalyticsService.logTripShared());
      final msg = context.l10n.shareTripMessage(
        currentTripId ?? "",
        nameDriver.isEmpty ? context.l10n.yourDriver : nameDriver,
        carDetailsDriver.isEmpty ? "—" : carDetailsDriver,
        plateDriver.isEmpty ? "—" : plateDriver,
      );
      await Share.share(msg, subject: context.l10n.shareTripSubject);
    } else if (result == "support") {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SupportPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Start Home with a compact "Where to?" entry; expand on tap.
    searchContainerHeight = 160;
    bottomMapPadding = 160;
    _loadSavedPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        _carMarkerIcon = await createCarMarkerBitmapDescriptor();
        if (mounted) setState(() {});
      } catch (_) {
        // Marker icon is optional; fall back to default marker.
      }
      try {
        await getCurrentLiveLocationOfUser();
      } catch (_) {
        // Home must never crash due to async startup failures.
      }
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
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        cMethods.displaySnackBar(
          context.l10n.locationServicesDisabled,
          context,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        cMethods.displaySnackBar(
          context.l10n.locationPermissionDeniedLimited,
          context,
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        cMethods.displaySnackBar(
          context.l10n.locationPermissionDeniedForever,
          context,
        );
        return;
      }

      final positionOfUser = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      if (!mounted) return;
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

      try {
        await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
            currentPositionOfUser!, context);
      } catch (_) {}
      if (!context.mounted) return;

      try {
        await getUserInfoAndCheckBlockStatus();
      } catch (_) {}
      if (!context.mounted) return;

      _lastGeoCenterLat = currentPositionOfUser!.latitude;
      _lastGeoCenterLng = currentPositionOfUser!.longitude;
      if (_enableNearbyDrivers) {
        try {
          await _startGeoFireQuery(
            currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude,
            30,
          );
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      cMethods.displaySnackBar(
        context.l10n.couldNotGetLocation,
        context,
      );
    }
  }

  getUserInfoAndCheckBlockStatus() async {
    // If the session hasn't loaded yet, don't treat it as an auth failure.
    if (userID.trim().isEmpty) return;

    final response = await ApiClient.get("/users/$userID");
    if (response.statusCode != 200) {
      if (!mounted) return;
      await Provider.of<AuthenticationProvider>(context, listen: false)
          .signOut(context);
      return;
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final item = (payload["item"] ?? {}) as Map;
    if ((payload["exists"] ?? false) != true || item.isEmpty) {
      if (!mounted) return;
      await Provider.of<AuthenticationProvider>(context, listen: false)
          .signOut(context);
      return;
    }
    final blockStatus = item["blockStatus"]?.toString() ?? "no";
    if (blockStatus != "no") {
      if (!mounted) return;
      final blockedMsg = context.l10n.blockedContactAdmin("gulzarsoft@gmail.com");
      await Provider.of<AuthenticationProvider>(context, listen: false)
          .signOut(context);
      if (!mounted) return;
      cMethods.displaySnackBar(blockedMsg, context);
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
        bottomMapPadding = 320;
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

    if (pickUpLocation == null || dropOffDestinationLocation == null) {
      if (!mounted) return;
      cMethods.displaySnackBar(
        context.l10n.pleaseSelectPickupAndDropoff,
        context,
      );
      return;
    }

    final pickupGeoGraphicCoOrdinates = ll.LatLng(
        pickUpLocation.latitudePosition!, pickUpLocation.longitudePosition!);
    final dropOffDestinationGeoGraphicCoOrdinates = ll.LatLng(
        dropOffDestinationLocation.latitudePosition!,
        dropOffDestinationLocation.longitudePosition!);
    final pickupMapLatLng = LatLng(
      pickUpLocation.latitudePosition!,
      pickUpLocation.longitudePosition!,
    );
    final dropOffMapLatLng = LatLng(
      dropOffDestinationLocation.latitudePosition!,
      dropOffDestinationLocation.longitudePosition!,
    );

    final navigator = Navigator.of(context);
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: context.l10n.gettingDirections),
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
    _queueRecalculateFareAndTime();

    if (!mounted) return;
    navigator.pop();

    if (detailsFromDirectionAPI == null ||
        detailsFromDirectionAPI.encodedPoints == null ||
        detailsFromDirectionAPI.encodedPoints!.trim().isEmpty) {
      cMethods.displaySnackBar(context.l10n.couldNotGetDirections, context);
      return;
    }

    //draw route from pickup to dropOffDestination
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination =
        pointsPolyline.decodePolyline(detailsFromDirectionAPI.encodedPoints!);

    polylineCoOrdinates.clear();
    for (final latLngPoint in latLngPointsFromPickUpToDestination) {
      polylineCoOrdinates.add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
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
      searchContainerHeight = 360;
      bottomMapPadding = 360;
      isDrawerOpened = true;
      _homeSheetExpanded = false;

      status = "";
      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      carDetailsDriver = "";
      plateDriver = "";
      tripStatusDisplay = 'Driver is Arriving';
      _tripActiveFunnelLogged = false;
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
      ApiClient.put("/trips/$currentTripId", body: {"status": "cancelled"});
    }
    _cancelDemoDriverTimers();
    tripPollTimer?.cancel();
    tripPollTimer = null;
    currentTripId = null;
    plateDriver = "";
    _tripActiveFunnelLogged = false;
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
        bottomMapPadding = 260;
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
    const d = ll.Distance();
    return d.distance(
      ll.LatLng(a.latitude, a.longitude),
      ll.LatLng(b.latitude, b.longitude),
    ).toDouble();
  }

  Future<void> _onMapCameraIdle() async {
    if (!mounted || mapController == null || _geoListenerPaused) return;
    // GeoFire live driver updates are optional; don't run background queries unless enabled.
    if (!_enableNearbyDrivers) return;
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
    if (!_enableNearbyDrivers) return;
    _cameraIdleDebounce?.cancel();
    _cameraIdleDebounce =
        Timer(const Duration(milliseconds: 350), () async {
      await _onMapCameraIdle();
    });
  }

  Future<void> _startGeoFireQuery(double lat, double lng, double radiusKm) async {
    if (_geoListenerPaused) return;
    try {
      await _geoFireSubscription?.cancel();
    } catch (_) {}
    _geoFireSubscription = null;
    try {
      Geofire.stopListener();
    } catch (_) {}
    try {
      Geofire.initialize("onlineDrivers");
    } catch (_) {
      // If GeoFire isn't configured (or Firebase RTDB is missing), don't crash Home.
      return;
    }
    ManageDriversMethods.nearbyOnlineDriversList.clear();
    nearbyOnlineDriversKeysLoaded = false;

    try {
      _geoFireSubscription =
          Geofire.queryAtLocation(lat, lng, radiusKm)?.listen((driverEvent) {
        try {
          if (driverEvent == null) return;
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
        } catch (_) {}
      });
    } catch (_) {
      // Ignore GeoFire query errors.
      return;
    }
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
    ApiClient.post("/trips", body: dataMap);

    tripPollTimer?.cancel();
    tripPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (currentTripId == null) {
        timer.cancel();
        return;
      }
      final response = await ApiClient.get("/trips/$currentTripId");
      if (response.statusCode != 200) return;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (payload["item"] ?? {}) as Map;
      if ((payload["exists"] ?? false) != true || data.isEmpty) return;

      nameDriver = data["driverName"] ?? nameDriver;
      phoneNumberDriver = data["driverPhone"] ?? phoneNumberDriver;
      photoDriver = data["driverPhoto"] ?? photoDriver;
      carDetailsDriver = data["carDetails"] ?? carDetailsDriver;
      plateDriver = data["vehiclePlate"]?.toString() ??
          data["plateNumber"]?.toString() ??
          plateDriver;
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

            if (status == "accepted") {
              updateFromDriverCurrentLocationToPickUp(
                  driverCurrentLocationLatLng);
            } else if (status == "arrived") {
              if (!mounted) return;
              setState(() {
                tripStatusDisplay = 'Driver has Arrived';
              });
            } else if (status == "ontrip") {
              updateFromDriverCurrentLocationToDropOffDestination(
                  driverCurrentLocationLatLng);
            }
          } catch (_) {}
        }
      }

      if (status == "accepted") {
        displayTripDetailsContainer();
        _geoListenerPaused = true;
        unawaited(_geoFireSubscription?.cancel());
        _geoFireSubscription = null;
        Geofire.stopListener();

        if (!mounted) return;
        setState(() {
          markerCoordinates.removeWhere((key, _) => key.contains("driver"));
        });
      }

      if (status == "ended") {
        // Parse the actual fare amount from the trip data
        double fareAmount = double.parse(data["fareAmount"].toString());

        if (!mounted) return;
        var responseFromPaymentDialog = await showDialog(
          context: context,
          builder: (context) => PaymentDialog(
            fareAmount: fareAmount.toString(),
            tripId: (data["tripID"] ?? currentTripId ?? "").toString(),
            userId: userID,
            preferredPaymentMethod:
                (data["paymentMethod"] ?? selectedPaymentMethod).toString(),
            promoCode: (data["promoCode"] ?? "").toString(),
          ),
        );

        if (!mounted) return;
        if (responseFromPaymentDialog == "paid") {
          final method =
              (data["paymentMethod"] ?? selectedPaymentMethod).toString();
          await _handleTripPaid(method);
        }
      }
    });
  }

  displayTripDetailsContainer() {
    if (!_tripActiveFunnelLogged) {
      _tripActiveFunnelLogged = true;
      unawaited(AnalyticsService.logTripActive());
    }
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 295;
      bottomMapPadding = 320;
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
        requestingDirectionDetailsInfo = false;
        return;
      }

      if (mounted) {
        setState(() {
          tripStatusDisplay =
              "Driver is Coming ${directionDetailsPickup.durationTextString}";
        });
      }

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
        requestingDirectionDetailsInfo = false;
        return;
      }

      if (mounted) {
        setState(() {
          tripStatusDisplay =
              "Drop Off Location ${directionDetailsPickup.durationTextString}";
        });
      }

      requestingDirectionDetailsInfo = false;
    }
  }

  noDriverAvailable() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const InfoDialog(
        title: "No Driver Available",
        description:
            "No driver found in the nearby location. Please try again shortly.",
      ),
    );
  }

  searchDriver() {
    if (availableNearbyOnlineDriversList.isEmpty) {
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }

    final currentDriver = availableNearbyOnlineDriversList.first;

    //send notification to this currentDriver - currentDriver means selected driver
    sendNotificationToDriver(currentDriver);

    if (availableNearbyOnlineDriversList.isNotEmpty) {
      availableNearbyOnlineDriversList.removeAt(0);
    }
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    if (currentTripId == null || currentDriver.uidDriver == null) {
      return;
    }
    final app = Provider.of<AppInfoClass>(context, listen: false);
    final pickUp = app.pickUpLocation?.placeName?.toString() ?? "";
    final dropOff = app.dropOffLocation?.placeName?.toString() ?? "";
    ApiClient.get("/drivers/${currentDriver.uidDriver}").then((resp) {
      if (resp.statusCode != 200) return;
      final payload = jsonDecode(resp.body) as Map<String, dynamic>;
      final item = (payload["item"] ?? {}) as Map;
      final deviceToken = item["deviceToken"]?.toString() ?? "";
      if (deviceToken.isNotEmpty) {
        PushNotificationService.sendNotificationToSelectedDriver(
          deviceToken,
          currentTripId!,
          pickUp,
          dropOff,
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
      } catch (_) {
        timer?.cancel();
      }
    }).catchError((_) {});
  }

  CommonMethods commonMethods = CommonMethods();

  @override
  void dispose() {
    _cancelDemoDriverTimers();
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

  double _fareForTier(String tier) {
    final multipliers = {"Economy": 1.0, "Comfort": 1.18, "XL": 1.35};
    final base = actualFareAmountCar * (multipliers[tier] ?? 1.0);
    final discounted = base - promoDiscountAmount;
    return discounted > 0 ? discounted : 0;
  }

  Future<void> applyPromoCode(String promoCode, {bool silent = false}) async {
    final code = promoCode.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      appliedPromo = null;
      promoDiscountAmount = 0;
    });
    try {
      final response = await ApiClient.get(
        "/promos/by-code/${Uri.encodeComponent(code)}",
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
      final userResponse = await ApiClient.get("/users/$userID");
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
      _queueRecalculateFareAndTime();
      if (!silent && mounted) {
        cMethods.displaySnackBar(
          context.l10n.promoAppliedSaved(discount.toStringAsFixed(2)),
          context,
        );
      }
    } finally {
      // no-op
    }
  }

  Future<bool> _hasEnoughWalletBalance(double amount) async {
    final response = await ApiClient.get("/users/$userID");
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
              title: Text(context.l10n.setAsPickup),
              onTap: () => Navigator.pop(context, "pickup"),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(context.l10n.setAsDropoff),
              onTap: () => Navigator.pop(context, "dropoff"),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final address = await _addressFromMapPoint(point);
    if (!mounted) return;
    final appInfo = Provider.of<AppInfoClass>(context, listen: false);
    if (choice == "pickup") {
      appInfo.updatePickUpLocation(address);
      cMethods.displaySnackBar(context.l10n.pickupUpdatedFromMap, context);
    } else {
      appInfo.updateDropOffLocation(address);
      cMethods.displaySnackBar(context.l10n.dropoffUpdatedFromMap, context);
      if (!mounted) return;
      await displayUserRideDetailsContainer();
    }
  }

  Future<AddressModel> _addressFromMapPoint(LatLng point) async {
    final fallback =
        "${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}";
    try {
      final url =
          "https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=jsonv2&accept-language=en";
      final resp = await http.get(
        Uri.parse(url),
        headers: const {"User-Agent": "velo-users-app/1.0"},
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final display = decoded["display_name"]?.toString().trim();
        final name = (display != null && display.isNotEmpty) ? display : fallback;
        return AddressModel(
          placeName: name,
          humanReadableAddress: name,
          latitudePosition: point.latitude,
          longitudePosition: point.longitude,
          placeID: "${point.latitude},${point.longitude}",
        );
      }
    } catch (_) {}
    return AddressModel(
      placeName: fallback,
      humanReadableAddress: fallback,
      latitudePosition: point.latitude,
      longitudePosition: point.longitude,
      placeID: "${point.latitude},${point.longitude}",
    );
  }

  void _startPickFromMap(String target) {
    if (!mounted) return;
    setState(() {
      _mapPickTarget = target;
      // bring user back to the map
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      bottomMapPadding = 160;
      searchContainerHeight = 160;
      isDrawerOpened = true;
    });
    cMethods.displaySnackBar(
      target == "pickup"
          ? context.l10n.selectPickupOnMap
          : context.l10n.selectDropoffOnMap,
      context,
    );
  }

  Future<void> _handleMapTap(LatLng point) async {
    // 1) If user requested to pick a point from the trip screen
    final target = _mapPickTarget;
    if (target != null) {
      final address = await _addressFromMapPoint(point);
      if (!mounted) return;
      if (target == "pickup") {
        Provider.of<AppInfoClass>(context, listen: false)
            .updatePickUpLocation(address);
        cMethods.displaySnackBar(context.l10n.pickupUpdatedFromMap, context);
      } else {
        Provider.of<AppInfoClass>(context, listen: false)
            .updateDropOffLocation(address);
        cMethods.displaySnackBar(context.l10n.dropoffUpdatedFromMap, context);
      }
      setState(() => _mapPickTarget = null);

      // If both points exist, show trip screen again.
      final app = Provider.of<AppInfoClass>(context, listen: false);
      if (app.pickUpLocation != null && app.dropOffLocation != null) {
        await displayUserRideDetailsContainer();
      }
      return;
    }

    // 2) Normal mode: a simple tap selects the destination and opens trip screen.
    if (stateOfApp != "normal") return;
    if (rideDetailsContainerHeight > 0 ||
        requestContainerHeight > 0 ||
        tripContainerHeight > 0) {
      return;
    }
    final address = await _addressFromMapPoint(point);
    if (!mounted) return;
    Provider.of<AppInfoClass>(context, listen: false)
        .updateDropOffLocation(address);
    cMethods.displaySnackBar(context.l10n.dropoffUpdatedFromMap, context);
    await displayUserRideDetailsContainer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawPlaceName = Provider.of<AppInfoClass>(context, listen: false)
        .pickUpLocation
        ?.placeName;
    final String userAddress;
    if (rawPlaceName != null && rawPlaceName.isNotEmpty) {
      userAddress = rawPlaceName.length > 35
          ? "${rawPlaceName.substring(0, 35)}..."
          : rawPlaceName;
    } else {
      userAddress = context.l10n.fetchingLocation;
    }

    // Never call setState from build. Derived values are recalculated when inputs change.

    final appProvider = Provider.of<AppInfoClass>(context, listen: false);

    return SafeArea(
      child: Scaffold(
        key: sKey,
        drawer: CustomDrawer(userName: userName),
        body: Stack(
          children: [
            ///map area
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              padding: EdgeInsets.only(bottom: bottomMapPadding),
              initialCameraPosition:
                  const CameraPosition(target: initialMapCenter, zoom: 13),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _scheduleOnCameraIdle();
              },
              onCameraIdle: _scheduleOnCameraIdle,
              onTap: _handleMapTap,
              onLongPress: _selectPointFromMap,
              polylines: {
                if (polylineCoOrdinates.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId("main_route"),
                    points: polylineCoOrdinates,
                    width: 5,
                    color: AppTheme.accent,
                  ),
              },
              circles: circleCoordinates.entries
                  .map(
                    (entry) => Circle(
                      circleId: CircleId(entry.key),
                      center: entry.value,
                      radius: 70,
                      fillColor: AppTheme.accent.withOpacity(0.18),
                      strokeWidth: 2,
                      strokeColor: AppTheme.accent.withOpacity(0.9),
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

            ///top glass app bar (menu + brand + avatar)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.82),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              if (isDrawerOpened == true) {
                                sKey.currentState!.openDrawer();
                              } else {
                                resetAppNow();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                isDrawerOpened == true
                                    ? Icons.menu_rounded
                                    : Icons.close_rounded,
                                color: AppTheme.accent,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.appName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.accent,
                                  letterSpacing: -0.4,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/avatarman.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            ///pickup/destination map overlay cards (Stitch style)
            if (rideDetailsContainerHeight > 0 ||
                requestContainerHeight > 0 ||
                tripContainerHeight > 0)
              Positioned(
                top: 86,
                left: 16,
                right: 16,
                child: IgnorePointer(
                  child: Column(
                    children: [
                      _MapChipCard(
                        dotColor: AppTheme.accent,
                        label: context.l10n.pickup,
                        value: (appProvider.pickUpLocation?.placeName
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ==
                                true)
                            ? appProvider.pickUpLocation!.placeName.toString()
                            : context.l10n.locationNotAvailable,
                      ),
                      const SizedBox(height: 8),
                      _MapChipCard(
                        dotColor: const Color(0xFF0F172A),
                        label: context.l10n.dropoff,
                        value: (appProvider.dropOffLocation?.placeName
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ==
                                true)
                            ? appProvider.dropOffLocation!.placeName.toString()
                            : context.l10n.locationNotAvailable,
                      ),
                    ],
                  ),
                ),
              ),

            ///LIVE TRIP HUD + Safety button (Stitch style)
            if (tripContainerHeight > 0)
              Positioned(
                top: 170,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.90),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.onRouteUpper,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppTheme.onSurfaceMuted,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.6,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (appProvider.dropOffLocation?.placeName
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ==
                                            true)
                                        ? appProvider.dropOffLocation!.placeName
                                            .toString()
                                        : context.l10n.tripInProgress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.onSurface,
                                          letterSpacing: -0.2,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  estimatedTimeCar.isEmpty ? "—" : estimatedTimeCar,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.accent,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.l10n.etaLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Semantics(
                      button: true,
                      label: context.l10n.safetyTitle,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _openSafetySheet(),
                          child: Ink(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.90),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.08),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                            // Keep compact mode within 160px (avoid 1-2px overflows).
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 48,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (!_homeSheetExpanded) ...[
                                  InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      setState(() {
                                        _homeSheetExpanded = true;
                                        searchContainerHeight = 360;
                                        bottomMapPadding = 360;
                                      });
                                    },
                                    child: Ink(
                                      height: 64,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.search_rounded,
                                              color: AppTheme.accent),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              context.l10n.whereTo,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_up_rounded,
                                            color: AppTheme.onSurfaceMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _homeSheetExpanded = true;
                                        });
                                      },
                                      child: Text(context.l10n.showOptions),
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          context.l10n.whereTo,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w900),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: context.l10n.collapse,
                                        onPressed: () {
                                          setState(() {
                                            _homeSheetExpanded = false;
                                            searchContainerHeight = 160;
                                            bottomMapPadding = 160;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () async {
                                      final responseFromSearchPage =
                                          await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (c) =>
                                              const SearchDestinationPlace
                                                  .forDropOff(),
                                        ),
                                      );
                                      if (responseFromSearchPage ==
                                          "placeSelected") {
                                        displayUserRideDetailsContainer();
                                      }
                                    },
                                    child: Ink(
                                      height: 56,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLow,
                                        borderRadius:
                                            BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.search_rounded,
                                              color: AppTheme.accent),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              context.l10n.searchDestinationHint,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: AppTheme
                                                        .onSurfaceMuted,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          const Icon(Icons.mic_none_rounded,
                                              color:
                                                  AppTheme.onSurfaceMuted),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                InkWell(
                                  borderRadius: BorderRadius.circular(16),
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
                                  child: Ink(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.my_location_rounded),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.l10n.pickup,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 0.8,
                                                      color:
                                                          AppTheme.onSurfaceMuted,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                userAddress,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppTheme.onSurface,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.45,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      _LandmarkCard(
                                        icon: Icons.domain_rounded,
                                        title: context.l10n.recAbdaliTitle,
                                        subtitle: context.l10n.recAbdaliSubtitle,
                                        priceHint: "8.2 JOD",
                                        onTap: () async {
                                          final r = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (c) =>
                                                  const SearchDestinationPlace
                                                      .forDropOff(),
                                            ),
                                          );
                                          if (r == "placeSelected") {
                                            displayUserRideDetailsContainer();
                                          }
                                        },
                                      ),
                                      _LandmarkCard(
                                        icon: Icons.shopping_bag_rounded,
                                        title: context.l10n.recCityMallTitle,
                                        subtitle: context.l10n.recCityMallSubtitle,
                                        priceHint: "4.5 JOD",
                                        onTap: () async {
                                          final r = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (c) =>
                                                  const SearchDestinationPlace
                                                      .forDropOff(),
                                            ),
                                          );
                                          if (r == "placeSelected") {
                                            displayUserRideDetailsContainer();
                                          }
                                        },
                                      ),
                                      _LandmarkCard(
                                        icon: Icons.flight_takeoff_rounded,
                                        title: context.l10n.airport,
                                        subtitle: context.l10n.queenAliaAirport,
                                        priceHint: "22 JOD",
                                        onTap: () async {
                                          final r = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (c) =>
                                                  const SearchDestinationPlace
                                                      .forDropOff(),
                                            ),
                                          );
                                          if (r == "placeSelected") {
                                            displayUserRideDetailsContainer();
                                          }
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.savings_outlined,
                                                size: 18,
                                                color: AppTheme.accent),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                context.l10n.alwaysCheaperTagline,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppTheme.onSurface,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ],
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
                      dark: isDark,
                      showHandle: true,
                      child: SizedBox(
                        height: rideDetailsContainerHeight,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: RideTierSheet(
                            pickupText: (appProvider.pickUpLocation?.placeName
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true)
                                ? appProvider.pickUpLocation!.placeName.toString()
                                : context.l10n.locationNotAvailable,
                            destinationText: (appProvider.dropOffLocation?.placeName
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true)
                                ? appProvider.dropOffLocation!.placeName.toString()
                                : context.l10n.locationNotAvailable,
                            selectedTier: selectedVehicle,
                            onSelectTier: (tier) {
                              setState(() => selectedVehicle = tier);
                              _queueRecalculateFareAndTime();
                            },
                            etaText: estimatedTimeCar.isEmpty
                                ? "—"
                                : "$estimatedTimeCar away",
                            fareByTier: {
                              "Economy":
                                  "JOD ${_fareForTier("Economy").toStringAsFixed(2)}",
                              "Comfort":
                                  "JOD ${_fareForTier("Comfort").toStringAsFixed(2)}",
                              "XL": "JOD ${_fareForTier("XL").toStringAsFixed(2)}",
                            },
                            paymentLabel: selectedPaymentMethod == "Wallet"
                                ? context.l10n.wallet
                                : context.l10n.cash,
                            onSelectPickupFromMap: () => _startPickFromMap("pickup"),
                            onSelectDropoffFromMap: () => _startPickFromMap("dropoff"),
                            onTogglePayment: () {
                              setState(() {
                                selectedPaymentMethod =
                                    selectedPaymentMethod == "Cash" ? "Wallet" : "Cash";
                              });
                            },
                            onConfirm: () async {
                              unawaited(AnalyticsService.logConfirmBooking(
                                  vehicleTier: selectedVehicle));
                              if (selectedPaymentMethod == "Wallet") {
                                final enough =
                                    await _hasEnoughWalletBalance(_effectiveFare());
                                if (!context.mounted) return;
                                if (!enough) {
                                  commonMethods.displaySnackBar(
                                    context
                                        .l10n
                                        .insufficientWalletBalanceForTrip,
                                    context,
                                  );
                                  return;
                                }
                              }
                              if (!mounted) return;

                              setState(() {
                                stateOfApp = "requesting";
                              });

                              // Shows the requesting UI and creates the trip record.
                              displayRequestContainer();
                              unawaited(AnalyticsService.logRequestDriver());

                              // Debug/demo flow: auto-accept to let you explore trip states.
                              if (kDebugMode && _enableDemoDriver) {
                                await _startDemoDriverFlow();
                                return;
                              }

                              // Snapshot the currently known nearby drivers and start dispatch.
                              availableNearbyOnlineDriversList =
                                  List<OnlineNearbyDrivers>.from(
                                ManageDriversMethods.nearbyOnlineDriversList,
                              );
                              searchDriver();
                            },
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
                      dark: isDark,
                      showHandle: true,
                      child: SizedBox(
                        height: requestContainerHeight,
                        child: RequestingDriverSheet(
                          etaMinutesText: estimatedTimeCar
                                  .replaceAll(RegExp(r'[^0-9]'), '')
                                  .trim()
                                  .isEmpty
                              ? "—"
                              : estimatedTimeCar
                                  .replaceAll(RegExp(r'[^0-9]'), '')
                                  .trim(),
                          vehicleName: "Velo $selectedVehicle",
                          vehicleSubtitle: "Premium • AC",
                          fareText: "JOD ${_effectiveFare().toStringAsFixed(2)}",
                          onCancel: () {
                            resetAppNow();
                            cancelRideRequest();
                          },
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
                      dark: isDark,
                      showHandle: true,
                      child: SizedBox(
                        height: tripContainerHeight,
                        child: ActiveTripSheet(
                          tripStatusDisplay: tripStatusDisplay,
                          driverName: nameDriver,
                          driverPhotoUrl: photoDriver,
                          carDetails: carDetailsDriver,
                          driverPhone: phoneNumberDriver,
                          vehiclePlate: plateDriver,
                          onShareTrip: () async {
                            unawaited(AnalyticsService.logTripShared());
                            final msg = context.l10n.shareTripMessage(
                              currentTripId ?? "",
                              nameDriver.isEmpty
                                  ? context.l10n.yourDriver
                                  : nameDriver,
                              carDetailsDriver.isEmpty
                                  ? "—"
                                  : carDetailsDriver,
                              plateDriver.isEmpty ? "—" : plateDriver,
                            );
                            await Share.share(
                              msg,
                              subject: context.l10n.shareTripSubject,
                            );
                          },
                          onEmergency: () {
                            unawaited(AnalyticsService.logEmergencyTapped());
                            _openSafetySheet();
                          },
                          onCancelTrip: () {
                            resetAppNow();
                            cancelRideRequest();
                          },
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

class _LandmarkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String priceHint;
  final VoidCallback onTap;

  const _LandmarkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.priceHint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.accent, size: 20),
                ),
                const Spacer(),
                Text(
                  priceHint,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.onSurfaceMuted,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapChipCard extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;

  const _MapChipCard({
    required this.dotColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withOpacity(0.25),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
