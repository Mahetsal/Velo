import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenSupportAction)),
      );
    }
  }

  void _showFaq(BuildContext context, String title, List<Map<String, String>> faqs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: faqs.length,
                  separatorBuilder: (_, __) => const Divider(height: 18),
                  itemBuilder: (context, i) {
                    final q = faqs[i]["q"] ?? "";
                    final a = faqs[i]["a"] ?? "";
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        q,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              a,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.onSurfaceMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final paymentFaq = [
      {
        "q": context.l10n.supportPaymentQ1,
        "a": context.l10n.supportPaymentA1,
      },
      {
        "q": context.l10n.supportPaymentQ2,
        "a": context.l10n.supportPaymentA2,
      },
      {
        "q": context.l10n.supportPaymentQ3,
        "a": context.l10n.supportPaymentA3,
      },
    ];

    final etaFaq = [
      {
        "q": context.l10n.supportEtaQ1,
        "a": context.l10n.supportEtaA1,
      },
      {
        "q": context.l10n.supportEtaQ2,
        "a": context.l10n.supportEtaA2,
      },
      {
        "q": context.l10n.supportEtaQ3,
        "a": context.l10n.supportEtaA3,
      },
    ];

    final safetyFaq = [
      {
        "q": context.l10n.supportSafetyQ1,
        "a": context.l10n.supportSafetyA1,
      },
      {
        "q": context.l10n.supportSafetyQ2,
        "a": context.l10n.supportSafetyA2,
      },
      {
        "q": context.l10n.supportSafetyQ3,
        "a": context.l10n.supportSafetyA3,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.support),
        backgroundColor: cs.surface.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.supportHeroTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.supportHeroSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.supportLiveActive,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SupportTile(
                  color: cs.surfaceContainerLowest,
                  icon: Icons.chat_bubble_rounded,
                  iconColor: const Color(0xFF25D366),
                  title: context.l10n.supportWhatsApp,
                  subtitle: context.l10n.supportInstantReplies,
                  onTap: () => _launchUri(
                    context,
                    Uri.parse("https://wa.me/962790000000"),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SupportTile(
                  color: cs.surfaceContainerLowest,
                  icon: Icons.call_rounded,
                  iconColor: AppTheme.accent,
                  title: context.l10n.supportCallCenter,
                  subtitle: context.l10n.supportDedicatedLine,
                  onTap: () => _launchUri(context, Uri.parse("tel:+962790000000")),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SupportTile(
            color: cs.surfaceContainerLowest,
            icon: Icons.mail_rounded,
            iconColor: AppTheme.onSurfaceMuted,
            title: context.l10n.supportEmailUs,
            subtitle: "support@velo.app",
            onTap: () => _launchUri(
              context,
              Uri.parse(
                "mailto:support@velo.app?subject=Velo%20Support%20Request",
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.commonHelp,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          _CommonHelpTile(
            icon: Icons.payments_rounded,
            title: context.l10n.supportPaymentAndCharges,
            subtitle: context.l10n.supportPaymentAndChargesSubtitle,
            onTap: () =>
                _showFaq(context, context.l10n.paymentChargesFaqTitle, paymentFaq),
          ),
          const SizedBox(height: 8),
          _CommonHelpTile(
            icon: Icons.location_on_rounded,
            title: context.l10n.supportDriverMovementEta,
            subtitle: context.l10n.supportDriverMovementEtaSubtitle,
            onTap: () => _showFaq(context, context.l10n.etaFaqTitle, etaFaq),
          ),
          const SizedBox(height: 8),
          _CommonHelpTile(
            icon: Icons.shield_rounded,
            title: context.l10n.supportSafetyConcerns,
            subtitle: context.l10n.supportSafetyConcernsSubtitle,
            danger: true,
            onTap: () => _showFaq(context, context.l10n.safetyFaqTitle, safetyFaq),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.05),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommonHelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback onTap;

  const _CommonHelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ic = danger ? AppTheme.accent : AppTheme.onSurfaceMuted;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: ic),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
      ),
    );
  }
}
