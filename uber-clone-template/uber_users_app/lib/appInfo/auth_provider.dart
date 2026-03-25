import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/authentication/register_screen.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/global/global_var.dart';
import '../models/user_model.dart';

class AuthenticationProvider extends ChangeNotifier {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  static const String _sessionUidKey = "user_uid";
  static const String _sessionPhoneKey = "user_phone";
  static const String _sessionEmailKey = "user_email";
  CommonMethods commonMethods = CommonMethods();
  bool _isLoading = false;
  bool _isSuccessful = false;
  bool _isGoogleSignedIn = false;
  bool _isGoogleSignInLoading = false;
  String? _uid;
  String? _phoneNumber;

  UserModel? _userModel;

  UserModel get userModel => _userModel!;

  String? get uid => _uid;
  String get phoneNumber => _phoneNumber!;
  bool get isSuccessful => _isSuccessful;
  bool get isLoading => _isLoading;
  bool get isGoogleSignedIn => _isGoogleSignedIn;
  bool get isGoogleSigInLoading => _isGoogleSignInLoading;

  String? _googleEmail;
  String? _pendingPlainPassword;
  String? get signedInEmail => _googleEmail;

  Future<bool> loginWithPhone({
    required BuildContext context,
    required String phoneNumber,
    required String password,
  }) async {
    startLoading();
    try {
      final normalizedPhone = _normalizeJordanPhone(phoneNumber);
      final response = await http.post(
        Uri.parse("$_awsApiBaseUrl/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": normalizedPhone, "password": password}),
      );
      if (response.statusCode != 200) {
        commonMethods.displaySnackBar(
          "Invalid phone or password.",
          context,
        );
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final item = (data["item"] ?? {}) as Map;
      final existingId = item["id"]?.toString() ?? "";
      if (existingId.isEmpty) {
        commonMethods.displaySnackBar(
          "Invalid phone or password.",
          context,
        );
        return false;
      }

      _uid = existingId;
      _phoneNumber = normalizedPhone;
      _googleEmail = item["email"]?.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUidKey, _uid!);
      await prefs.setString(_sessionPhoneKey, _phoneNumber ?? "");
      if (_googleEmail != null && _googleEmail!.isNotEmpty) {
        await prefs.setString(_sessionEmailKey, _googleEmail!);
      }
      userID = _uid ?? "";
      _isSuccessful = true;
      notifyListeners();
      return true;
    } catch (e) {
      commonMethods.displaySnackBar("Login failed: $e", context);
      return false;
    } finally {
      stopLoading();
    }
  }

  Future<bool> resetPasswordByPhone({
    required BuildContext context,
    required String phoneNumber,
    required String newPassword,
  }) async {
    startLoading();
    try {
      final normalizedPhone = _normalizeJordanPhone(phoneNumber);
      final response = await http.post(
        Uri.parse("$_awsApiBaseUrl/users/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
          {"phone": normalizedPhone, "newPassword": newPassword.trim()},
        ),
      );
      if (response.statusCode == 200) {
        commonMethods.displaySnackBar(
          "Password reset successful. You can now log in.",
          context,
        );
        return true;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final error = payload["error"]?.toString() ?? "Password reset failed.";
      commonMethods.displaySnackBar(error, context);
      return false;
    } catch (e) {
      commonMethods.displaySnackBar("Password reset failed: $e", context);
      return false;
    } finally {
      stopLoading();
    }
  }

  String _normalizeJordanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('962') && digits.length >= 12) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length == 10) {
      return '+962${digits.substring(1)}';
    }
    if (digits.length == 9) {
      return '+962$digits';
    }
    if (phone.trim().startsWith('+')) {
      return phone.trim();
    }
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
          "$_awsApiBaseUrl/users/by-phone/${Uri.encodeComponent(normalizedPhone)}",
        ),
      );
      if (existing.statusCode == 200) {
        final data = jsonDecode(existing.body) as Map<String, dynamic>;
        final item = (data["item"] ?? {}) as Map;
        if ((data["exists"] ?? false) == true && item["id"] != null) {
          _uid = item["id"].toString();
          _googleEmail = item["email"]?.toString();
        }
      }
      _uid ??= DateTime.now().millisecondsSinceEpoch.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUidKey, _uid!);
      await prefs.setString(_sessionPhoneKey, _phoneNumber ?? "");
      if (_googleEmail != null && _googleEmail!.isNotEmpty) {
        await prefs.setString(_sessionEmailKey, _googleEmail!);
      }
      _isSuccessful = true;
      userID = _uid ?? "";
      notifyListeners();
    } catch (e) {
      commonMethods.displaySnackBar("Failed to continue: $e", context);
    } finally {
      stopLoading();
    }
  }

  Future<bool> isPhoneUniqueAcrossUsersAndDrivers(String phoneNumber) async {
    final normalized = _normalizeJordanPhone(phoneNumber);
    final u = await checkUserExistByPhone(normalized);
    if (u) return false;
    final r = await http.get(
      Uri.parse(
        "$_awsApiBaseUrl/drivers/by-phone/${Uri.encodeComponent(normalized)}",
      ),
    );
    if (r.statusCode != 200) return true;
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data["exists"] ?? false) != true;
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
    required UserModel userModel,
    required String password,
    required VoidCallback onSuccess,
  }) async {
    startLoading();
    notifyListeners();

    try {
      final phone = userModel.phone.trim();
      if (phone.isEmpty) {
        throw Exception("Phone number is required.");
      }
      final normalizedPhone = _normalizeJordanPhone(phone);
      final existingByPhone = await http.get(
        Uri.parse(
          "$_awsApiBaseUrl/users/by-phone/${Uri.encodeComponent(normalizedPhone)}",
        ),
      );
      bool shouldCreate = true;
      if (existingByPhone.statusCode == 200) {
        final payload = jsonDecode(existingByPhone.body) as Map<String, dynamic>;
        final bool exists = (payload["exists"] ?? false) == true;
        final Map existingItem = (payload["item"] ?? {}) as Map;
        final String existingId = existingItem["id"]?.toString() ?? "";
        if (exists && existingId.isNotEmpty && existingId != userModel.id) {
          throw Exception("This phone number is already in use.");
        }
        if (exists && existingId == userModel.id) {
          shouldCreate = false;
        }
      }

      final response = shouldCreate
          ? await http.post(
              Uri.parse("$_awsApiBaseUrl/users"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer public-migration-token"
              },
              body: jsonEncode({...userModel.toMap(), "password": password}),
            )
          : await http.put(
              Uri.parse("$_awsApiBaseUrl/users/${userModel.id}"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer public-migration-token"
              },
              body: jsonEncode({...userModel.toMap(), "password": password}),
            );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("AWS save failed with status ${response.statusCode}");
      }
      stopLoading();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUidKey, userModel.id);
      await prefs.setString(_sessionPhoneKey, normalizedPhone);
      await prefs.setString(_sessionEmailKey, userModel.email);
      _uid = userModel.id;
      userID = _uid ?? "";
      _googleEmail = userModel.email;
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
      Uri.parse("$_awsApiBaseUrl/users/by-email/${Uri.encodeComponent(email)}"),
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["exists"] ?? false) == true;
  }

  // Method to check if user exists in Firebase Realtime Database by phone number
  Future<bool> checkUserExistByPhone(String phoneNumber) async {
    final normalizedPhone = _normalizeJordanPhone(phoneNumber);
    final response = await http.get(
      Uri.parse(
        "$_awsApiBaseUrl/users/by-phone/${Uri.encodeComponent(normalizedPhone)}",
      ),
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["exists"] ?? false) == true;
  }

  Future<bool> checkUserExistById() async {
    final currentUid = _uid;
    if (currentUid == null) return false;
    final response = await http.get(Uri.parse("$_awsApiBaseUrl/users/$currentUid"));
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["exists"] ?? false) == true;
  }

  // Method to get user data from Firebase Realtime Database
  Future<void> getUserDataFromFirebaseDatabase() async {
    try {
      final resolvedUid = _uid;
      if (resolvedUid == null) return;
      final response = await http.get(Uri.parse("$_awsApiBaseUrl/users/$resolvedUid"));
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = (payload["item"] ?? <String, dynamic>{}) as Map;
        if ((payload["exists"] ?? false) != true || userData.isEmpty) {
          return;
        }

        // Create a UserModel object from the retrieved data
        _userModel = UserModel(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          phone: userData['phone'],
          blockStatus: userData['blockStatus'],
        );

        _uid = _userModel!.id;
        userID = _uid ?? "";
        notifyListeners(); // Notify listeners to update the UI
      }
    } catch (e) {
      print("An error occurred while fetching user data: $e");
    }
  }

  Future<bool> checkIfUserIsBlocked() async {
    try {
      final currentUid = _uid;
      if (currentUid == null) return false;
      final response = await http.get(Uri.parse("$_awsApiBaseUrl/users/$currentUid"));
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
          userID = "";
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

  Future<bool> checkUserFieldsFilled() async {
    try {
      final currentUid = _uid;
      if (currentUid == null) return false;
      final response = await http.get(Uri.parse("$_awsApiBaseUrl/users/$currentUid"));
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = (payload["item"] ?? <String, dynamic>{}) as Map;
        if ((payload["exists"] ?? false) != true || userData.isEmpty) {
          return false;
        }

        // Retrieve individual fields and perform null checks
        String id = userData["id"] ?? '';
        String name = userData["name"] ?? '';
        String email = userData["email"] ?? '';
        String phone = userData["phone"] ?? '';

        // Check if any of the required fields are missing or empty
        if (id.isEmpty || name.isEmpty || email.isEmpty || phone.isEmpty) {
          return false; // Some fields are missing or empty
        } else {
          return true; // All fields are filled
        }
      }
      return false;
    } catch (e) {
      print("An error occurred while checking user fields: $e");
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

  // Sign out method
  Future<void> signOut(BuildContext context) async {
    startLoading();
    try {
      _uid = null;
      userID = "";
      _isGoogleSignedIn = false;
      _googleEmail = null;
      _pendingPlainPassword = null;
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
    userID = _uid ?? "";
    _phoneNumber = prefs.getString(_sessionPhoneKey);
    _googleEmail = prefs.getString(_sessionEmailKey);
    notifyListeners();
  }

  void setPendingPassword(String password) {
    _pendingPlainPassword = password.trim();
  }

  String? consumePendingPassword() {
    final value = _pendingPlainPassword;
    _pendingPlainPassword = null;
    return value;
  }
}
