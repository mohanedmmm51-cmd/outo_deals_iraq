part of '../advanced_features.dart';

class AvailabilityWatchPage extends StatefulWidget {
  const AvailabilityWatchPage({super.key});

  @override
  State<AvailabilityWatchPage> createState() => _AvailabilityWatchPageState();
}

class _AvailabilityWatchPageState extends State<AvailabilityWatchPage> {
  final size = TextEditingController();
  late final Future<User> session;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    session = _ensureAdvancedCustomer();
  }

  @override
  void dispose() {
    size.dispose();
    super.dispose();
  }

  Future<void> _save(User user) async {
    final value = size.text.trim();
    if (value.isEmpty || saving) {
      if (value.isEmpty) setState(() => error = 'اكتب القياس المطلوب');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });
    try {
      await FirebaseFirestore.instance.collection('availability_watch').add({
        'customerUid': user.uid,
        'size': value,
        'active': true,
        'status': 'watching',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      size.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التنبيه وإرساله للمحلات')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'تعذر حفظ التنبيه. تأكد من الإنترنت وحاول مجدداً.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _cancel(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    try {
      await reference.update({
        'active': false,
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إلغاء التنبيه حالياً')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنبيه توفر القياس')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<User>(
          future: session,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!userSnapshot.hasData) {
              return const Center(
                child: Text('تعذر فتح الخدمة. تأكد من الإنترنت.'),
              );
            }
            final user = userSnapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: size,
                  maxLength: 100,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'القياس المطلوب',
                    hintText: 'مثال: 205/55 R16',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: saving ? null : () => _save(user),
                  icon: saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications_active),
                  label: Text(saving ? 'جاري الحفظ...' : 'نبهني عند التوفر'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 22),
                const Text(
                  'تنبيهاتي',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _CustomerAvailabilityWatches(
                  customerUid: user.uid,
                  onCancel: _cancel,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CustomerAvailabilityWatches extends StatelessWidget {
  const _CustomerAvailabilityWatches({
    required this.customerUid,
    required this.onCancel,
  });

  final String customerUid;
  final Future<void> Function(DocumentReference<Map<String, dynamic>>) onCancel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('availability_watch')
          .where('customerUid', isEqualTo: customerUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('تعذر تحميل التنبيهات حالياً'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.toList()
          ..sort(
            (a, b) =>
                _advancedDate(b.data()['createdAt'])
                    .compareTo(_advancedDate(a.data()['createdAt'])),
          );
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('بعد ما عندك تنبيهات محفوظة'),
            ),
          );
        }
        return Column(
          children: docs
              .map(
                (document) => _AvailabilityWatchCard(
                  document: document,
                  onCancel: onCancel,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AvailabilityWatchCard extends StatelessWidget {
  const _AvailabilityWatchCard({
    required this.document,
    required this.onCancel,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final Future<void> Function(DocumentReference<Map<String, dynamic>>) onCancel;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final active = data['active'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: active ? advancedYellow : Colors.grey.shade300,
                child: Icon(
                  active ? Icons.notifications_active : Icons.notifications_off,
                  color: Colors.black,
                ),
              ),
              title: Text(
                '${data['size'] ?? ''}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(active ? 'التنبيه فعال' : 'تم إلغاء التنبيه'),
              trailing: active
                  ? TextButton(
                      onPressed: () => onCancel(document.reference),
                      child: const Text('إلغاء'),
                    )
                  : null,
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: document.reference.collection('matches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'تعذر تحميل إشعارات المحلات حالياً.',
                    style: TextStyle(color: Colors.red),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'بانتظار إشعار التوفر من المحلات.',
                    style: TextStyle(color: Colors.black54),
                  );
                }
                final matches = snapshot.data!.docs.toList()
                  ..sort(
                    (a, b) =>
                        _advancedDate(b.data()['matchedAt'])
                            .compareTo(_advancedDate(a.data()['matchedAt'])),
                  );
                return Column(
                  children: matches.map((match) {
                    final item = match.data();
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.storefront),
                      title: Text('${item['shopName'] ?? 'محل'}'),
                      subtitle: Text('${item['note'] ?? 'متوفر حالياً'}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ShopAvailabilityWatchesPage extends StatelessWidget {
  const ShopAvailabilityWatchesPage({super.key});

  Future<void> _markAvailable(
    BuildContext context,
    ShopProfile shop,
    DocumentReference<Map<String, dynamic>> watch,
  ) async {
    try {
      final currentShop = await ShopStore.cacheFromRemote(shop.id);
      if (currentShop == null || !currentShop.approved) {
        throw StateError('حساب المحل غير معتمد حالياً');
      }
      await watch.collection('matches').doc(currentShop.id).set({
        'shopId': currentShop.id,
        'shopName': currentShop.name,
        'note': 'القياس متوفر حالياً',
        'matchedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إشعار الزبون بتوفر القياس')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final message = e is StateError
            ? e.toString().replaceFirst('Bad state: ', '')
            : 'تعذر إرسال إشعار التوفر';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopProfile?>(
      future: ShopStore.loadForAuthenticatedOwner(),
      builder: (context, shopSnapshot) {
        if (shopSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final shop = shopSnapshot.data;
        if (shop == null || !shop.approved) {
          return const Scaffold(
            body: Center(child: Text('سجل دخول محل معتمد أولاً')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('طلبات تنبيه التوفر')),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('availability_watch')
                  .where('active', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('تعذر تحميل طلبات التوفر'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.toList()
                  ..sort(
                    (a, b) =>
                        _advancedDate(b.data()['createdAt'])
                            .compareTo(_advancedDate(a.data()['createdAt'])),
                  );
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('ماكو طلبات تنبيه فعالة حالياً'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final document = docs[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: advancedYellow,
                          child: Icon(Icons.straighten, color: Colors.black),
                        ),
                        title: Text(
                          '${document.data()['size'] ?? ''}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: FilledButton(
                          onPressed: () =>
                              _markAvailable(context, shop, document.reference),
                          child: const Text('متوفر عندي'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
