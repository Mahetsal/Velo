import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  final TextEditingController _promoController = TextEditingController();
  bool _saving = false;
  String _status = "";
  Map<String, dynamic>? _validatedPromo;
  List<Map<String, dynamic>> _availablePromos = [];
  bool _loadingPromos = false;

  @override
  void initState() {
    super.initState();
    _loadPromo();
    _loadAvailablePromos();
  }

  Future<void> _loadPromo() async {
    final prefs = await SharedPreferences.getInstance();
    _promoController.text = prefs.getString("default_promo_code") ?? "";
    final saved = _promoController.text.trim().toUpperCase();
    if (saved.isNotEmpty) {
      // Best-effort validation (no UI blocking).
      unawaited(_validateAndPreview(saved, silent: true));
    }
  }

  Future<void> _loadAvailablePromos() async {
    if (_loadingPromos) return;
    setState(() => _loadingPromos = true);
    try {
      // Best-effort endpoint: list promos. If backend doesn't support it,
      // we simply show none.
      final resp = await ApiClient.get("/promos");
      if (resp.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _availablePromos = [];
        });
        return;
      }
      final payload = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = (payload["items"] as List?) ?? const [];
      final promos = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Filter to active + eligible (best effort).
      final now = DateTime.now();
      final filtered = <Map<String, dynamic>>[];
      for (final p in promos) {
        final isActive = p["isActive"] == true;
        final validTill = DateTime.tryParse(p["validTill"]?.toString() ?? "");
        if (!isActive) continue;
        if (validTill != null && now.isAfter(validTill)) continue;
        final targetType = (p["targetType"] ?? "all").toString();
        final eligible = ((p["eligibleUserIds"] ?? []) as List)
            .map((e) => e.toString())
            .toList();
        if (targetType == "specific" && !eligible.contains(userID)) continue;
        filtered.add(p);
      }
      if (!mounted) return;
      setState(() => _availablePromos = filtered);
    } catch (_) {
      if (!mounted) return;
      setState(() => _availablePromos = []);
    } finally {
      if (mounted) setState(() => _loadingPromos = false);
    }
  }

  Future<bool> _validateAndPreview(String code, {bool silent = false}) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return true;
    try {
      final response = await ApiClient.get(
        "/promos/by-code/${Uri.encodeComponent(normalized)}",
      );
      if (response.statusCode != 200) {
        if (!silent && mounted) {
          setState(() => _validatedPromo = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.promoCodeNotFound)),
          );
        }
        return false;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final exists = (payload["exists"] ?? false) == true;
      if (!exists || payload["item"] == null) {
        if (!silent && mounted) {
          setState(() => _validatedPromo = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.promoCodeNotFound)),
          );
        }
        return false;
      }
      final promo = Map<String, dynamic>.from(payload["item"] as Map);

      final targetType = (promo["targetType"] ?? "all").toString();
      final eligibleUserIds = ((promo["eligibleUserIds"] ?? []) as List)
          .map((e) => e.toString())
          .toList();
      if (targetType == "specific" && !eligibleUserIds.contains(userID)) {
        if (!silent && mounted) {
          setState(() => _validatedPromo = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.promoNotEligible)),
          );
        }
        return false;
      }

      final isActive = promo["isActive"] == true;
      final validTill = DateTime.tryParse(promo["validTill"]?.toString() ?? "");
      if (!isActive ||
          (validTill != null && DateTime.now().isAfter(validTill))) {
        if (!silent && mounted) {
          setState(() => _validatedPromo = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.promoExpiredOrInactive)),
          );
        }
        return false;
      }

      if (mounted) setState(() => _validatedPromo = promo);
      return true;
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _validatedPromo = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.promoValidateFailed)),
        );
      }
      return false;
    }
  }

  Future<void> _savePromo() async {
    final code = _promoController.text.trim().toUpperCase();
    setState(() {
      _saving = true;
      _status = "";
    });
    if (code.isNotEmpty) {
      final ok = await _validateAndPreview(code);
      if (!ok) {
        if (!mounted) return;
        setState(() => _saving = false);
        return;
      }
    } else {
      setState(() => _validatedPromo = null);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("default_promo_code", code);

    // Best effort save to profile on backend if endpoint supports extra fields.
    try {
      await ApiClient.put("/users/$userID", body: {"defaultPromoCode": code});
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _saving = false;
      _status = code.isEmpty
          ? context.l10n.defaultPromoCleared
          : context.l10n.promoActivatedAutoApply;
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.promotions),
        backgroundColor: cs.surface.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            context.l10n.exclusiveOffersTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.exclusiveOffersSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.autoApplyDiscounts,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.autoApplyDiscountsSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_validatedPromo != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.activePromoLabel(
                        (_validatedPromo!["code"] ?? "").toString(),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF065F46),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _promoController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: context.l10n.promoCodeLabel,
              hintText: context.l10n.promoCodeHint,
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
            ),
            onChanged: (v) {
              if (_status.isNotEmpty) setState(() => _status = "");
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _savePromo,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(_saving ? context.l10n.saving : context.l10n.activateCode),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.availablePromos,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          if (_loadingPromos)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ))
          else if (_availablePromos.isEmpty)
            Text(
              context.l10n.noActivePromos,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
            )
          else
            ..._availablePromos.take(10).map((p) {
              final code = (p["code"] ?? "").toString();
              final discountType = (p["discountType"] ?? "percent").toString();
              final discountValue = (p["discountValue"] ?? "").toString();
              final label = discountType == "fixed"
                  ? context.l10n.promoFixedOff(discountValue)
                  : context.l10n.promoPercentOff(discountValue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(Icons.local_offer_rounded,
                            color: AppTheme.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              code,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onSurfaceMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _promoController.text = code;
                          setState(() {
                            _validatedPromo = null;
                            _status = "";
                          });
                        },
                        child: Text(context.l10n.use),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF065F46),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
