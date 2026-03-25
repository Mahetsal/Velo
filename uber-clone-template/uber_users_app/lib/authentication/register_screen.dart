import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/authentication/user_information_screen.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/pages/blocked_screen.dart';
import 'package:uber_users_app/pages/user_root_page.dart';
import 'package:uber_users_app/pages/privacy_policy_page.dart';
import 'package:uber_users_app/pages/terms_page.dart';
import 'package:uber_users_app/theme/app_theme.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';

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
        backgroundColor: AppTheme.surface,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x220F172A),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            context.l10n.brandInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.appName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.registerTagline,
                          style: const TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F172A),
                          blurRadius: 30,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isLoginMode = true),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isLoginMode
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      context.l10n.login,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isLoginMode
                                            ? AppTheme.onSurface
                                            : AppTheme.onSurfaceMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => isLoginMode = false),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !isLoginMode
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      context.l10n.signUp,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !isLoginMode
                                            ? AppTheme.accent
                                            : AppTheme.onSurfaceMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isLoginMode
                              ? context.l10n.welcomeBack
                              : context.l10n.welcomeSignUpTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isLoginMode
                              ? context.l10n.loginSubtitle
                              : context.l10n.signUpSubtitle,
                          style: const TextStyle(color: AppTheme.onSurfaceMuted),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.phoneNumberLabelUpper,
                          style: TextStyle(
                            color: AppTheme.onSurfaceMuted.withOpacity(0.9),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneController,
                          maxLength: 15,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final cleaned = _normalizePhone(value ?? "");
                            if (cleaned.length < 7 || cleaned.length > 15) {
                              return context.l10n.enterValidMobileNumber;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            counterText: '',
                            hintText: context.l10n.phoneHint,
                            hintStyle: const TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 16,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                                minWidth: 120, minHeight: 48),
                            prefixIcon: Container(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 4.0, 12.0),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  showCountryPicker(
                                    context: context,
                                    countryListTheme:
                                        const CountryListThemeData(
                                            borderRadius:
                                                BorderRadius.vertical(
                                                    top: Radius.circular(16)),
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                        shape: BoxShape.circle,
                                        color: AppTheme.onSurface),
                                    child: const Icon(
                                      Icons.done,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.passwordLabelUpper,
                          style: TextStyle(
                            color: AppTheme.onSurfaceMuted.withOpacity(0.9),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          validator: (value) {
                            if ((value ?? "").trim().length < 6) {
                              return context.l10n.passwordMinChars;
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF3F4F6),
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 15,
                            ),
                            suffixIcon: Icon(Icons.remove_red_eye_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!isLoginMode)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: acceptedTerms,
                                onChanged: (v) => setState(
                                    () => acceptedTerms = v ?? false),
                              ),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Text(context.l10n.iAcceptThe),
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
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(context.l10n.andAcknowledgeThe),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PrivacyPolicyPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        context.l10n.privacyPolicyText,
                                        style: const TextStyle(
                                          color: AppTheme.accent,
                                          fontWeight: FontWeight.w800,
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
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                isLoginMode ? loginWithPhone : signUpWithPhone,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isLoginMode
                                            ? context.l10n.login
                                            : context.l10n.createAccount,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(Directionality.of(context) == TextDirection.rtl
                                          ? Icons.arrow_back_rounded
                                          : Icons.arrow_forward_rounded),
                                    ],
                                  ),
                          ),
                        ),
                        if (isLoginMode) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: _showResetPasswordSheet,
                              child: Text(context.l10n.forgotPassword),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.l10n.registerFooterUpper,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.onSurfaceMuted.withOpacity(0.8),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 64,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 28,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
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
        context.l10n.pleaseEnterValidMobileNumber,
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
        context.l10n.profileIncompletePleaseCompleteSignup,
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
          context.l10n.pleaseAcceptTermsToContinue, context);
      return;
    }
    final String phoneNumber = _normalizePhone(phoneController.text);
    if (phoneNumber.isEmpty || phoneNumber.length < 7 || phoneNumber.length > 15) {
      commonMethods.displaySnackBar(
        context.l10n.pleaseEnterValidMobileNumber,
        context,
      );
      return;
    }
    final String fullPhoneNumber = '+${selectedCountry.phoneCode}$phoneNumber';
    final exists = await authRepo.checkUserExistByPhone(fullPhoneNumber);
    if (!mounted) return;
    if (exists) {
      if (!mounted) return;
      commonMethods.displaySnackBar(
        context.l10n.accountExistsPleaseLogin,
        context,
      );
      return;
    }
    final String password = passwordController.text.trim();
    if (password.length < 6) {
      commonMethods.displaySnackBar(
        context.l10n.passwordMinChars,
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
          MaterialPageRoute(builder: (context) => const UserRootPage()),
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
                Text(
                  context.l10n.resetPasswordTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneResetController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: context.l10n.phoneNumber,
                    hintText: context.l10n.resetPhoneHint,
                  ),
                  validator: (value) {
                    final cleaned = _normalizePhone(value ?? "");
                    if (cleaned.length < 7 || cleaned.length > 15) {
                      return context.l10n.enterValidPhoneNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: context.l10n.newPassword),
                  validator: (value) {
                    if ((value ?? "").trim().length < 6) {
                      return context.l10n.passwordMinChars;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: context.l10n.confirmPassword),
                  validator: (value) {
                    if ((value ?? "").trim() != newPasswordController.text.trim()) {
                      return context.l10n.passwordsDoNotMatch;
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
                      if (ok && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(context.l10n.resetPassword),
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
