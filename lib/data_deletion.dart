import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataDeletionRequestPage extends StatefulWidget {
  const DataDeletionRequestPage({super.key});

  @override
  State<DataDeletionRequestPage> createState() =>
      _DataDeletionRequestPageState();
}

class _DataDeletionRequestPageState extends State<DataDeletionRequestPage> {
  bool confirmed = false;
  bool busy = false;
  bool sent = false;
  String? error;

  Future<void> _submit() async {
    if (!confirmed || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = (await FirebaseAuth.instance.signInAnonymously()).user;
      }
      if (user == null) throw StateError('deletion-auth-failed');
      await FirebaseFirestore.instance
          .collection('deletion_requests')
          .doc(user.uid)
          .set({
        'userUid': user.uid,
        'email': user.email ?? '',
        'status': 'pending',
        'source': 'app',
        'requestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) setState(() => sent = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'تعذر إرسال الطلب. تأكد من الإنترنت وحاول مرة ثانية.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('حذف الحساب والبيانات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(Icons.delete_forever_outlined, size: 72),
            const SizedBox(height: 12),
            const Text(
              'طلب حذف نهائي',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'بعد التحقق، نحذف الحساب والبيانات المرتبطة به خلال 30 يوماً. قد نحتفظ بسجلات محدودة للطلبات والتسويات إذا كانت مطلوبة للمحاسبة أو منع الاحتيال أو الالتزام القانوني.',
                  style: TextStyle(height: 1.5),
                ),
              ),
            ),
            if (user == null || user.isAnonymous)
              const Card(
                color: Color(0xFFFFF4B8),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'إذا تريد حذف حساب محل، سجّل دخول حساب المحل أولاً ثم ارجع لهذه الصفحة. الطلب الحالي يخص بيانات المستخدم الموجودة على هذا الجهاز.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ),
            CheckboxListTile(
              value: confirmed,
              onChanged: sent ? null : (value) {
                setState(() => confirmed = value ?? false);
              },
              title: const Text(
                'أفهم أن الحذف نهائي وقد أفقد الوصول إلى الحساب وبياناته.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (sent)
              const Card(
                color: Color(0xFFDFF5E1),
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('تم استلام طلب الحذف'),
                  subtitle: Text('راح تتم مراجعته وتنفيذه خلال 30 يوماً.'),
                ),
              )
            else
              FilledButton.icon(
                onPressed: confirmed && !busy ? _submit : null,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: const Text('إرسال طلب الحذف'),
              ),
          ],
        ),
      ),
    );
  }
}

class AdminDeletionRequestsPage extends StatelessWidget {
  const AdminDeletionRequestsPage({super.key});

  DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse('$value') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _completeRequest(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد إكمال الحذف'),
        content: const Text(
          'هل حذفت الحساب وكل بياناته المرتبطة من Firebase؟ بعد التأكيد ينحذف سجل الطلب من قائمة الانتظار.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('نعم، تم الحذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) await reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات حذف البيانات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('deletion_requests')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('تعذر تحميل طلبات الحذف'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final requests = snap.data!.docs.toList()
              ..sort(
                (a, b) => _date(b.data()['requestedAt'])
                    .compareTo(_date(a.data()['requestedAt'])),
              );
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Card(
                  color: Color(0xFFFFF4B8),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'احذف المستخدم وبياناته المرتبطة من Firebase بعد التحقق، وبعد إكمال الحذف فقط اضغط «تمت المعالجة».',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ),
                if (requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'ماكو طلبات حذف حالياً',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ...requests.map((request) {
                  final data = request.data();
                  final email = '${data['email'] ?? ''}'.trim();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.isEmpty ? 'مستخدم بدون بريد' : email,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SelectableText('UID: ${request.id}'),
                          Text('المصدر: ${data['source'] == 'web' ? 'الموقع' : 'التطبيق'}'),
                          const Text('الحالة: قيد المعالجة'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: request.id),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم نسخ UID')),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('نسخ UID'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _completeRequest(
                                    context,
                                    request.reference,
                                  ),
                                  child: const Text('تمت المعالجة'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
