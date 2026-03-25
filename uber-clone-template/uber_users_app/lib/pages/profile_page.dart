import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  bool _editMode = false;
  bool _saving = false;
  Future<http.Response>? _walletFuture;

  void _refreshWallet() {
    setState(() {
      _walletFuture = ApiClient.get("/users/$userID");
    });
  }

  void setDriverInfo() {
    setState(() {
      nameTextEditingController.text = userName;
      phoneTextEditingController.text = userPhone;
      emailTextEditingController.text = userEmail;
    });
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    final l10n = context.l10n;
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    final hadSessionToken =
        (authProvider.authToken != null && authProvider.authToken!.isNotEmpty);
    final newName = nameTextEditingController.text.trim();
    final newEmail = emailTextEditingController.text.trim();
    final newPhone = phoneTextEditingController.text.trim();

    if (newName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameMinChars)),
      );
      return;
    }
    if (newEmail.isNotEmpty && !newEmail.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidEmail)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (userID.isEmpty) {
        throw Exception(l10n.sessionMissingPleaseLogin);
      }

      // Read current record first, then send a merged PUT. Some backends treat PUT
      // as replace and will reject partial bodies (often surfaced as 401/403/validation).
      final getResp = await ApiClient.get("/users/$userID");
      if (getResp.statusCode != 200) {
        throw Exception(l10n.couldNotLoadProfile);
      }
      final payload = jsonDecode(getResp.body) as Map<String, dynamic>;
      final item = Map<String, dynamic>.from((payload["item"] ?? {}) as Map);
      final exists = (payload["exists"] ?? false) == true;
      if (!exists || item.isEmpty) {
        throw Exception(l10n.profileNotFound);
      }

      // Only send the fields our backend model expects + preserve any required flags.
      final merged = <String, dynamic>{
        "id": (item["id"]?.toString().trim().isNotEmpty == true)
            ? item["id"].toString()
            : userID,
        "name": newName,
        "email": newEmail,
        "phone": newPhone,
        "blockStatus": (item["blockStatus"] ?? "no").toString(),
        "acceptedTerms": item["acceptedTerms"] ?? true,
        "acceptedTermsVersion": (item["acceptedTermsVersion"] ?? "1.0").toString(),
        "acceptedTermsAt": (item["acceptedTermsAt"] ?? "").toString(),
      };

      final putResp = await ApiClient.put("/users/$userID", body: merged);

      http.Response effectivePutResp = putResp;
      if ((putResp.statusCode == 401 || putResp.statusCode == 403) &&
          hadSessionToken) {
        effectivePutResp = await ApiClient.put("/users/$userID", body: merged);
      }
      if (effectivePutResp.statusCode == 401 ||
          effectivePutResp.statusCode == 403) {
        throw Exception(l10n.unauthorizedPleaseLoginAgain);
      }
      if (effectivePutResp.statusCode < 200 ||
          effectivePutResp.statusCode >= 300) {
        final body = effectivePutResp.body.trim();
        final lowered = body.toLowerCase();
        if (lowered.contains("auth failed") || lowered.contains("unauthorized")) {
          throw Exception(l10n.unauthorizedPleaseLoginAgain);
        }
        throw Exception(body.isEmpty ? l10n.saveFailedTryAgain : body);
      }

      // Update globals so other screens immediately reflect changes.
      userName = newName;
      userEmail = newEmail;
      userPhone = newPhone;

      if (!mounted) return;
      _refreshWallet();
      setState(() => _editMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshWallet();
    setDriverInfo();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.profile,
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: cs.surface.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_editMode) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _editMode = false;
                  setDriverInfo();
                });
              },
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: Text(context.l10n.save),
            ),
          ] else
            TextButton(
              onPressed: () => setState(() => _editMode = true),
              child: Text(context.l10n.edit),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: cs.surfaceContainerLow,
                  image: const DecorationImage(
                    image: AssetImage("assets/images/avatarman.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isEmpty ? "Velo Customer" : userName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Premium Member",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.22),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: FutureBuilder<http.Response>(
              future: _walletFuture,
              builder: (_, snapshot) {
                String walletText = "—";
                if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                  try {
                    final payload =
                        jsonDecode(snapshot.data!.body) as Map<String, dynamic>;
                    final item = (payload["item"] ?? {}) as Map;
                    final walletRaw = item["walletBalance"]?.toString() ?? "0";
                    final wallet = double.tryParse(walletRaw) ?? 0;
                    walletText = wallet.toStringAsFixed(2);
                  } catch (_) {}
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AVAILABLE BALANCE",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          walletText,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "JOD",
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _ProfileField(
            icon: Icons.person_rounded,
            label: context.l10n.fullName,
            controller: nameTextEditingController,
            enabled: _editMode,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            icon: Icons.call_rounded,
            label: context.l10n.phoneNumber,
            controller: phoneTextEditingController,
            enabled: _editMode,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            icon: Icons.mail_rounded,
            label: context.l10n.emailAddress,
            controller: emailTextEditingController,
            enabled: _editMode,
            keyboardType: TextInputType.emailAddress,
          ),

            // const SizedBox(
            //   height: 12,
            // ),

            // //logout btn
            // ElevatedButton(
            //   onPressed: () {
            //     Sign out handled via auth provider.
            //     Navigator.push(context,
            //         MaterialPageRoute(builder: (c) => const LoginScreen()));
            //   },
            //   style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.pink,
            //       padding: const EdgeInsets.symmetric(
            //           horizontal: 80, vertical: 18)),
            //   child: const Text("Logout"),
            // ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.controller,
    this.enabled = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: AppTheme.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: AppTheme.onSurfaceMuted,
                      ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
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
