part of '../operations_features.dart';

class ShopRiskPage extends StatelessWidget {
  const ShopRiskPage({super.key});

  Future<Map<String, dynamic>> _load() async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('shops').get(),
      db.collection('complaints').get(),
      db.collection('settlements').where('status', isEqualTo: 'pending').get(),
    ]);
    return {
      'shops': results[0] as QuerySnapshot<Map<String, dynamic>>,
      'complaints': results[1] as QuerySnapshot<Map<String, dynamic>>,
      'settlements': results[2] as QuerySnapshot<Map<String, dynamic>>,
    };
  }

  Future<void> _suspend(String shopId, String name) async {
    await FirebaseFirestore.instance.collection('shops').doc(shopId).set({
      'approved': false,
      'status': 'suspended',
      'suspendedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditLogService.record(action: 'shop_suspended_risk', targetType: 'shop', targetId: shopId, details: name);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مخاطر وشكاوى المحلات')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _load(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final shops = (snap.data!['shops'] as QuerySnapshot<Map<String, dynamic>>).docs;
              final complaints = (snap.data!['complaints'] as QuerySnapshot<Map<String, dynamic>>).docs;
              final settlements = (snap.data!['settlements'] as QuerySnapshot<Map<String, dynamic>>).docs;
              final now = DateTime.now();
              return ListView(
                padding: const EdgeInsets.all(12),
                children: shops.map((shop) {
                  final x = shop.data();
                  final complaintCount = complaints.where((c) => c.data()['shopId'] == shop.id && c.data()['status'] == 'open').length;
                  final overdue = settlements.any((s) {
                    if (s.data()['shopId'] != shop.id) return false;
                    final created = opDate(s.data()['createdAt']);
                    return created.millisecondsSinceEpoch > 0 && now.difference(created).inDays >= 7;
                  });
                  final risky = complaintCount >= 3 || overdue;
                  return Card(
                    color: risky ? Colors.orange.shade100 : null,
                    child: ListTile(
                      leading: Icon(risky ? Icons.warning_amber : Icons.verified_user),
                      title: Text('${x['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('شكاوى مفتوحة: $complaintCount\n${overdue ? 'تسوية متأخرة 7 أيام أو أكثر' : 'التسويات طبيعية'}'),
                      isThreeLine: true,
                      trailing: risky
                          ? FilledButton(onPressed: () => _suspend(shop.id, '${x['name'] ?? ''}'), child: const Text('تعليق'))
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      );
}
class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سجل النشاط')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('audit_logs').orderBy('createdAt', descending: true).limit(300).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              return ListView(
                padding: const EdgeInsets.all(12),
                children: snap.data!.docs.map((d) {
                  final x = d.data();
                  return Card(
                    child: ListTile(
                      title: Text('${x['action'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${x['targetType'] ?? ''}: ${x['targetId'] ?? ''}\n${x['actorEmail'] ?? ''} • ${x['details'] ?? ''}'),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      );
}
