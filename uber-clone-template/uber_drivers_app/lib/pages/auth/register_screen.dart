import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_drivers_app/methods/common_method.dart';
import 'package:uber_drivers_app/pages/dashboard.dart';
import 'package:uber_drivers_app/pages/driverRegistration/driver_registration.dart';
import 'package:uber_drivers_app/pages/terms_page.dart';
import 'package:uber_drivers_app/widgets/blocked_screen.dart';

import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Country selectedCountry = Country(
    phoneCode: '962',
    countryCode: 'JO',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Jordan',
    example: 'Jordan',
    displayName: 'Jordan',
    displayNameNoCountryCode: 'JO',
    e164Key: '',
  );

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  CommonMethods commonMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Drive with Velo",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                const Text(
                  "Sign in with your mobile number",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller: phoneController,
                  maxLength: 15,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Keep suffix icon in sync
                    });
                  },
                  validator: (value) {
                    final cleaned = _normalizePhone(value ?? "");
                    if (cleaned.length < 7 || cleaned.length > 15) {
                      return "Enter a valid mobile number";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    hintText: '313 7426256',
                    hintStyle: const TextStyle(
                      color: Color(0xFF98A2B3),
                      fontSize: 16,
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 120, minHeight: 48),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1570EF)),
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 4.0, 12.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            countryListTheme: const CountryListThemeData(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                bottomSheetHeight: 400),
                            onSelect: (value) {
                              setState(() {
                                selectedCountry = value;
                              });
                            },
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ' +${selectedCountry.phoneCode}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 24),
                          ],
                        ),
                      ),
                    ),
                    suffixIcon: phoneController.text.length >= 7
                        ? Container(
                            height: 20,
                            width: 20,
                            margin: const EdgeInsets.all(10.0),
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.black),
                            child: const Icon(
                              Icons.done,
                              size: 20,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        children: [
                          const Text("By continuing you agree to the "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Terms & Conditions",
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Text("."),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.07,
                  child: ElevatedButton(
                    onPressed:
                        signInWithPhone,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : const Text(
                            "Sign in with Phone",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.07,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : signUpWithPhone,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Sign up with Phone",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Text(
                  "By proceeding, you consent to get calls, whatsApp or SMS messages,including by automated means, from Velo and its affiliates to the number provided.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> signInWithPhone() async {
    final authRepo =
        Provider.of<AuthenticationProvider>(context, listen: false);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String phoneNumber = _normalizePhone(phoneController.text);

    // Validate the phone number
    if (phoneNumber.isEmpty || phoneNumber.length < 7 || phoneNumber.length > 15) {
      // Show error if the phone number is invalid
      commonMethods.displaySnackBar(
        "Please enter a valid mobile number.",
        context,
      );
      return;
    }

    // Append country code
    final String fullPhoneNumber = '+${selectedCountry.phoneCode}$phoneNumber';

    final bool exists = await authRepo.checkUserExistByPhone(fullPhoneNumber);
    if (!exists) {
      commonMethods.displaySnackBar(
        "No account found. Please use Sign up with Phone first.",
        context,
      );
      return;
    }

    final bool isBlocked = await authRepo.checkIfDriverIsBlocked();
    if (isBlocked) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BlockedScreen()),
      );
      return;
    }

    final bool isApproved = await authRepo.isDriverApproved();
    if (!isApproved) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DriverRegistration()),
      );
      commonMethods.displaySnackBar(
        "Your account is pending admin approval.",
        context,
      );
      return;
    }

    final bool isComplete = await authRepo.checkDriverFieldsFilled();
    if (isComplete) {
      navigate(isSingedIn: true);
    } else {
      navigate(isSingedIn: false);
      commonMethods.displaySnackBar("Please complete your profile.", context);
    }
  }

  Future<void> signUpWithPhone() async {
    final authRepo =
        Provider.of<AuthenticationProvider>(context, listen: false);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String phoneNumber = _normalizePhone(phoneController.text);
    if (phoneNumber.isEmpty || phoneNumber.length < 7 || phoneNumber.length > 15) {
      commonMethods.displaySnackBar(
        "Please enter a valid mobile number.",
        context,
      );
      return;
    }
    final String fullPhoneNumber = '+${selectedCountry.phoneCode}$phoneNumber';
    final bool exists = await authRepo.checkUserExistByPhone(fullPhoneNumber);
    if (exists) {
      commonMethods.displaySnackBar(
        "This phone number is already registered. Please sign in.",
        context,
      );
      return;
    }
    await authRepo.continueWithoutSms(
      context: context,
      phoneNumber: fullPhoneNumber,
    );
    navigate(isSingedIn: false);
  }

  String _normalizePhone(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.startsWith('0')) {
      return digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    }
    return digitsOnly;
  }

  void navigate({required bool isSingedIn}) {
    if (isSingedIn) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
          (route) => false);
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => DriverRegistration()));
    }
  }
}
