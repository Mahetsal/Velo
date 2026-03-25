import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/pages/home_page.dart';
import 'package:uber_users_app/pages/terms_page.dart';

import '../models/user_model.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({Key? key}) : super(key: key);

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController gmailController = TextEditingController();
  CommonMethods commonMethods = CommonMethods();
  bool acceptedTerms = false;
  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    gmailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    if (authProvider.isGoogleSignedIn == false) {
      phoneController.text = authProvider.phoneNumber;
    }

    if (authProvider.isGoogleSignedIn) {
      gmailController.text = authProvider.signedInEmail ?? "";
      phoneController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FB),
        centerTitle: true,
        title: const Text(
          'Profile Setup',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 25.0, horizontal: 35),
              child: Form(
                key: _formKey,
                child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Let's complete your profile",
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      // textFormFields
                      myTextFormField(
                        hintText: 'Enter Your Full Name',
                        icon: Icons.account_circle,
                        textInputType: TextInputType.name,
                        maxLines: 1,
                        maxLength: 25,
                        textEditingController: nameController,
                        enabled: true,
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return "Name must be at least 3 characters";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                      myTextFormField(
                        hintText: 'Enter Your Email Address',
                        icon: Icons.account_circle,
                        textInputType: TextInputType.emailAddress,
                        maxLines: 1,
                        maxLength: 25,
                        textEditingController: gmailController,
                        enabled: authProvider.isGoogleSignedIn ? false : true,
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty || !email.contains('@')) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      myTextFormField(
                        hintText: 'Enter your phone number',
                        icon: Icons.phone,
                        textInputType: TextInputType.number,
                        maxLines: 1,
                        maxLength: 15,
                        textEditingController: phoneController,
                        enabled: true,
                        validator: (value) {
                          final cleaned =
                              (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                          if (cleaned.length < 7 || cleaned.length > 15) {
                            return "Enter a valid phone number";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
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
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.07,
                    child: ElevatedButton(
                      onPressed:
                          saveUserDataToFireStore, // Correctly call the sendPhoneNumber function

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
                              "Continue",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget myTextFormField({
    required String hintText,
    required IconData icon,
    required TextInputType textInputType,
    required int maxLines,
    required int maxLength,
    required TextEditingController textEditingController,
    required bool enabled,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      enabled: enabled,
      cursorColor: Colors.grey,
      controller: textEditingController,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: const Color(0xFF111827)),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1570EF)),
        ),
        hintText: hintText,
        alignLabelWithHint: true,
        border: InputBorder.none,
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  // store user data to fireStore
  void saveUserDataToFireStore() async {
    //final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    final authProvider = context.read<AuthenticationProvider>();
    final cleanedDigits =
        phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    String normalizedPhone = phoneController.text.trim();
    if (cleanedDigits.startsWith('962') && cleanedDigits.length >= 12) {
      normalizedPhone = '+$cleanedDigits';
    } else if (cleanedDigits.startsWith('0') && cleanedDigits.length == 10) {
      normalizedPhone = '+962${cleanedDigits.substring(1)}';
    } else if (cleanedDigits.length == 9) {
      normalizedPhone = '+962$cleanedDigits';
    }

    UserModel userModel = UserModel(
        id: authProvider.uid!,
        name: nameController.text.trim(),
        phone: normalizedPhone,
        email: gmailController.text.trim(),
        blockStatus: "no",
        acceptedTerms: true,
        acceptedTermsVersion: "1.0",
        acceptedTermsAt: DateTime.now().toIso8601String());

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!acceptedTerms) {
      commonMethods.displaySnackBar(
          "Please accept Terms & Conditions to continue.", context);
      return;
    }
    if (nameController.text.length >= 3) {
      final pendingPassword = authProvider.consumePendingPassword();
      if ((pendingPassword ?? "").length < 6) {
        commonMethods.displaySnackBar(
          "Missing password. Please go back and set your password again.",
          context,
        );
        return;
      }
      authProvider.saveUserDataToFirebase(
        context: context,
        userModel: userModel,
        password: pendingPassword!,
        onSuccess: () async {
          // save user data locally
          //await authProvider.saveUserDataToSharedPref();

          // set signed in
          //await authProvider.setSignedIn();

          // go to home screen
          navigateToHomeScreen();
        },
      );
    } else {
      commonMethods.displaySnackBar(
          'Name must be atleast 3 characters', context);
    }
  }

  void navigateToHomeScreen() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false);
  }
}
