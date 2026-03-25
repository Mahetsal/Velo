import 'package:flutter/material.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';

class BidDialogWidget extends StatefulWidget {
  final double? initialFareAmount;
  final ValueChanged<double?> onBidAmountChanged;

  const BidDialogWidget({
    super.key,
    required this.initialFareAmount,
    required this.onBidAmountChanged,
  });

  @override
  State<BidDialogWidget> createState() => _BidDialogWidgetState();
}

class _BidDialogWidgetState extends State<BidDialogWidget> {
  final TextEditingController bidController = TextEditingController();
  String? _enteredBidAmount;

  @override
  void initState() {
    super.initState();
    bidController.text = widget.initialFareAmount.toString();
    _enteredBidAmount = widget.initialFareAmount?.toString();
  }

  void _showBidDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.setBidAmount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: bidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: _validateBidAmount(),
                  helperText:
                      context.l10n.bidRange(
                        _calculateLowerLimit().toStringAsFixed(2),
                        _calculateUpperLimit().toStringAsFixed(2),
                      ),
                  helperStyle: const TextStyle(color: Colors.black),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _enteredBidAmount = value; // Update the entered bid amount
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                context.l10n.cancel,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_validateBidAmount() == null) {
                  double? bidAmount = double.tryParse(bidController.text);
                  widget.onBidAmountChanged(bidAmount);
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: Text(
                context.l10n.ok,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _validateBidAmount() {
    double bid = double.tryParse(bidController.text) ?? 0.0;

    double lowerLimit = _calculateLowerLimit();
    double upperLimit = _calculateUpperLimit();

    if (bid < lowerLimit || bid > upperLimit) {
      return context.l10n.bidRange(
        lowerLimit.toStringAsFixed(2),
        upperLimit.toStringAsFixed(2),
      );
    }
    return null;
  }

  double _calculateLowerLimit() {
    return widget.initialFareAmount! * 0.90; // 10% lower
  }

  double _calculateUpperLimit() {
    return widget.initialFareAmount! * 1.20; // 20% higher
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      onPressed: () => _showBidDialog(context),
      child: Text(
        _enteredBidAmount == null || _validateBidAmount() != null
            ? context.l10n.setBid
            : context.l10n.bidAmount(_enteredBidAmount ?? ""),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
