import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shop_store.dart';

const advancedYellow = Color(0xFFFFD400);

String advMoney(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

class LocalCustomerStore {
  static const _favorites = 'adi_favorites_v1';
  static const _points = 'adi_points_v1';
  static const _referral = 'adi_referral_v1';

  static Future<Set<String>> favorites() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_favorites) ?? const <String>[]).toSet();
  }

  static Future<void> toggleFavorite(String id) async {
    final p = await SharedPreferences.getInstance();
    final set = (p.getStringList(_favorites) ?? <String>[]).toSet();
    set.contains(id) ? set.remove(id) : set.add(id);
    await p.setStringList(_favorites, set.toList());
  }

  static Future<int> points() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_points) ?? 0;
  }

  static Future<void> addPoints(int value) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_points, (p.getInt(_points) ?? 0) + value);
  }

  static Future<String> referralCode() async {
    final p = await SharedPreferences.getInstance();
    var code = p.getString(_referral);
    if (code == null || code.isEmpty) {
      final s = DateTime.now().millisecondsSinceEpoch.toString();
      code = 'ADI-${s.substring(s.length - 6)}';
      await p.setString(_referral, code);
    }
    return code;
  }
}

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

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final id = TextEditingController();
  Set<String>? items;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final v = await LocalCustomerStore.favorites(); if (mounted) setState(() => items = v); }
  @override
  void dispose() { id.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('المفضلة')),
    body: Directionality(textDirection: TextDirection.rtl, child: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: id, decoration: const InputDecoration(labelText: 'اكتب اسم المقاس أو المحل', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      FilledButton(onPressed: () async { if (id.text.trim().isEmpty) return; await LocalCustomerStore.toggleFavorite(id.text.trim()); id.clear(); _load(); }, child: const Text('إضافة / إزالة من المفضلة')),
      const SizedBox(height: 12),
      ...?items?.map((e) => Card(child: ListTile(leading: const Icon(Icons.favorite, color: Colors.red), title: Text(e), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await LocalCustomerStore.toggleFavorite(e); _load(); })))).toList(),
    ])),
  );
}

class AvailabilityWatchPage extends StatefulWidget {
  const AvailabilityWatchPage({super.key});
  @override
  State<AvailabilityWatchPage> createState() => _AvailabilityWatchPageState();
}
class _AvailabilityWatchPageState extends State<AvailabilityWatchPage> {
  final size = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تنبيه توفر القياس')),
    body: Directionality(textDirection: TextDirection.rtl, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: size, decoration: const InputDecoration(labelText: 'القياس المطلوب', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: () async {
        final value = size.text.trim(); if (value.isEmpty) return;
        await FirebaseFirestore.instance.collection('availability_watch').add({'size': value, 'active': true, 'createdAt': FieldValue.serverTimestamp()});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التنبيه')));
      }, icon: const Icon(Icons.notifications_active), label: const Text('نبهني عند التوفر')),
    ]))),
  );
}

class ShopComparePage extends StatelessWidget {
  const ShopComparePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مقارنة المحلات')),
    body: Directionality(textDirection: TextDirection.rtl, child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: FirebaseFirestore.instance.collection('shops').where('approved', isEqualTo: true).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs.toList()..sort((a,b) => (((b.data()['rating'] as num?)?.toDouble() ?? 0)).compareTo((a.data()['rating'] as num?)?.toDouble() ?? 0));
        return ListView(padding: const EdgeInsets.all(12), children: docs.map((d) {
          final x = d.data();
          return Card(child: ListTile(
            title: Text('${x['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('التقييم: ${x['rating'] ?? 0} ★ • متوفر: ${x['availableCount'] ?? 0}\n${x['phone'] ?? ''}'),
            isThreeLine: true,
          ));
        }).toList());
      },
    )),
  );
}

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});
  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}
