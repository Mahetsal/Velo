import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/pages/about_page.dart';
import 'package:uber_users_app/pages/privacy_policy_page.dart';
import 'package:uber_users_app/pages/support_page.dart';
import 'package:uber_users_app/pages/terms_page.dart';
import 'package:uber_users_app/theme/app_theme.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';

class CustomDrawer extends StatelessWidget {
  final String userName;

  const CustomDrawer({
    super.key,
    required this.userName,
  });

  Future<String> _fetchWalletBalance() async {
    if (userID.isEmpty) return "0.00";
    final response = await ApiClient.get("/users/$userID");
    if (response.statusCode != 200) return "0.00";
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final item = (payload["item"] ?? {}) as Map;
    final wallet = double.tryParse(item["walletBalance"]?.toString() ?? "0") ?? 0;
    return wallet.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget navItem({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool emphasized = false,
      Color? iconColor,
      Color? textColor,
    }) {
      final Color fg = emphasized ? AppTheme.accent : (textColor ?? AppTheme.onSurface);
      final Color ic = emphasized ? AppTheme.accent : (iconColor ?? AppTheme.onSurfaceMuted);
      return Semantics(
        button: true,
        label: label,
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: emphasized ? AppTheme.accent.withOpacity(0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(icon, color: ic),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fg,
                          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                        ),
                  ),
                ),
                Directionality.of(context) == TextDirection.rtl
                    ? const Icon(Icons.chevron_left_rounded, color: Color(0xFFCBD5E1))
                    : const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),);
    }

    return Drawer(
      backgroundColor: cs.surfaceContainerLowest,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accent,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.onSurfaceMuted,
                    tooltip: context.l10n.close,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FutureBuilder<String>(
                future: _fetchWalletBalance(),
                builder: (_, snapshot) {
                  final wallet = snapshot.data ?? "0.00";
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: cs.surfaceContainerLowest,
                            image: const DecorationImage(
                              image: AssetImage("assets/images/avatarman.png"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName.isEmpty
                                    ? context.l10n.veloCustomer
                                    : userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.onSurfaceMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      context.l10n.walletBalance,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.onSurfaceMuted,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "JOD $wallet",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.accent,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    navItem(
                      icon: Icons.info_outline_rounded,
                      label: context.l10n.aboutTitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    navItem(
                      icon: Icons.contact_support_outlined,
                      label: context.l10n.support,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SupportPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    navItem(
                      icon: Icons.description_outlined,
                      label: context.l10n.termsTitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TermsPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    navItem(
                      icon: Icons.privacy_tip_outlined,
                      label: context.l10n.privacyPolicyTitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
