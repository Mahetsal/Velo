import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  static const String _fallbackTermsEn = """
Velo Rider Terms & Conditions (Summary)

By using the Velo rider app, you agree to these terms. If you do not agree, please do not use the app.

1) Service
- Velo helps you request rides from independent drivers/providers.
- Availability may vary by time and location.

2) Accounts & Eligibility
- You must provide accurate account information.
- You are responsible for activity on your account.

3) Pricing & Payments
- Fares are estimated before the trip and may change based on route/time changes.
- Wallet payments require sufficient balance.
- Promotions are subject to eligibility, expiry, and usage limits.

4) Rider Conduct
- Treat drivers and others respectfully.
- You must comply with local laws and safety requirements.

5) Safety & Incidents
- In urgent situations, contact local emergency services.
- You may report issues through Support in the app.

6) Cancellations & Refunds
- Cancellations may be subject to fees depending on timing and driver assignment.
- Refund decisions depend on trip and payment details.

7) Privacy
- We process location and trip data to provide the service.
- We aim to minimize data collection and protect your information.

8) Changes
- Terms may be updated. Continued use means you accept the latest version.

Full legal terms can also be published in-app by the service operator.
""";

  static const String _fallbackTermsAr = """
شروط وأحكام فيلو للراكب (ملخص)

باستخدامك لتطبيق فيلو للراكب، فإنك توافق على هذه الشروط. إذا لم توافق، يرجى عدم استخدام التطبيق.

1) الخدمة
- يساعدك فيلو على طلب الرحلات من سائقين/مزودين مستقلين.
- قد يختلف توفر الخدمة حسب الوقت والموقع.

2) الحسابات والأهلية
- يجب تقديم معلومات حساب صحيحة.
- أنت مسؤول عن أي نشاط يتم عبر حسابك.

3) التسعير والمدفوعات
- يتم عرض تقدير للأجرة قبل الرحلة وقد يتغير حسب تغيّر المسار/الوقت.
- تتطلب مدفوعات المحفظة توفر رصيد كافٍ.
- العروض الترويجية تخضع للأهلية وتاريخ الانتهاء وحدود الاستخدام.

4) سلوك الراكب
- تعامل مع السائقين والآخرين باحترام.
- يجب الالتزام بالقوانين المحلية ومتطلبات السلامة.

5) السلامة والحوادث
- في الحالات الطارئة اتصل بخدمات الطوارئ المحلية.
- يمكنك الإبلاغ عن المشاكل من خلال الدعم داخل التطبيق.

6) الإلغاء والاسترداد
- قد يتم تطبيق رسوم إلغاء حسب التوقيت وتأكيد السائق.
- تعتمد قرارات الاسترداد على تفاصيل الرحلة وطريقة الدفع.

7) الخصوصية
- نعالج بيانات الموقع والرحلات لتقديم الخدمة.
- نسعى لتقليل جمع البيانات وحماية معلوماتك.

8) التغييرات
- قد يتم تحديث الشروط. استمرار الاستخدام يعني قبول أحدث إصدار.

يمكن أيضًا نشر الشروط القانونية الكاملة داخل التطبيق بواسطة مشغل الخدمة.
""";

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.termsTitle),
        backgroundColor: cs.surface.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<http.Response>(
        future: ApiClient.get("/settings/legal_terms"),
        builder: (context, snapshot) {
          final isArabic = Localizations.localeOf(context).languageCode == "ar";
          String content = context.l10n.termsNotAvailable;
          if (snapshot.hasData && snapshot.data!.statusCode == 200) {
            try {
              final payload =
                  jsonDecode(snapshot.data!.body) as Map<String, dynamic>;
              final item = (payload["item"] ?? {}) as Map;
              content = item["content"]?.toString() ?? content;
            } catch (_) {}
          }
          if (content.trim().isEmpty ||
              content.trim() == context.l10n.termsNotAvailable) {
            content = isArabic ? _fallbackTermsAr : _fallbackTermsEn;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.legalAgreement,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: AppTheme.accent,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.userTermsAndConditions,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.termsReadCarefully,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SelectableText(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: AppTheme.onSurface,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
