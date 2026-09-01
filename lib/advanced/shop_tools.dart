part of '../advanced_features.dart';

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