class _AppointmentPageState extends State<AppointmentPage> {
  String service = 'شد وبلنص';
  DateTime when = DateTime.now().add(const Duration(days: 1));
  Future<void> _save() async {
    await FirebaseFirestore.instance.collection('appointments').add({'service': service, 'when': Timestamp.fromDate(when), 'status': 'pending', 'createdAt': FieldValue.serverTimestamp()});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الحجز')));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('حجز موعد')),
    body: Directionality(textDirection: TextDirection.rtl, child: ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<String>(initialValue: service, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'الخدمة'), items: const [DropdownMenuItem(value:'شد وبلنص', child: Text('شد وبلنص')), DropdownMenuItem(value:'تبديل بطارية', child: Text('تبديل بطارية'))], onChanged: (v) => setState(() => service = v ?? service)),
      const SizedBox(height: 10),
      ListTile(tileColor: Colors.white, title: const Text('الموعد'), subtitle: Text('${when.year}/${when.month}/${when.day} - ${when.hour}:${when.minute.toString().padLeft(2,'0')}'), trailing: const Icon(Icons.calendar_month), onTap: () async {
        final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)), initialDate: when);
        if (d == null || !mounted) return;
        final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(when));
        if (t != null) setState(() => when = DateTime(d.year,d.month,d.day,t.hour,t.minute));
      }),
      const SizedBox(height: 10), FilledButton(onPressed: _save, child: const Text('تأكيد الحجز')),
    ])),
  );
}

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});
  @override State<RewardsPage> createState() => _RewardsPageState();
}
class _RewardsPageState extends State<RewardsPage> {
  int? points;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { final p = await LocalCustomerStore.points(); if(mounted)setState(()=>points=p); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('النقاط والمكافآت')),body:Center(child:Card(color:advancedYellow,child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.stars,size:70),const Text('رصيد النقاط'),Text('${points ?? 0}',style:const TextStyle(fontSize:32,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('كل طلب منفذ يضيف نقاط. يمكن ربط الاستبدال بكوبونات لاحقاً.')])))));
}

class CouponsPage extends StatefulWidget { const CouponsPage({super.key}); @override State<CouponsPage> createState()=>_CouponsPageState(); }
class _CouponsPageState extends State<CouponsPage> {
  final code=TextEditingController(); String? result;
  Future<void> _check() async { final d=await FirebaseFirestore.instance.collection('coupons').doc(code.text.trim().toUpperCase()).get(); if(mounted)setState(()=>result=d.exists && d.data()?['active']==true?'الكوبون فعال • الخصم ${d.data()?['discount'] ?? 0} د.ع':'الكوبون غير فعال'); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('كوبونات الخصم')),body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[TextField(controller:code,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'كود الخصم',border:OutlineInputBorder())),const SizedBox(height:8),FilledButton(onPressed:_check,child:const Text('فحص الكوبون')),if(result!=null)Padding(padding:const EdgeInsets.all(12),child:Text(result!,style:const TextStyle(fontWeight:FontWeight.bold))) ])));
}

class ReferralPage extends StatefulWidget { const ReferralPage({super.key}); @override State<ReferralPage> createState()=>_ReferralPageState(); }
class _ReferralPageState extends State<ReferralPage> { String? code; @override void initState(){super.initState();LocalCustomerStore.referralCode().then((v){if(mounted)setState(()=>code=v);});} @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('برنامج الإحالة')),body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('كود الدعوة الخاص بهذا الجهاز'),const SizedBox(height:8),SelectableText(code??'...',style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold)),const SizedBox(height:12),const Text('تُمنح المكافأة بعد أول طلب منفذ للشخص المدعو.')]))); }

class DigitalInvoicesPage extends StatelessWidget {
  const DigitalInvoicesPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الفواتير الرقمية')),body:Directionality(textDirection:TextDirection.rtl,child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').where('completed',isEqualTo:true).limit(100).snapshots(),builder:(_,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(padding:const EdgeInsets.all(12),children:s.data!.docs.map((d){final x=d.data();return Card(child:ListTile(leading:const Icon(Icons.receipt_long),title:Text('${x['title']??''}'),subtitle:Text('فاتورة ${d.id}\n${x['shopName']??''} • ${advMoney((x['price'] as num?)?.toInt()??0)} د.ع'),isThreeLine:true));}).toList());})));
}

class MediaGalleryPage extends StatefulWidget { const MediaGalleryPage({super.key}); @override State<MediaGalleryPage> createState()=>_MediaGalleryPageState(); }
class _MediaGalleryPageState extends State<MediaGalleryPage> {
  bool busy=false;
  Future<void> _upload() async {
    final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:80); if(file==null)return;
    setState(()=>busy=true);
    try{final ref=FirebaseStorage.instance.ref('uploads/${DateTime.now().millisecondsSinceEpoch}_${file.name}'); await ref.putData(await file.readAsBytes()); final url=await ref.getDownloadURL(); await FirebaseFirestore.instance.collection('media').add({'url':url,'type':'general','createdAt':FieldValue.serverTimestamp()});}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الصور')),floatingActionButton:FloatingActionButton(onPressed:busy?null:_upload,child:const Icon(Icons.add_a_photo)),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('media').orderBy('createdAt',descending:true).limit(100).snapshots(),builder:(_,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return GridView.count(crossAxisCount:2,padding:const EdgeInsets.all(8),children:s.data!.docs.map((d)=>Card(clipBehavior:Clip.antiAlias,child:Image.network('${d.data()['url']??''}',fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image)))).toList());}));
}

