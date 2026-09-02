part of '../app_core.dart';

class OrderCodePage extends StatelessWidget {
  final String title;
  final String detail;
  final int price;

  const OrderCodePage({
    super.key,
    required this.title,
    required this.detail,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final code = newOrderCode();

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              color: yellow,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(detail),
                    const SizedBox(height: 8),
                    Text(
                      'السعر النهائي: ${money(price)} د.ع',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'كود الطلب',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: code,
                width: 190,
                height: 190,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: code,
                width: 290,
                height: 90,
                drawText: true,
              ),
            ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'خلي هذا الكود وياك. من توصل للمحل، صاحب المحل يستلم الكود أو يمسح الـQR قبل تنفيذ الطلب.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    const offers = [
      ('عرض الإطارات', 'خصومات على قياسات مختارة حسب المخزون.'),
      ('تركيب وبلنص', 'خدمات إضافية مجانية مع بعض العروض.'),
      ('عرض نهاية الأسبوع', 'أسعار خاصة لفترة محدودة.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('العروض والخصومات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'العروض الحالية',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...offers.map(
              (offer) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: yellow,
                    child: Icon(Icons.local_offer),
                  ),
                  title: Text(
                    offer.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(offer.$2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '07722617795',
  );
  static const supportWhatsApp = '9647722617795';
  static const supportMessage =
      'السلام عليكم، أحتاج مساعدة في تطبيق Auto Deals Iraq';

  Future<void> _openSupportLink(
    BuildContext context,
    Uri uri,
    String errorMessage,
  ) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> openWhatsApp(BuildContext context) async {
    final uri = Uri.https('wa.me', '/$supportWhatsApp', {
      'text': supportMessage,
    });
    await _openSupportLink(context, uri, 'تعذر فتح واتساب');
  }

  Future<void> sendSms(BuildContext context) async {
    final uri = Uri(
      scheme: 'sms',
      path: supportPhone,
      queryParameters: {'body': supportMessage},
    );
    await _openSupportLink(context, uri, 'تعذر فتح تطبيق الرسائل');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التواصل مع الدعم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(Icons.support_agent, size: 90, color: yellow),
            const SizedBox(height: 14),
            const Text(
              'شلون نكدر نساعدك؟',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('راسلنا على واتساب'),
                subtitle: const Text(supportPhone),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => openWhatsApp(context),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sms_outlined),
                title: const Text('إرسال رسالة SMS'),
                subtitle: const Text(supportPhone),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => sendSms(context),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('التواصل الكتابي فقط'),
                subtitle: Text(
                  'يفتح واتساب أو تطبيق الرسائل في جهازك بدون إجراء مكالمة.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
