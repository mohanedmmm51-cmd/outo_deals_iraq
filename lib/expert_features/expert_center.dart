part of '../expert_features.dart';

class ExpertCenterPage extends StatelessWidget {
  const ExpertCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مركز الخبير')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff111111),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium, color: yellow, size: 58),
                  SizedBox(height: 8),
                  Text(
                    'خبرة عملية قبل لا تشتري',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'اختيار صحيح للإطار والبطارية، مقارنة واضحة، ونصائح تمنع الشراء الغلط.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            expertButton(
              context,
              Icons.tips_and_updates,
              'نصيحة الخبير',
              'DOT، التآكل، الضغط، المدينة والسفر',
              Colors.white,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpertAdvicePage()),
              ),
            ),
            const SizedBox(height: 12),
            expertButton(
              context,
              Icons.compare_arrows,
              'مقارنة الإطارات',
              'قارن حتى 3 قياسات وأسعار ونصيحة الاستخدام',
              Colors.white,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TireComparisonPage()),
              ),
            ),
            const SizedBox(height: 12),
            expertButton(
              context,
              Icons.battery_saver,
              'مساعد البطارية',
              'اختيار حسب الأمبير وStart/Stop والبطارية القديمة',
              Colors.white,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BatteryAdvisorPage()),
              ),
            ),
            const SizedBox(height: 12),
            expertButton(
              context,
              Icons.directions_car,
              'القياس حسب السيارة',
              'شركة → موديل → سنة → فئة → قياس',
              Colors.white,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const legacy.CarsPage()),
              ),
            ),
            const SizedBox(height: 12),
            expertButton(
              context,
              Icons.history,
              'سجل السيارة والضمان',
              'احفظ التركيب والكيلومترات والضمان',
              Colors.white,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MaintenanceRecordsPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