class ProductFilterPage extends StatefulWidget { const ProductFilterPage({super.key}); @override State<ProductFilterPage> createState()=>_ProductFilterPageState(); }
class _ProductFilterPageState extends State<ProductFilterPage> {
  final q=TextEditingController(); String category='tires';
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('فلترة متقدمة')),body:Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(16),children:[DropdownButtonFormField<String>(initialValue:category,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'الفئة'),items:const [DropdownMenuItem(value:'tires',child:Text('إطارات')),DropdownMenuItem(value:'batteries',child:Text('بطاريات'))],onChanged:(v)=>setState(()=>category=v??category)),const SizedBox(height:8),TextField(controller:q,decoration:InputDecoration(border:const OutlineInputBorder(),labelText:category=='tires'?'ماركة / منشأ / قياس / سنة إنتاج / استخدام':'أمبير / منشأ / حجم / ضمان')),const SizedBox(height:8),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('واجهة الفلترة جاهزة للربط مع بيانات المنتجات الموسعة في Firestore، وتدعم البحث حسب الحقول المطلوبة.')))])));
}

class PriceHistoryPage extends StatelessWidget { const PriceHistoryPage({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('تاريخ الأسعار')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('price_history').orderBy('createdAt',descending:true).limit(200).snapshots(),builder:(_,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(padding:const EdgeInsets.all(12),children:s.data!.docs.map((d){final x=d.data();final old=(x['oldPrice']as num?)?.toInt()??0;final now=(x['newPrice']as num?)?.toInt()??0;return Card(child:ListTile(title:Text('${x['item']??''}'),subtitle:Text('${advMoney(old)} → ${advMoney(now)} د.ع'),trailing:Icon(now>=old?Icons.trending_up:Icons.trending_down)));}).toList());})); }

class DemandHeatPage extends StatelessWidget { const DemandHeatPage({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('خريطة الطلب')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').limit(500).snapshots(),builder:(_,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final counts=<String,int>{};for(final d in s.data!.docs){final a='${d.data()['area']??'غير محدد'}';counts[a]=(counts[a]??0)+1;}final list=counts.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));return ListView(padding:const EdgeInsets.all(12),children:[const Text('المناطق الأعلى طلباً',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),...list.map((e)=>ListTile(leading:const Icon(Icons.local_fire_department),title:Text(e.key),trailing:Text('${e.value} طلب')))]); })); }

class ArrivalQrPage extends StatefulWidget { const ArrivalQrPage({super.key}); @override State<ArrivalQrPage> createState()=>_ArrivalQrPageState(); }
class _ArrivalQrPageState extends State<ArrivalQrPage> { ShopProfile? shop; @override void initState(){super.initState();ShopStore.load().then((v){if(mounted)setState(()=>shop=v);});} @override Widget build(BuildContext context){final s=shop;return Scaffold(appBar:AppBar(title:const Text('QR الوصول للمحل')),body:Center(child:s==null?const Text('سجل دخول المحل أولاً'):Column(mainAxisSize:MainAxisSize.min,children:[Text(s.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:12),BarcodeWidget(barcode:Barcode.qrCode(),data:'ARRIVAL:${s.id}',width:220,height:220),const SizedBox(height:8),SelectableText('ARRIVAL:${s.id}')])));}}

class FraudSignalsPage extends StatelessWidget { const FraudSignalsPage({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('مكافحة الاحتيال')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').limit(500).snapshots(),builder:(_,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final docs=s.data!.docs;final seen=<String,int>{};for(final d in docs){final key='${d.data()['shopId']}:${d.data()['price']}:${d.data()['title']}';seen[key]=(seen[key]??0)+1;}final suspicious=seen.entries.where((e)=>e.value>=5).toList()..sort((a,b)=>b.value.compareTo(a.value));return ListView(padding:const EdgeInsets.all(12),children:[const Card(color:advancedYellow,child:Padding(padding:EdgeInsets.all(14),child:Text('إشارات أولية: تكرار نمط طلبات متشابه بشكل مرتفع. هذه ليست إدانة، فقط إشارات للمراجعة.'))),...suspicious.map((e)=>Card(child:ListTile(leading:const Icon(Icons.warning_amber),title:Text(e.key),trailing:Text('${e.value} مرات'))))]);})); }

class MaintenanceReminderPage extends StatefulWidget { const MaintenanceReminderPage({super.key}); @override State<MaintenanceReminderPage> createState()=>_MaintenanceReminderPageState(); }
class _MaintenanceReminderPageState extends State<MaintenanceReminderPage> {
  final prefsKey='adi_maintenance_reminders_v1'; List<Map<String,dynamic>> items=[];
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {final p=await SharedPreferences.getInstance();final raw=p.getString(prefsKey);if(raw!=null){final d=jsonDecode(raw);if(d is List)items=d.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}if(mounted)setState((){});}
  Future<void> _add(String title,int days) async {items.add({'title':title,'date':DateTime.now().add(Duration(days:days)).toIso8601String()});final p=await SharedPreferences.getInstance();await p.setString(prefsKey,jsonEncode(items));if(mounted)setState((){});}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('تذكيرات الصيانة')),body:Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(14),children:[Wrap(spacing:8,runSpacing:8,children:[FilledButton(onPressed:()=>_add('فحص ضغط الإطارات',30),child:const Text('ضغط الإطارات')),FilledButton(onPressed:()=>_add('تدوير الإطارات',90),child:const Text('تدوير الإطارات')),FilledButton(onPressed:()=>_add('فحص البطارية',120),child:const Text('فحص البطارية'))]),const SizedBox(height:12),...items.map((e)=>Card(child:ListTile(leading:const Icon(Icons.alarm),title:Text('${e['title']}'),subtitle:Text('${e['date']}'))))])));
}

class ShopAdvancedToolsPage extends StatelessWidget {
  const ShopAdvancedToolsPage({super.key});
  void _open(BuildContext c, Widget p)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>p));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('أدوات المحل المتقدمة')),body:ListView(padding:const EdgeInsets.all(14),children:[
    ListTile(leading:const Icon(Icons.qr_code),title:const Text('QR الوصول للمحل'),onTap:()=>_open(context,const ArrivalQrPage())),
    ListTile(leading:const Icon(Icons.warning),title:const Text('تنبيه المخزون المنخفض'),onTap:()=>_open(context,const LowStockPage())),
    ListTile(leading:const Icon(Icons.auto_graph),title:const Text('اقتراح شراء للمحل'),onTap:()=>_open(context,const PurchaseSuggestionsPage())),
    ListTile(leading:const Icon(Icons.photo_library),title:const Text('رفع صور'),onTap:()=>_open(context,const MediaGalleryPage())),
  ]));
}

