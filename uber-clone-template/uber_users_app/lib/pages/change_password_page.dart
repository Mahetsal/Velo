import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  bool _show = false;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final l10n = context.l10n;
    final phone = (userPhone.trim().isNotEmpty) ? userPhone.trim() : (auth.uid ?? "");
    final p1 = _newPassword.text.trim();
    final p2 = _confirmPassword.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sessionMissingPleaseLogin)),
      );
      return;
    }
    if (p1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters.")),
      );
      return;
    }
    if (p1 != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Uses the existing backend endpoint used from RegisterScreen.
      final ok = await auth.resetPasswordByPhone(
        context: context,
        phoneNumber: userPhone,
        newPassword: p1,
      );
      if (!mounted) return;
      if (ok) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.resetPasswordTitle),
        backgroundColor: cs.surface.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            context.l10n.resetPasswordTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            "Set a new password for your account.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _Field(
            label: "New password",
            controller: _newPassword,
            obscureText: !_show,
          ),
          const SizedBox(height: 12),
          _Field(
            label: "Confirm password",
            controller: _confirmPassword,
            obscureText: !_show,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Switch(
                value: _show,
                onChanged: (v) => setState(() => _show = v),
                activeColor: AppTheme.accent,
              ),
              Text(
                "Show password",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.resetPassword),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;

  const _Field({
    required this.label,
    required this.controller,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
        ),
      ),
    );
  }
}

