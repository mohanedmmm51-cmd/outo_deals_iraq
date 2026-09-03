import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data_deletion.dart';

const privacyPolicyUrl = 'https://auto-deals-iraq.web.app/privacy';
const dataDeletionUrl = 'https://auto-deals-iraq.web.app/deletion';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  Future<void> _openPublicPolicy(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط سياسة الخصوصية')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              color: Color(0xFFFFD400),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.privacy_tip_outlined, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'سياسة خصوصية Auto Deals Iraq',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('آخر تحديث: 3 أيلول 2026'),
                  ],
                ),
              ),
            ),
            const _PolicySection(
              title: '1. نطاق السياسة',
              text:
                  'توضح هذه السياسة شلون يجمع تطبيق Auto Deals Iraq البيانات ويستخدمها ويحميها عند استعمال خدمات الإطارات والبطاريات والطلبات والمحلات والدعم.',
            ),
            const _PolicySection(
              title: '2. البيانات التي نجمعها',
              text:
                  'قد نجمع البريد الإلكتروني ومعرّف الحساب لأصحاب المحلات والإدارة، واسم المحل ورقم هاتفه وموقعه وفروعه ومخزونه. نحفظ بيانات الطلب مثل المنتج والسعر والكود والمحل والحالة والتوقيت والعمولة والتسوية. كذلك نحفظ رسائل الدعم وطلبات القياس والتقييمات والشكاوى والصور التي يختار المستخدم رفعها.\n\nتستخدم خدمات Firebase بيانات تقنية لازمة مثل رمز الإشعارات وتقارير الأعطال والأداء ومعلومات تقنية عامة عن الجهاز والاتصال.',
            ),
            const _PolicySection(
              title: '3. الموقع والكاميرا والإشعارات',
              text:
                  'نطلب الموقع أثناء استخدام ميزة المحلات القريبة لحساب المسافة، ويُعالج موقع الزبون على الجهاز ولا يُحفظ كملف تتبع. عند تسجيل محل، يُحفظ موقع المحل حتى يظهر للزبائن. نستخدم الكاميرا لمسح QR، ومعرض الصور فقط عند اختيار رفع صورة. الإشعارات تستخدم لتنبيهات الطلبات والخدمة. لا نجمع الموقع بالخلفية.',
            ),
            const _PolicySection(
              title: '4. شلون نستخدم البيانات',
              text:
                  'نستخدم البيانات لتشغيل الحسابات، عرض المحلات القريبة، إنشاء الطلبات وتنفيذها، تثبيت السعر، إدارة العمولات والتسويات، منع الاحتيال، الرد على رسائل الدعم، إرسال التنبيهات، وتحسين استقرار وأداء التطبيق.',
            ),
            const _PolicySection(
              title: '5. المشاركة مع الآخرين',
              text:
                  'لا نبيع البيانات الشخصية ولا نستخدمها للإعلانات. نشارك الحد الأدنى اللازم لتنفيذ الطلب مع المحل المختار. نعتمد على Google Firebase للمصادقة وقاعدة البيانات والتخزين والإشعارات وتقارير الأعطال والأداء والإعدادات. وعند اختيار الاتجاهات تُفتح خرائط Google، وعند البحث عن مركبة قد تُرسل بيانات البحث التقنية إلى VehDB. تخضع هذه الخدمات أيضاً لسياسات مزوديها.',
            ),
            const _PolicySection(
              title: '6. الحماية ومكان المعالجة',
              text:
                  'تنتقل البيانات عبر اتصالات مشفرة، ونستخدم مصادقة Firebase وقواعد وصول حسب صلاحية المستخدم. بعض البيانات المحلية مثل السلة والطلبات المحفوظة والتفضيلات تبقى على الجهاز. قد تعالج Google وFirebase البيانات في مراكز بيانات خارج العراق وفق ترتيباتها الأمنية والقانونية.',
            ),
            const _PolicySection(
              title: '7. الاحتفاظ والحذف',
              text:
                  'نحتفظ ببيانات الحساب مدة نشاطه. نعالج طلب حذف الحساب والبيانات خلال 30 يوماً بعد التحقق. قد نحتفظ بسجلات الطلبات والعمولات والتسويات لمدة تصل إلى 5 سنوات لأغراض المحاسبة وتسوية النزاعات ومنع الاحتيال، أو مدة أطول إذا ألزم القانون. قد تُحفظ محادثات الدعم حتى 12 شهراً بعد إغلاقها. تخضع تقارير الأعطال والأداء لمدد الاحتفاظ لدى Firebase.',
            ),
            const _PolicySection(
              title: '8. حقوق المستخدم',
              text:
                  'تقدر تطلب الاطلاع على بياناتك أو تصحيحها أو حذف حسابك وبياناتك. من داخل التطبيق افتح «حسابي» ثم «حذف الحساب والبيانات»، أو استخدم صفحة الحذف العامة. قد نطلب التحقق من ملكية الحساب قبل التنفيذ.',
            ),
            const _PolicySection(
              title: '9. الأطفال والتغييرات',
              text:
                  'التطبيق غير موجّه للأطفال دون 13 سنة. قد نحدّث هذه السياسة عند تغيير الخدمات أو المتطلبات، ويظهر تاريخ آخر تحديث أعلى الصفحة.',
            ),
            const _PolicySection(
              title: '10. التواصل بخصوص الخصوصية',
              text:
                  'لأي استفسار أو طلب متعلق بالخصوصية، استخدم «التواصل مع الدعم» داخل التطبيق. المراسلة تتم داخل التطبيق بدون إظهار رقم هاتف.',
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DataDeletionRequestPage(),
                ),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('طلب حذف الحساب والبيانات'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openPublicPolicy(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح النسخة المنشورة على الإنترنت'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            Text(text, style: const TextStyle(height: 1.55)),
          ],
        ),
      ),
    );
  }
}
