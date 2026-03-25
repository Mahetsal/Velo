import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open support action.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Support Center")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Need help with a trip, payment, or account issue? Reach us using any option below.",
              style: TextStyle(color: Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text("WhatsApp Support"),
            subtitle: const Text("Fast support for active trip issues"),
            onTap: () => _launchUri(
              context,
              Uri.parse("https://wa.me/962790000000"),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            leading: const Icon(Icons.phone_outlined),
            title: const Text("Call Support"),
            subtitle: const Text("24/7 emergency and ride help"),
            onTap: () => _launchUri(context, Uri.parse("tel:+962790000000")),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            leading: const Icon(Icons.email_outlined),
            title: const Text("Email Support"),
            subtitle: const Text("For account and billing requests"),
            onTap: () => _launchUri(
              context,
              Uri.parse(
                "mailto:support@velo.app?subject=Velo%20Support%20Request",
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Common Help",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.receipt_long_outlined),
              title: Text("Payment issue"),
              subtitle: Text("Check trip history and share trip ID with support."),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.location_off_outlined),
              title: Text("Driver not moving"),
              subtitle: Text("Call driver first, then contact support if needed."),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text("Safety concern"),
              subtitle: Text("Call support immediately and share live trip details."),
            ),
          ),
        ],
      ),
    );
  }
}
