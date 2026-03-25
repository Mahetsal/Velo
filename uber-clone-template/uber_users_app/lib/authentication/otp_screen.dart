import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/authentication/user_information_screen.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/pages/blocked_screen.dart';
import 'package:uber_users_app/pages/user_root_page.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  const OTPScreen({super.key, required this.verificationId});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

CommonMethods commonMethods = CommonMethods();

class _OTPScreenState extends State<OTPScreen> {
  String? smsCode;
  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthenticationProvider>(context, listen: true);
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  "SECURITY VERIFICATION",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Verify your\nnumber",
              style: TextStyle(
                fontSize: 40,
                height: 0.98,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "We've sent a 6-digit code to\nyour mobile device.",
              style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 16),
            ),
            const SizedBox(height: 22),
            Center(
              child: Pinput(
                length: 6,
                showCursor: true,
                defaultPinTheme: PinTheme(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onChanged: (v) => setState(() => smsCode = v),
                onCompleted: (value) {
                  setState(() => smsCode = value);
                  verifyOTP(smsCode: value);
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accent.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authRepo.isLoading ? "VERIFYING" : "VERIFY",
                      style: TextStyle(
                        color: AppTheme.accent.withOpacity(0.6),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Container(width: 1, height: 18, color: Colors.black12),
                const SizedBox(width: 18),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: authRepo.isSuccessful
                          ? const Color(0xFF047857)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authRepo.isSuccessful ? "VALID" : "PENDING",
                      style: TextStyle(
                        color: authRepo.isSuccessful
                            ? const Color(0xFF047857)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: (smsCode ?? "").length == 6 && !authRepo.isLoading
                    ? () => verifyOTP(smsCode: smsCode!)
                    : null,
                child: const Text(
                  "Confirm Code",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                "Didn't receive the code?",
                style: TextStyle(color: AppTheme.onSurfaceMuted),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "SMS resend is not available in this build.",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Resend Code (00:59)",
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void verifyOTP({required String smsCode}) {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    authProvider.verifyOTP(
      context: context,
      verificationId: widget.verificationId,
      smsCode: smsCode,
      onSuccess: () async {
        final navigator = Navigator.of(context);

        // 1. check database if the current user exist
        bool userExits = await authProvider.checkUserExistById();
        if (userExits) {
          // 2. Check if the driver is blocked
          bool isBlocked = await authProvider.checkIfUserIsBlocked();
          // 2. get user data from database

          if (isBlocked) {
            if (!mounted) return;
            // Navigate to Block Screen if blocked
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (_) => const BlockedScreen(),
              ),
            );
          } else {
            await authProvider.getUserDataFromFirebaseDatabase();
            // 4. Check if driver fields are filled
            bool isUserComplete = await authProvider.checkUserFieldsFilled();

            if (isUserComplete) {
              // Navigate to dashboard if profile is complete
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const UserRootPage()),
                (route) => false,
              );
            } else {
              // Navigate to driver registration if profile is incomplete
              if (!mounted) return;
              navigator.push(
                MaterialPageRoute(builder: (_) => const UserInformationScreen()),
              );
              commonMethods.displaySnackBar(
                "Fill your missing information!",
                context,
              );
            }
          }
        } else {
          // navigate to user information screen
          if (!mounted) return;
          navigator.push(
            MaterialPageRoute(builder: (_) => const UserInformationScreen()),
          );
        }
      },
    );
  }
}
