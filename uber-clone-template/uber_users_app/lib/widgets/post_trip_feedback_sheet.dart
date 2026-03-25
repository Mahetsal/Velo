import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/observability/analytics_service.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class PostTripFeedbackSheet {
  static Future<void> show(
    BuildContext context, {
    String driverName = "",
    String driverPhotoUrl = "",
    String? tripId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _PostTripFeedbackBody(
        driverName: driverName,
        driverPhotoUrl: driverPhotoUrl,
        tripId: tripId,
      ),
    );
  }
}

class _PostTripFeedbackBody extends StatefulWidget {
  final String driverName;
  final String driverPhotoUrl;
  final String? tripId;

  const _PostTripFeedbackBody({
    required this.driverName,
    required this.driverPhotoUrl,
    this.tripId,
  });

  @override
  State<_PostTripFeedbackBody> createState() => _PostTripFeedbackBodyState();
}

class _PostTripFeedbackBodyState extends State<_PostTripFeedbackBody> {
  int _stars = 0;
  double _tipAmount = 0;
  final _commentController = TextEditingController();

  static const List<double> _tipOptions = [0, 0.50, 1.00, 2.00];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    final hasDriverName = widget.driverName.trim().isNotEmpty;
    final photoUrl = widget.driverPhotoUrl.isEmpty
        ? "https://firebasestorage.googleapis.com/v0/b/everyone-2de50.appspot.com/o/avatarman.png?alt=media&token=702d209c-9f99-46b2-832f-5bb986bc5eac"
        : widget.driverPhotoUrl;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasDriverName) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  photoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Text(
            hasDriverName
                ? context.l10n.howWasTripWith(widget.driverName)
                : context.l10n.howWasTrip,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),

          Semantics(
            label: context.l10n.howWasTrip,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final n = i + 1;
                final on = n <= _stars;
                return IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _stars = n);
                  },
                  icon: Icon(
                    on ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: on ? AppTheme.accent : cs.outline,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _commentController,
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.l10n.feedbackCommentHint,
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          Text(
            context.l10n.addTip,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _tipOptions.map((amount) {
              final selected = _tipAmount == amount;
              final label = amount == 0
                  ? context.l10n.noTip
                  : context.l10n.tipAmount(amount.toStringAsFixed(2));
              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                      end: amount == _tipOptions.last ? 0 : 8),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppTheme.accent.withOpacity(0.15),
                    checkmarkColor: AppTheme.accent,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _tipAmount = amount);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.skipFeedback),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _stars == 0
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          final comment = _commentController.text.trim();
                          await AnalyticsService.logFeedbackSubmitted(
                            stars: _stars,
                            hasComment: comment.isNotEmpty,
                            tipAmount: _tipAmount,
                          );
                          if (_tipAmount > 0) {
                            await AnalyticsService.logTipAdded(
                                amount: _tipAmount);
                          }
                          if (!context.mounted) return;
                          if (_tipAmount > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(context.l10n.tipThanks)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(context.l10n.thanksForFeedback)),
                            );
                          }
                          Navigator.pop(context);
                        },
                  child: Text(context.l10n.submitFeedback),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
