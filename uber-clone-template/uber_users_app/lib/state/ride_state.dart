import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/models/direction_details.dart';

/// Phases of a ride request lifecycle, replacing the loose `stateOfApp` string
/// and the combination of sheet-height booleans in HomePage.
enum RidePhase {
  idle,
  selectingTier,
  requesting,
  active,
  payment,
}

/// Centralizes the mutable trip/driver/fare fields that were previously
/// scattered across `global/trip_var.dart` globals and `_HomePageState` local
/// variables. Widgets use `Consumer<RideState>` or `context.read<RideState>()`
/// to access and mutate them.
class RideState extends ChangeNotifier {
  // ── Phase ───────────────────────────────────────────────

  RidePhase _phase = RidePhase.idle;

  RidePhase get phase => _phase;

  void setPhase(RidePhase p) {
    if (_phase == p) return;
    _phase = p;
    notifyListeners();
  }

  // ── Driver info (was globals in trip_var.dart) ──────────

  String _driverName = '';
  String _driverPhoto = '';
  String _driverPhone = '';
  String _carDetails = '';
  String _vehiclePlate = '';
  String _tripStatus = '';
  String _tripStatusDisplay = 'Driver is Arriving';
  int _requestTimeoutSeconds = 40;

  String get driverName => _driverName;
  String get driverPhoto => _driverPhoto;
  String get driverPhone => _driverPhone;
  String get carDetails => _carDetails;
  String get vehiclePlate => _vehiclePlate;
  String get tripStatus => _tripStatus;
  String get tripStatusDisplay => _tripStatusDisplay;
  int get requestTimeoutSeconds => _requestTimeoutSeconds;

  void updateDriver({
    String? name,
    String? photo,
    String? phone,
    String? carDetails,
    String? plate,
  }) {
    _driverName = name ?? _driverName;
    _driverPhoto = photo ?? _driverPhoto;
    _driverPhone = phone ?? _driverPhone;
    _carDetails = carDetails ?? _carDetails;
    _vehiclePlate = plate ?? _vehiclePlate;
    notifyListeners();
  }

  void setTripStatus(String status, {String? display}) {
    _tripStatus = status;
    if (display != null) _tripStatusDisplay = display;
    notifyListeners();
  }

  void setTripStatusDisplay(String text) {
    if (_tripStatusDisplay == text) return;
    _tripStatusDisplay = text;
    notifyListeners();
  }

  void tickTimeout() {
    if (_requestTimeoutSeconds > 0) _requestTimeoutSeconds--;
  }

  void resetTimeout([int seconds = 40]) {
    _requestTimeoutSeconds = seconds;
  }

  // ── Trip identity ───────────────────────────────────────

  String? _currentTripId;
  String? get currentTripId => _currentTripId;

  void setTripId(String? id) {
    _currentTripId = id;
  }

  // ── Vehicle & payment selection ─────────────────────────

  String _selectedVehicle = 'Economy';
  String _selectedPaymentMethod = 'Cash';

  String get selectedVehicle => _selectedVehicle;
  String get selectedPaymentMethod => _selectedPaymentMethod;

  void selectVehicle(String tier) {
    if (_selectedVehicle == tier) return;
    _selectedVehicle = tier;
    notifyListeners();
  }

  void togglePaymentMethod() {
    _selectedPaymentMethod =
        _selectedPaymentMethod == 'Cash' ? 'Wallet' : 'Cash';
    notifyListeners();
  }

  // ── Direction / fare ────────────────────────────────────

  DirectionDetails? _directionDetails;
  double _baseFare = 0.0;
  String _estimatedTime = '';
  final CommonMethods _cMethods = CommonMethods();

  DirectionDetails? get directionDetails => _directionDetails;
  double get baseFare => _baseFare;
  String get estimatedTime => _estimatedTime;

  void setDirectionDetails(DirectionDetails? details) {
    _directionDetails = details;
    _recalculateFare();
    notifyListeners();
  }

  static const _tierMultipliers = {
    'Economy': 1.0,
    'Comfort': 1.18,
    'XL': 1.35,
  };

  void _recalculateFare() {
    if (_directionDetails == null) {
      _baseFare = 0.0;
      _estimatedTime = '';
      return;
    }
    final fareString = _cMethods.calculateFareAmountInJOD(_directionDetails!);
    _baseFare = double.tryParse(fareString) ?? 0.0;
    _estimatedTime = _directionDetails!.durationTextString ?? '';
  }

  double effectiveFare() {
    final base = _baseFare * (_tierMultipliers[_selectedVehicle] ?? 1.0);
    final discounted = base - _promoDiscountAmount;
    return discounted > 0 ? discounted : 0;
  }

