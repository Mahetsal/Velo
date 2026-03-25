import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_drivers_app/models/driver.dart';
import 'package:uber_drivers_app/pages/auth/register_screen.dart';
import 'package:uber_drivers_app/global/global.dart';
import '../methods/common_method.dart';
import '../models/vehicleInfo.dart';

class AuthenticationProvider extends ChangeNotifier {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  static const String _sessionUidKey = "driver_uid";
  static const String _sessionPhoneKey = "driver_phone";
  static const String _sessionEmailKey = "driver_email";
  CommonMethods commonMethods = CommonMethods();
  bool _isLoading = false;
  bool _isSuccessful = false;
  bool _isGoogleSignedIn = false;
  bool _isGoogleSignInLoading = false;
  String? _uid;
  String? _phoneNumber;

  Driver? _driverModel;

  Driver get driverModel => _driverModel!;

  String? get uid => _uid;
  String get phoneNumber => _phoneNumber!;
  bool get isSuccessful => _isSuccessful;
  bool get isLoading => _isLoading;
  bool get isGoogleSignedIn => _isGoogleSignedIn;
  bool get isGoogleSigInLoading => _isGoogleSignInLoading;

  String? _signedInEmail;
  String? get signedInEmail => _signedInEmail;

  String _normalizeJordanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('962') && digits.length >= 12) return '+$digits';
    if (digits.startsWith('0') && digits.length == 10) {
      return '+962${digits.substring(1)}';
    }
    if (digits.length == 9) return '+962$digits';
    if (phone.trim().startsWith('+')) return phone.trim();
    return '+$digits';
  }

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void startGoogleLoading() {
    _isGoogleSignInLoading = true;
    notifyListeners();
  }

  void stopGoogleLoading() {
    _isGoogleSignInLoading = false;
    notifyListeners();
  }

  // Sign in user with phone
  void signInWithPhone({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    continueWithoutSms(context: context, phoneNumber: phoneNumber);
  }

  Future<void> continueWithoutSms({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    startLoading();
    try {
      final normalizedPhone = _normalizeJordanPhone(phoneNumber);
      _phoneNumber = normalizedPhone;
      final existing = await http.get(
        Uri.parse(
          "$_awsApiBaseUrl/drivers/by-phone/${Uri.encodeComponent(normalizedPhone)}",
        ),
      );
      if (existing.statusCode == 200) {
        final data = jsonDecode(existing.body) as Map<String, dynamic>;
        final item = (data["item"] ?? {}) as Map;
        if ((data["exists"] ?? false) == true && item["id"] != null) {
          _uid = item["id"].toString();
          _signedInEmail = item["email"]?.toString();
        }
      }
      _uid ??= DateTime.now().millisecondsSinceEpoch.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUidKey, _uid!);
      await prefs.setString(_sessionPhoneKey, _phoneNumber ?? "");
      if (_signedInEmail != null && _signedInEmail!.isNotEmpty) {
        await prefs.setString(_sessionEmailKey, _signedInEmail!);
      }
      _isSuccessful = true;
      driverUid = _uid ?? "";
      notifyListeners();
    } catch (e) {
      commonMethods.displaySnackBar("Failed to continue: $e", context);
    } finally {
      stopLoading();
    }
  }

  void verifyOTP({
    required BuildContext context,
    required String verificationId,
    required String smsCode,
    required Function onSuccess,
  }) async {
    _isLoading = false;
    _isSuccessful = true;
    notifyListeners();
    onSuccess();
  }

// Method to register a new user
  void saveUserDataToFirebase({
    required BuildContext context,
    required Driver driverModel,
    required VoidCallback onSuccess,
  }) async {
    startLoading();
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("$_awsApiBaseUrl/drivers"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer public-migration-token"},
        body: jsonEncode(driverModel.toMap()),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("AWS save failed with status ${response.statusCode}");
      }
      stopLoading();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUidKey, driverModel.id);
      await prefs.setString(_sessionPhoneKey, driverModel.phoneNumber);
      await prefs.setString(_sessionEmailKey, driverModel.email);
      _uid = driverModel.id;
      driverUid = _uid ?? "";
      _signedInEmail = driverModel.email;
      onSuccess();
    } catch (e) {
      stopLoading();
      notifyListeners();
      commonMethods.displaySnackBar(e.toString(), context);
    }
  }

  // Method to check if user exists in Firebase Realtime Database
  Future<bool> checkUserExistByEmail(String email) async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/drivers/by-email/${Uri.encodeComponent(email)}"),
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["exists"] ?? false) == true;
  }

  Future<bool> checkUserExistByPhone(String phoneNumber) async {
    final normalizedPhone = _normalizeJordanPhone(phoneNumber);
    final response = await http.get(
      Uri.parse(
        "$_awsApiBaseUrl/drivers/by-phone/${Uri.encodeComponent(normalizedPhone)}",
      ),
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final exists = (data["exists"] ?? false) == true;
    if (!exists) return false;
    final item = (data["item"] ?? {}) as Map;
    if (item["id"] != null) {
      _uid = item["id"].toString();
      driverUid = _uid ?? "";
    }
    _phoneNumber = normalizedPhone;
    _signedInEmail = item["email"]?.toString();
    notifyListeners();
    return true;
  }

  Future<bool> checkUserExistById() async {
    final currentUid = _uid;
    if (currentUid == null) return false;
    final response =
        await http.get(Uri.parse("$_awsApiBaseUrl/drivers/$currentUid"));
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["exists"] ?? false) == true;
  }

  Future<void> getUserDataFromFirebaseDatabase() async {
    try {
      final currentUid = _uid;
      if (currentUid == null) return;
      final response =
          await http.get(Uri.parse("$_awsApiBaseUrl/drivers/$currentUid"));
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final driverData = (payload["item"] ?? <String, dynamic>{}) as Map;
        if ((payload["exists"] ?? false) != true || driverData.isEmpty) {
          return;
        }

        // Retrieve individual values from the map and create the Driver object
        _driverModel = Driver(
          id: driverData["id"] ?? '',
          firstName: driverData["firstName"] ?? '',
          secondName: driverData["secondName"] ?? '',
          phoneNumber: driverData["phoneNumber"] ?? '',
          address: driverData["address"] ?? '',
          profilePicture: driverData["profilePicture"] ?? '',
          dob: driverData["dob"] ?? '',
          email: driverData["email"] ?? '',
          cnicNumber: driverData["cnicNumber"] ?? '',
          cnicFrontImage: driverData["cnicFrontImage"] ?? '',
          cnicBackImage: driverData["cnicBackImage"] ?? '',
          driverFaceWithCnic: driverData["driverFaceWithCnic"] ?? '',
          drivingLicenseNumber: driverData["drivingLicenseNumber"] ?? '',
          drivingLicenseFrontImage:
              driverData["drivingLicenseFrontImage"] ?? '',
          drivingLicenseBackImage: driverData["drivingLicenseBackImage"] ?? '',
          blockStatus: driverData["blockStatus"] ?? '',
          deviceToken: driverData["deviceToken"] ?? '',
          driverRattings: driverData["driverRattings"] ?? '',
          earnings: driverData["earnings"] ?? '',
          vehicleInfo: VehicleInfo(
            brand: driverData["vehicleInfo"]?["brand"] ?? '',
            color: driverData["vehicleInfo"]?["color"] ?? '',
            productionYear: driverData["vehicleInfo"]?["productionYear"] ?? '',
            vehiclePicture: driverData["vehicleInfo"]?["vehiclePicture"] ?? '',
            type: driverData["vehicleInfo"]?["type"] ?? '',
            registrationPlateNumber:
                driverData["vehicleInfo"]?["registrationPlateNumber"] ?? '',
            registrationCertificateFrontImage: driverData["vehicleInfo"]
                    ?["registrationCertificateFrontImage"] ??
                '',
            registrationCertificateBackImage: driverData["vehicleInfo"]
                    ?["registrationCertificateBackImage"] ??
                '',
          ),
        );

        // Print or use the driver model as needed
        print(_driverModel);
        _uid = _driverModel!.id;
        driverUid = _uid ?? "";
        notifyListeners(); // Notify listeners to update the UI
      }
    } catch (e) {
      print("An error occurred while fetching user data: $e");
    }
  }

  Future<bool> checkDriverFieldsFilled() async {
    try {
      final currentUid = _uid;
      if (currentUid == null) return false;
      final response =
          await http.get(Uri.parse("$_awsApiBaseUrl/drivers/$currentUid"));
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final driverData = (payload["item"] ?? <String, dynamic>{}) as Map;
        if ((payload["exists"] ?? false) != true || driverData.isEmpty) {
          return false;
        }

        // Retrieve individual fields and perform null checks
        String profilePicture = driverData["profilePicture"] ?? '';
        String firstName = driverData["firstName"] ?? '';
        String secondName = driverData["secondName"] ?? '';
        String phoneNumber = driverData["phoneNumber"] ?? '';
        String dob = driverData["dob"] ?? '';
        String email = driverData["email"] ?? '';
        String cnicNumber = driverData["cnicNumber"] ?? '';
        String cnicFrontImage = driverData["cnicFrontImage"] ?? '';
        String cnicBackImage = driverData["cnicBackImage"] ?? '';
        String driverFaceWithCnic = driverData["driverFaceWithCnic"] ?? '';
        String drivingLicenseNumber = driverData["drivingLicenseNumber"] ?? '';
        String drivingLicenseFrontImage =
            driverData["drivingLicenseFrontImage"] ?? '';
        String drivingLicenseBackImage =
            driverData["drivingLicenseBackImage"] ?? '';

        // Extract and check nested vehicle info fields
        Map vehicleInfo = driverData["vehicleInfo"] ?? {};
        String carBrand = vehicleInfo["brand"] ?? '';
        String carColor = vehicleInfo["color"] ?? '';
        String productionYear = vehicleInfo["productionYear"] ?? '';
        String vehiclePicture = vehicleInfo["vehiclePicture"] ?? '';
        String vehicleType = vehicleInfo["type"] ?? '';
        String registrationPlateNumber =
            vehicleInfo["registrationPlateNumber"] ?? '';
        String registrationCertificateFrontImage =
            vehicleInfo["registrationCertificateFrontImage"] ?? '';
        String registrationCertificateBackImage =
            vehicleInfo["registrationCertificateBackImage"] ?? '';

        // Check if any of the required fields are missing or empty
        if (profilePicture.isEmpty ||
            firstName.isEmpty ||
            secondName.isEmpty ||
            phoneNumber.isEmpty ||
            dob.isEmpty ||
            email.isEmpty ||
            cnicNumber.isEmpty ||
            cnicFrontImage.isEmpty ||
            cnicBackImage.isEmpty ||
            driverFaceWithCnic.isEmpty ||
            drivingLicenseNumber.isEmpty ||
            drivingLicenseFrontImage.isEmpty ||
            drivingLicenseBackImage.isEmpty ||
            carBrand.isEmpty ||
            carColor.isEmpty ||
            productionYear.isEmpty ||
            vehiclePicture.isEmpty ||
            vehicleType.isEmpty ||
            registrationPlateNumber.isEmpty ||
            registrationCertificateFrontImage.isEmpty ||
            registrationCertificateBackImage.isEmpty) {
          return false; // Some fields are missing or empty
        } else {
          return true; // All fields are filled
        }
      }
      return false;
    } catch (e) {
      print("An error occurred while checking driver fields: $e");
      return false;
    }
  }

  Future<bool> isDriverApproved() async {
    try {
      final currentUid = _uid;
      if (currentUid == null) return false;
      final response =
          await http.get(Uri.parse("$_awsApiBaseUrl/drivers/$currentUid"));
      if (response.statusCode != 200) return false;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final driverData = (payload["item"] ?? <String, dynamic>{}) as Map;
      if ((payload["exists"] ?? false) != true || driverData.isEmpty) {
        return false;
      }
      return (driverData["approvalStatus"]?.toString() ?? "pending") ==
          "approved";
    } catch (_) {
      return false;
    }
  }

  // Google Sign-In method
  Future<void> signInWithGoogle(
      BuildContext context, VoidCallback onSuccess) async {
    startGoogleLoading();
    commonMethods.displaySnackBar(
      "Google sign-in is disabled after AWS-only migration. Use phone login.",
      context,
    );
    _isGoogleSignedIn = false;
    stopGoogleLoading();
    onSuccess();
  }

  Future<bool> checkIfDriverIsBlocked() async {
    try {
      final currentUid = _uid;
      if (currentUid == null) return false;
      final response =
          await http.get(Uri.parse("$_awsApiBaseUrl/drivers/$currentUid"));
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final driverData = (payload["item"] ?? <String, dynamic>{}) as Map;
        if ((payload["exists"] ?? false) != true || driverData.isEmpty) {
          return false;
        }

        // Check the block status
        String blockStatus = driverData["blockStatus"] ?? 'no';

        // If blockStatus is 'yes', return true (blocked)
        if (blockStatus == 'yes') {
          _uid = null;
          driverUid = "";
          _isGoogleSignedIn = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_sessionUidKey);
          await prefs.remove(_sessionPhoneKey);
          await prefs.remove(_sessionEmailKey);
          notifyListeners();
          return true;
        } else {
          // If blockStatus is 'no', return false (not blocked)
          return false;
        }
      }
      return false;
    } catch (e) {
      print("An error occurred while checking block status: $e");
      return false; // Default to not blocked in case of an error
    }
  }

  // Sign out method
  Future<void> signOut(BuildContext context) async {
    startLoading();
    try {
      _uid = null;
      driverUid = "";
      _isGoogleSignedIn = false;
      _signedInEmail = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUidKey);
      await prefs.remove(_sessionPhoneKey);
      await prefs.remove(_sessionEmailKey);
      notifyListeners();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const RegisterScreen()), // Change to your login page
        (route) => false,
      );

      stopLoading();
    } catch (e) {
      stopLoading();
      commonMethods.displaySnackBar("Failed to sign out", context);
    }
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString(_sessionUidKey);
    driverUid = _uid ?? "";
    _phoneNumber = prefs.getString(_sessionPhoneKey);
    _signedInEmail = prefs.getString(_sessionEmailKey);
    notifyListeners();
  }
}
