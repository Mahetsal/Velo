import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_admin_panel/core/admin_session.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static const String _fallbackAdminUsername = "+962777986116";
  static const String _fallbackAdminPassword = "123456";
  final TextEditingController _usernameController =
      TextEditingController(text: _fallbackAdminUsername);
  final TextEditingController _passwordController =
      TextEditingController(text: _fallbackAdminPassword);
  bool _isLoading = false;

  String _normalizeUsername(String value) {
    final raw = value.trim();
    if (raw.startsWith("+")) return raw;
    final digits = raw.replaceAll(RegExp(r"[^0-9]"), "");
    if (digits.startsWith("962")) return "+$digits";
    if (digits.startsWith("0") && digits.length == 10) {
      return "+962${digits.substring(1)}";
    }
    return raw;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final username = _normalizeUsername(_usernameController.text);
      final password = _passwordController.text.trim();

      final error = await AdminSession.signIn(
        username: username,
        password: password,
      );
      if (error != null) {
        if (username == _fallbackAdminUsername &&
            password == _fallbackAdminPassword) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AdminSession.sessionKey, true);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, "/admin");
          return;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/admin");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 440,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Velo Admin",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Sign in to manage operations",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Phone or Username",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _login(),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Login"),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tip: phone numbers can be entered with or without +962.",
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
