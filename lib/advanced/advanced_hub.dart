part of '../advanced_features.dart';

class AdvancedHubPage extends StatelessWidget {
  const AdvancedHubPage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Widget)>[
      (Icons.favorite, 'المفضلة', 'احفظ المقاسات والمحلات المفضلة', const FavoritesPage()),
      (Icons.notifications_active, 'تنبيه توفر القياس', 'تابع القياسات غير المتوفرة', const AvailabilityWatchPage()),
      (Icons.compare_arrows, 'مقارنة المحلات', 'السعر + البعد + التقييم + التوفر', const ShopComparePage()),
      (Icons.calendar_month, 'حجز موعد', 'احجز وقت للشد/البلنص أو تبديل البطارية', const AppointmentPage()),
      (Icons.stars, 'النقاط والمكافآت', 'نقاط للطلبات المنفذة والمكافآت', const RewardsPage()),
      (Icons.confirmation_number, 'كوبونات الخصم', 'كوبونات الإدارة والمحلات', const CouponsPage()),
      (Icons.group_add, 'برنامج الإحالة', 'شارك كود دعوة واكسب نقاط', const ReferralPage()),
      (Icons.receipt_long, 'الفاتورة الرقمية', 'فاتورة للطلبات المنفذة', const DigitalInvoicesPage()),
      (Icons.photo_library, 'الصور', 'صور المنتجات والمحلات والفروع', const MediaGalleryPage()),
      (Icons.filter_alt, 'فلترة متقدمة', 'فلترة الإطارات والبطاريات', const ProductFilterPage()),
      (Icons.show_chart, 'تاريخ الأسعار', 'تابع ارتفاع ونزول الأسعار', const PriceHistoryPage()),
      (Icons.location_city, 'خريطة الطلب', 'المناطق الأعلى طلباً', const DemandHeatPage()),
      (Icons.qr_code_scanner, 'QR الوصول للمحل', 'مسح رمز المحل لإثبات الوصول', const ArrivalQrPage()),
      (Icons.security, 'مكافحة الاحتيال', 'كشف الأكواد والطلبات المشبوهة', const FraudSignalsPage()),
      (Icons.build_circle, 'تذكيرات الصيانة', 'ضغط الإطارات والدوران والفحص الدوري', const MaintenanceReminderPage()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الخدمات المتقدمة')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final x = items[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: advancedYellow, child: Icon(x.$1, color: Colors.black)),
                title: Text(x.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(x.$3),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                onTap: () => _open(context, x.$4),
              ),
            );
          },
        ),
      ),
    );
  }
}
