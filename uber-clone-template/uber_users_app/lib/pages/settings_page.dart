import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/pages/change_password_page.dart';
import 'package:uber_users_app/pages/privacy_policy_page.dart';
import 'package:uber_users_app/pages/terms_page.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _notificationsKey = "notifications_enabled";
  static const String _defaultPaymentKey = "default_payment_method";

  bool _loading = true;
  bool _notificationsEnabled = true;
  String _defaultPaymentMethod = "Cash";
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appInfo = Provider.of<AppInfoClass>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      final method = prefs.getString(_defaultPaymentKey) ?? "Cash";
      _defaultPaymentMethod = (method == "Wallet") ? "Wallet" : "Cash";
      _themeMode = appInfo.themeMode;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
    await prefs.setString(_defaultPaymentKey, _defaultPaymentMethod);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appInfo = Provider.of<AppInfoClass>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
        backgroundColor: cs.surface.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  context.l10n.settings,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.settingsSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  icon: Icons.language_rounded,
                  title: context.l10n.language,
                  subtitle: context.l10n.languageSubtitle,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: appInfo.locale.languageCode,
                      items: const [
                        DropdownMenuItem(value: "en", child: Text("English (US)")),
                        DropdownMenuItem(value: "ar", child: Text("العربية (Jordan)")),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        await appInfo.setLocale(Locale(value));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.dark_mode_rounded,
                  title: context.l10n.appearance,
                  subtitle: context.l10n.appearanceSubtitle,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: _themeMode,
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(context.l10n.system),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(context.l10n.light),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(context.l10n.dark),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _themeMode = value);
                        await appInfo.setThemeMode(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.notifications_rounded,
                  title: context.l10n.notifications,
                  subtitle: context.l10n.notificationsSubtitle,
                  child: Switch(
                    value: _notificationsEnabled,
                    activeColor: AppTheme.accent,
                    onChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      await _save();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.account_balance_wallet_rounded,
                  title: context.l10n.defaultPayment,
                  subtitle: context.l10n.defaultPaymentSubtitle,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _defaultPaymentMethod,
                      items: const [
                        DropdownMenuItem(value: "Cash", child: Text("Cash Payment")),
                        DropdownMenuItem(value: "Wallet", child: Text("Velo Wallet")),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _defaultPaymentMethod = value);
                        await _save();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.l10n.legalSectionTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage()),
                    );
                  },
                  child: _SettingsCard(
                    icon: Icons.privacy_tip_outlined,
                    title: context.l10n.settingsOpenPrivacy,
                    subtitle: context.l10n.privacyPolicyTitle,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsPage()),
                    );
                  },
                  child: _SettingsCard(
                    icon: Icons.gavel_rounded,
                    title: context.l10n.settingsOpenTerms,
                    subtitle: context.l10n.userTermsAndConditions,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                    );
                  },
                  child: _SettingsCard(
                    icon: Icons.lock_reset_rounded,
                    title: context.l10n.resetPasswordTitle,
                    subtitle: context.l10n.changePasswordSubtitle,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    context.l10n.settingsFooter,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.10),
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
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
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
          child,
        ],
      ),
    );
  }
}