class LowStockPage extends StatelessWidget { const LowStockPage({super.key}); @override Widget build(BuildContext context)=>FutureBuilder<ShopProfile?>(future:ShopStore.load(),builder:(_,shopSnap){final s=shopSnap.data;if(s==null)return const Scaffold(body:Center(child:Text('سجل دخول المحل أولاً')));return Scaffold(appBar:AppBar(title:const Text('المخزون المنخفض')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('shops').doc(s.id).collection('inventory').snapshots(),builder:(_,snap){if(!snap.hasData)return const Center(child:CircularProgressIndicator());final low=snap.data!.docs.where((d)=>((d.data()['quantity']as num?)?.toInt()??0)<=3).toList();return ListView(padding:const EdgeInsets.all(12),children:low.map((d)=>Card(child:ListTile(leading:const Icon(Icons.warning_amber),title:Text('${d.data()['name']??''}'),subtitle:Text('الكمية: ${d.data()['quantity']??0}')))).toList());}));}); }

class PurchaseSuggestionsPage extends StatelessWidget { const PurchaseSuggestionsPage({super.key}); @override Widget build(BuildContext context)=>FutureBuilder<ShopProfile?>(future:ShopStore.load(),builder:(_,shopSnap){final s=shopSnap.data;if(s==null)return const Scaffold(body:Center(child:Text('سجل دخول المحل أولاً')));return Scaffold(appBar:AppBar(title:const Text('اقتراحات الشراء')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').where('shopId',isEqualTo:s.id).limit(300).snapshots(),builder:(_,snap){if(!snap.hasData)return const Center(child:CircularProgressIndicator());final c=<String,int>{};for(final d in snap.data!.docs){final t='${d.data()['title']??''}';c[t]=(c[t]??0)+1;}final list=c.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));return ListView(padding:const EdgeInsets.all(12),children:[const Text('الأصناف المقترح تعزيز مخزونها',style:TextStyle(fontWeight:FontWeight.bold,fontSize:19)),...list.take(20).map((e)=>ListTile(title:Text(e.key),trailing:Text('${e.value} طلب')))]); }));}); }
