import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/authentication/user_information_screen.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/pages/blocked_screen.dart';
import 'package:uber_users_app/pages/home_page.dart';
import 'package:uber_users_app/pages/terms_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isLoginMode = true;
  bool acceptedTerms = false;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
    passwordController.dispose();
    super.dispose();
  }

  CommonMethods commonMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      "assets/images/velo_logo.png",
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Welcome to Velo",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Choose login for existing account or sign up for new",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isLoginMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isLoginMode
                                  ? const Color(0xFFE11D48)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Login",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isLoginMode ? Colors.white : const Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isLoginMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isLoginMode
                                  ? const Color(0xFFE11D48)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Sign up",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !isLoginMode ? Colors.white : const Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                      // Just trigger rebuild for suffix icon; controller updates automatically
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? "").trim().length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter password',
                    hintStyle: const TextStyle(
                      color: Color(0xFF98A2B3),
                      fontSize: 15,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1570EF)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                if (!isLoginMode)
                  Row(
                    children: [
                      Checkbox(
                        value: acceptedTerms,
                        onChanged: (v) {
                          setState(() {
                            acceptedTerms = v ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text("I agree to the "),
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
                    onPressed: isLoginMode ? loginWithPhone : signUpWithPhone,

                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFD90429),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : Text(
                            isLoginMode ? "Login with Phone" : "Create Account",
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
                if (isLoginMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showResetPasswordSheet,
                      child: const Text("Forgot password?"),
                    ),
                  ),
                const SizedBox(height: 18),
                const Text(
                  "Login uses phone + password, and account data is stored in the backend database.",
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

  Future<void> loginWithPhone() async {
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

    final loginOk = await authRepo.loginWithPhone(
      context: context,
      phoneNumber: fullPhoneNumber,
      password: passwordController.text.trim(),
    );
    if (!loginOk || !mounted) return;
    final isBlocked = await authRepo.checkIfUserIsBlocked();
    if (isBlocked) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BlockedScreen()),
      );
      return;
    }
    final profileDone = await authRepo.checkUserFieldsFilled();
    if (!mounted) return;
    if (profileDone) {
      navigate(isSingedIn: true);
    } else {
      commonMethods.displaySnackBar(
        "Account exists but profile is incomplete. Please complete sign up.",
        context,
      );
      navigate(isSingedIn: false);
    }
  }

  Future<void> signUpWithPhone() async {
    final authRepo =
        Provider.of<AuthenticationProvider>(context, listen: false);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!acceptedTerms) {
      commonMethods.displaySnackBar(
          "Please accept Terms & Conditions to continue.", context);
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
    final exists = await authRepo.checkUserExistByPhone(fullPhoneNumber);
    if (exists) {
      if (!mounted) return;
      commonMethods.displaySnackBar(
        "An account already exists with this phone. Please login.",
        context,
      );
      return;
    }
    final String password = passwordController.text.trim();
    if (password.length < 6) {
      commonMethods.displaySnackBar(
        "Password must be at least 6 characters.",
        context,
      );
      return;
    }
    authRepo.setPendingPassword(password);
    await authRepo.continueWithoutSms(
      context: context,
      phoneNumber: fullPhoneNumber,
    );
    if (!mounted) return;
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
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const UserInformationScreen()));
    }
  }

  Future<void> _showResetPasswordSheet() async {
    final formKey = GlobalKey<FormState>();
    final phoneResetController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Reset Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneResetController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone number",
                    hintText: "79xxxxxxx",
                  ),
                  validator: (value) {
                    final cleaned = _normalizePhone(value ?? "");
                    if (cleaned.length < 7 || cleaned.length > 15) {
                      return "Enter a valid phone number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New password"),
                  validator: (value) {
                    if ((value ?? "").trim().length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Confirm password"),
                  validator: (value) {
                    if ((value ?? "").trim() != newPasswordController.text.trim()) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      final authRepo = Provider.of<AuthenticationProvider>(
                        context,
                        listen: false,
                      );
                      final phone = _normalizePhone(phoneResetController.text);
                      final fullPhone = '+${selectedCountry.phoneCode}$phone';
                      final ok = await authRepo.resetPasswordByPhone(
                        context: context,
                        phoneNumber: fullPhone,
                        newPassword: newPasswordController.text.trim(),
                      );
                      if (ok && mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Reset password"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    phoneResetController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}
