import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/pages/home_page.dart';
import 'package:uber_users_app/pages/terms_page.dart';
import 'package:uber_users_app/theme/app_theme.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';

import '../models/user_model.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.profileSetup),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.completeYourProfile,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      "assets/images/avatarman.png",
                      height: 190,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _UrbanField(
                    controller: nameController,
                    label: context.l10n.fullName,
                    icon: Icons.person_outline,
                    enabled: true,
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return context.l10n.nameMinChars;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _UrbanField(
                    controller: gmailController,
                    label: context.l10n.emailAddress,
                    icon: Icons.mail_outline,
                    enabled: authProvider.isGoogleSignedIn ? false : true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty || !email.contains('@')) {
                        return context.l10n.enterValidEmailAddress;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _UrbanField(
                    controller: phoneController,
                    label: context.l10n.phoneNumber,
                    icon: Icons.phone_outlined,
                    enabled: true,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final cleaned =
                          (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      if (cleaned.length < 7 || cleaned.length > 15) {
                        return context.l10n.enterValidPhoneNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: acceptedTerms,
                        onChanged: (v) {
                          setState(() => acceptedTerms = v ?? false);
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            Text(context.l10n.iAgreeToThe),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TermsPage(),
                                  ),
                                );
                              },
                              child: Text(
                                context.l10n.termsOfServiceText,
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(context.l10n.dot),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: saveUserDataToFireStore,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              context.l10n.continueText,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
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
          context.l10n.pleaseAcceptTermsToContinue, context);
      return;
    }
    if (nameController.text.length >= 3) {
      final pendingPassword = authProvider.consumePendingPassword();
      if ((pendingPassword ?? "").length < 6) {
        commonMethods.displaySnackBar(
          context.l10n.missingPasswordGoBack,
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
          context.l10n.nameMinChars, context);
    }
  }

  void navigateToHomeScreen() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false);
  }
}

class _UrbanField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _UrbanField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