  double fareForTier(String tier) {
    final base = _baseFare * (_tierMultipliers[tier] ?? 1.0);
    final discounted = base - _promoDiscountAmount;
    return discounted > 0 ? discounted : 0;
  }

  // ── Promo ───────────────────────────────────────────────

  Map<String, dynamic>? _appliedPromo;
  double _promoDiscountAmount = 0.0;

  Map<String, dynamic>? get appliedPromo => _appliedPromo;
  double get promoDiscountAmount => _promoDiscountAmount;

  /// Validates and applies a promo code.
  ///
  /// [userId] is the current user for eligibility checks.
  /// [onMessage] optional callback for UI feedback (receives discount amount).
  Future<void> applyPromoCode(
    String promoCode, {
    required String userId,
    bool silent = false,
    void Function(String discountFormatted)? onMessage,
  }) async {
    final code = promoCode.trim().toUpperCase();
    if (code.isEmpty) return;
    _appliedPromo = null;
    _promoDiscountAmount = 0;
    notifyListeners();
    try {
      final response = await ApiClient.get(
        '/promos/by-code/${Uri.encodeComponent(code)}',
      );
      if (response.statusCode != 200) return;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if ((payload['exists'] ?? false) != true || payload['item'] == null) {
        return;
      }

      final promo = Map<String, dynamic>.from(payload['item'] as Map);
      final targetType = (promo['targetType'] ?? 'all').toString();
      final eligibleUserIds = ((promo['eligibleUserIds'] ?? []) as List)
          .map((e) => e.toString())
          .toList();
      if (targetType == 'specific' && !eligibleUserIds.contains(userId)) {
        return;
      }

      final userResponse = await ApiClient.get('/users/$userId');
      if (userResponse.statusCode == 200) {
        final userPayload =
            jsonDecode(userResponse.body) as Map<String, dynamic>;
        final userItem = (userPayload['item'] ?? {}) as Map;
        final usedCodes = ((userItem['usedPromoCodes'] ?? []) as List)
            .map((e) => e.toString().toUpperCase())
            .toList();
        if (usedCodes.contains(code)) return;
      }

      final isActive = promo['isActive'] == true;
      final validTill =
          DateTime.tryParse(promo['validTill']?.toString() ?? '');
      if (!isActive ||
          (validTill != null && DateTime.now().isAfter(validTill))) {
        return;
      }

      final usageLimit =
          int.tryParse((promo['usageLimit'] ?? '0').toString()) ?? 0;
      final usedCount =
          int.tryParse((promo['usedCount'] ?? '0').toString()) ?? 0;
      if (usageLimit > 0 && usedCount >= usageLimit) return;

      final base = effectiveFare();
      double discount = 0.0;
      final discountType = (promo['discountType'] ?? 'percent').toString();
      final discountValue =
          double.tryParse((promo['discountValue'] ?? '0').toString()) ?? 0.0;
      if (discountType == 'fixed') {
        discount = discountValue;
      } else {
        discount = (base * discountValue) / 100;
        final maxCap = double.tryParse(
                (promo['maxDiscountAmount'] ?? '0').toString()) ??
            0.0;
        if (maxCap > 0 && discount > maxCap) discount = maxCap;
      }
      if (discount > base) discount = base;

      _appliedPromo = promo;
      _promoDiscountAmount = discount;
      notifyListeners();

      if (!silent && onMessage != null) {
        onMessage(discount.toStringAsFixed(2));
      }
    } catch (_) {
      // Promo failures are non-fatal.
    }
  }

  Future<bool> hasEnoughWalletBalance(double amount, String userId) async {
    final response = await ApiClient.get('/users/$userId');
    if (response.statusCode != 200) return false;
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final item = (payload['item'] ?? {}) as Map;
    final wallet =
        double.tryParse(item['walletBalance']?.toString() ?? '0') ?? 0;
    return wallet >= amount;
  }

  // ── Preferences ─────────────────────────────────────────

  Future<void> loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMethod = prefs.getString('default_payment_method');
    _selectedPaymentMethod = savedMethod == 'Wallet' ? 'Wallet' : 'Cash';
    notifyListeners();
  }

  // ── Reset ───────────────────────────────────────────────

  void reset() {
    _phase = RidePhase.idle;
    _currentTripId = null;
    _driverName = '';
    _driverPhoto = '';
    _driverPhone = '';
    _carDetails = '';
    _vehiclePlate = '';
    _tripStatus = '';
    _tripStatusDisplay = 'Driver is Arriving';
    _requestTimeoutSeconds = 40;
    notifyListeners();
  }
}
