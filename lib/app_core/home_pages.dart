part of '../app_core.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إطارات وبطاريات العراق',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: yellow),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xff111111),
        selectedItemColor: yellow,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المحلات'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'السلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'طلباتي',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                decoration: const BoxDecoration(
                  color: Color(0xff101010),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu, color: Colors.white, size: 30),
                        Spacer(),
                        Column(
                          children: [
                            Text(
                              'إطارات وبطاريات العراق',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'الجودة .. بأقرب محل',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Spacer(),
                        Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                    SizedBox(height: 22),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: SizedBox(
                        height: 54,
                        child: Row(
                          children: [
                            SizedBox(width: 16),
                            Icon(Icons.search, size: 30),
                            SizedBox(width: 10),
                            Text(
                              'شنو تحتاج؟ إطارات أو بطاريات...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    button(
                      context,
                      Icons.directions_car,
                      'اختار سيارتك',
                      'اعرف قياس الإطار المناسب لسيارتك',
                      yellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CarsPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: cat(
                            context,
                            Icons.tire_repair,
                            'الإطارات',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TiresPage(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: cat(
                            context,
                            Icons.battery_charging_full,
                            'البطاريات',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BatteriesPage(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.location_on,
                      'المحلات القريبة',
                      'المسافة + الأقرب + الاتجاهات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NearbyShopsPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.add_business,
                      'إضافة محل',
                      'طلب انضمام لأصحاب المحلات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddShopPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.local_offer,
                      'العروض والخصومات',
                      'شوف أحدث العروض المتوفرة',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OffersPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.support_agent,
                      'التواصل مع الدعم',
                      'مساعدة واستفسارات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupportPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget button(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 45, color: Colors.black),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new, size: 18),
          ],
        ),
      ),
    );
  }

  static Widget cat(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xff171717),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: yellow, size: 52),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
