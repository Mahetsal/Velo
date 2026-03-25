import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/pages/promo_page.dart';
import 'package:uber_users_app/pages/profile_page.dart';
import 'package:uber_users_app/pages/settings_page.dart';
import 'package:uber_users_app/pages/wallet_page.dart';
import 'package:uber_users_app/theme/app_theme.dart';
import 'package:uber_users_app/widgets/sign_out_dialog.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String _defaultPaymentMethod = "Cash";
  String _defaultPromoCode = "";

  @override
  void initState() {
    super.initState();
    _loadLocalPrefs();
  }

  Future<void> _loadLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _defaultPaymentMethod = prefs.getString("default_payment_method") ?? "Cash";
      _defaultPromoCode = prefs.getString("default_promo_code") ?? "";
    });
  }

  Future<void> _setDefaultPayment(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("default_payment_method", method);
    if (!mounted) return;
    setState(() => _defaultPaymentMethod = method);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.defaultPaymentChangedTo(method))),
    );
  }

  Widget _headerCard() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
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
                  userName.isEmpty ? context.l10n.veloCustomer : userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail.isEmpty ? context.l10n.noEmailYet : userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              size: 16, color: Color(0xFFEAB308)),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.goldMember,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: AppTheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        userPhone.isEmpty
                            ? context.l10n.phoneUpper
                            : context.l10n.verifiedUpper,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: AppTheme.accent,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFFCBD5E1),
            tooltip: context.l10n.profile,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: cs.surface.withOpacity(0.92),
            surfaceTintColor: Colors.transparent,
            title: Text(context.l10n.account),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverToBoxAdapter(child: _headerCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    context.l10n.accountOverviewUpper,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: AppTheme.onSurfaceMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<http.Response>(
                future: ApiClient.get("/users/$userID"),
                builder: (_, snapshot) {
                  String walletText = "0.00";
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
                  return Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded,
                                color: AppTheme.accent),
                          ),
                          title: Text(
                            context.l10n.paymentsAndWallet,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            context.l10n.manageBalanceAndMethods,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.onSurfaceMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          trailing: Text(
                            "$walletText JOD",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WalletPage()),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const WalletPage()),
                                    );
                                  },
                                  icon: const Icon(Icons.add_card_rounded),
                                  label: Text(context.l10n.topUp),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: cs.surfaceContainerHigh,
                                    foregroundColor: AppTheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    final method = _defaultPaymentMethod == "Cash"
                                        ? "Wallet"
                                        : "Cash";
                                    await _setDefaultPayment(method);
                                  },
                                  icon: const Icon(Icons.payments_rounded),
                                  label: Text(_defaultPaymentMethod),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    foregroundColor: Colors.white,
                                  ),
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child:
                        const Icon(Icons.local_offer_rounded, color: AppTheme.accent),
                  ),
                  title: Text(context.l10n.promotions,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(
                    _defaultPromoCode.isEmpty
                        ? context.l10n.noSavedPromo
                        : context.l10n.activePromo(_defaultPromoCode),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PromoPage()),
                      );
                      _loadLocalPrefs();
                    },
                    child: Text(context.l10n.viewAll),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PromoPage()),
                    );
                    _loadLocalPrefs();
                  },
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.settingsAndPrivacyUpper,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: AppTheme.onSurfaceMuted,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _ToggleRow(
                      icon: Icons.notifications_rounded,
                      title: context.l10n.notifications,
                      value: true,
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 8),
                    Consumer<AppInfoClass>(
                      builder: (context, appInfo, _) {
                        final isDark = appInfo.themeMode == ThemeMode.dark;
                        return _ToggleRow(
                          icon: Icons.dark_mode_rounded,
                          title: context.l10n.darkAppearance,
                          value: isDark,
                          onChanged: (value) async {
                            await appInfo.setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(context.l10n.appSettings,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFCBD5E1)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _MiniActionTile(
                  icon: Icons.logout_rounded,
                  title: context.l10n.logout,
                  danger: true,
                  onTap: () async {
                    final authProvider = Provider.of<AuthenticationProvider>(
                      context,
                      listen: false,
                    );
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return SignOutDialog(
                          title: context.l10n.logout,
                          description: context.l10n.logoutConfirm,
                          onSignOut: () async {
                            await authProvider.signOut(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Center(
                child: Text(
                  context.l10n.madeInAmman,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: AppTheme.onSurfaceMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            )),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accent,
        ),
      ],
    );
  }
}

class _MiniActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _MiniActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = danger ? const Color(0xFFB91C1C) : AppTheme.onSurface;
    final ic = danger ? const Color(0xFFB91C1C) : AppTheme.accent;
    final bg = danger ? const Color(0xFFFEE2E2) : cs.surfaceContainerLowest;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: ic),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
