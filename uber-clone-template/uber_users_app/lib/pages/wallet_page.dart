import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';
import 'package:uber_users_app/widgets/velo_skeleton.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _loading = true;
  bool _hasError = false;
  double _balance = 0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    if (userID.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _balance = 0;
        _transactions = [];
      });
      return;
    }
    try {
      final resp = await ApiClient.get("/users/$userID");
      if (!mounted) return;
      if (resp.statusCode != 200) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
        return;
      }
      final payload = jsonDecode(resp.body) as Map<String, dynamic>;
      final item = (payload["item"] ?? {}) as Map;
      final bal = double.tryParse(item["walletBalance"]?.toString() ?? "0") ?? 0;
      final txs = (item["walletTransactions"] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _loading = false;
        _balance = bal;
        _transactions = txs;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.wallet),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
              children: const [
                VeloSkeletonBlock(height: 120, borderRadius: BorderRadius.all(Radius.circular(28))),
                SizedBox(height: 18),
                VeloSkeletonBlock(height: 18, width: 160),
                SizedBox(height: 10),
                VeloSkeletonBlock(height: 72),
                SizedBox(height: 10),
                VeloSkeletonBlock(height: 72),
              ],
            )
          : _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48, color: AppTheme.onSurfaceMuted),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.couldNotLoadWallet,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadWallet,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F0F172A),
                          blurRadius: 30,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.walletBalance,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_balance.toStringAsFixed(2)} JOD",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: context.l10n.topUp,
                          child: FilledButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.topUpComingSoon),
                                ),
                              );
                            },
                            child: Text(context.l10n.topUp),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.walletRecentActivity,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLowest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 32,
                              color: AppTheme.onSurfaceMuted.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.l10n.emptyWalletTitle,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.emptyWalletSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.onSurfaceMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._transactions.take(20).map((tx) {
                      final type = tx["type"]?.toString() ?? "";
                      final amount = tx["amount"]?.toString() ?? "";
                      final reason = tx["reason"]?.toString() ?? "";
                      final createdAt = tx["createdAt"]?.toString() ?? "";
                      final isCredit = type.toLowerCase() == "credit";
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLowest,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (isCredit
                                          ? const Color(0xFF12B76A)
                                          : AppTheme.accent)
                                      .withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isCredit
                                      ? const Color(0xFF12B76A)
                                      : AppTheme.accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reason.isEmpty
                                          ? (isCredit
                                              ? context.l10n.walletCredit
                                              : context.l10n.walletDebit)
                                          : reason,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      createdAt,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.onSurfaceMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${isCredit ? '+' : '-'}$amount",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: isCredit
                                      ? const Color(0xFF12B76A)
                                      : AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

