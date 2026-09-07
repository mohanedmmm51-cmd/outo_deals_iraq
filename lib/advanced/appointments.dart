part of '../advanced_features.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  late final Future<User> session;
  String service = 'شد وبلنص';
  String? selectedShopId;
  DateTime when = DateTime.now().add(const Duration(days: 1));
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    session = _ensureAdvancedCustomer();
  }

  Future<void> _save(User user) async {
    final shopId = selectedShopId;
    if (shopId == null || shopId.isEmpty) {
      setState(() => error = 'اختار المحل أولاً');
      return;
    }
    if (!when.isAfter(DateTime.now().add(const Duration(minutes: 10)))) {
      setState(() => error = 'اختار موعد بعد الوقت الحالي');
      return;
    }
    if (when.isAfter(DateTime.now().add(const Duration(days: 90)))) {
      setState(() => error = 'اختار موعد خلال 90 يوم');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });
    try {
      final shop = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();
      final shopData = shop.data();
      if (shopData == null ||
          shopData['approved'] != true ||
          shopData['status'] == 'suspended') {
        throw StateError('المحل غير متاح للحجز حالياً');
      }
      await FirebaseFirestore.instance.collection('appointments').add({
        'customerUid': user.uid,
        'shopId': shop.id,
        'shopName': '${shopData['name'] ?? ''}',
        'service': service,
        'when': Timestamp.fromDate(when),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إرسال الحجز للمحل')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e is StateError
              ? e.toString().replaceFirst('Bad state: ', '')
              : 'تعذر إرسال الحجز. تأكد من الإنترنت وحاول مجدداً.';
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      initialDate: when,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(when),
    );
    if (time != null && mounted) {
      setState(() {
        when = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _cancelAppointment(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    try {
      await reference.update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إلغاء الحجز حالياً')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حجز موعد')),
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
                child: Text('تعذر فتح خدمة الحجز. تأكد من الإنترنت.'),
              );
            }
            final user = userSnapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('shops')
                      .where('approved', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final shops = snapshot.data!.docs
                        .where((doc) => doc.data()['status'] != 'suspended')
                        .toList();
                    final selectedExists = shops.any(
                      (doc) => doc.id == selectedShopId,
                    );
                    return DropdownButtonFormField<String>(
                      key: ValueKey(
                        selectedExists ? selectedShopId : 'shop-not-selected',
                      ),
                      initialValue: selectedExists ? selectedShopId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'المحل',
                      ),
                      items: shops
                          .map(
                            (doc) => DropdownMenuItem(
                              value: doc.id,
                              child: Text('${doc.data()['name'] ?? 'محل'}'),
                            ),
                          )
                          .toList(),
                      onChanged: shops.isEmpty
                          ? null
                          : (value) => setState(() => selectedShopId = value),
                    );
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: service,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'الخدمة',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'شد وبلنص',
                      child: Text('شد وبلنص'),
                    ),
                    DropdownMenuItem(
                      value: 'تبديل بطارية',
                      child: Text('تبديل بطارية'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => service = value ?? service);
                  },
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    title: const Text('الموعد'),
                    subtitle: Text(_appointmentDate(when)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: _pickDateTime,
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
                      : const Icon(Icons.event_available),
                  label: Text(saving ? 'جاري الإرسال...' : 'تأكيد الحجز'),
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
                  'حجوزاتي',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _CustomerAppointments(
                  customerUid: user.uid,
                  onCancel: _cancelAppointment,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CustomerAppointments extends StatelessWidget {
  const _CustomerAppointments({
    required this.customerUid,
    required this.onCancel,
  });

  final String customerUid;
  final Future<void> Function(DocumentReference<Map<String, dynamic>>) onCancel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('customerUid', isEqualTo: customerUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('تعذر تحميل الحجوزات حالياً'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.toList()
          ..sort(
            (a, b) =>
                _advancedDate(b.data()['when'])
                    .compareTo(_advancedDate(a.data()['when'])),
          );
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('بعد ما عندك حجوزات'),
            ),
          );
        }
        return Column(
          children: docs.map((document) {
            final data = document.data();
            final status = '${data['status'] ?? 'pending'}';
            final cancellable = status == 'pending' || status == 'accepted';
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text('${data['shopName'] ?? 'محل'}'),
                subtitle: Text(
                  '${data['service'] ?? ''}\n'
                  '${_appointmentDate(_advancedDate(data['when']))}\n'
                  'الحالة: ${_appointmentStatus(status)}',
                ),
                isThreeLine: true,
                trailing: cancellable
                    ? TextButton(
                        onPressed: () => onCancel(document.reference),
                        child: const Text('إلغاء'),
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class ShopAppointmentsPage extends StatelessWidget {
  const ShopAppointmentsPage({super.key});

  Future<void> _setStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    String status,
  ) async {
    try {
      await reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديث الحجز حالياً')),
        );
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
          appBar: AppBar(title: const Text('حجوزات المحل')),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('shopId', isEqualTo: shop.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('تعذر تحميل الحجوزات'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.toList()
                  ..sort(
                    (a, b) =>
                        _advancedDate(a.data()['when'])
                            .compareTo(_advancedDate(b.data()['when'])),
                  );
                if (docs.isEmpty) {
                  return const Center(child: Text('ماكو حجوزات لهذا المحل'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final document = docs[index];
                    final data = document.data();
                    final status = '${data['status'] ?? 'pending'}';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: advancedYellow,
                                child: Icon(Icons.event, color: Colors.black),
                              ),
                              title: Text('${data['service'] ?? ''}'),
                              subtitle: Text(
                                '${_appointmentDate(_advancedDate(data['when']))}\n'
                                'الحالة: ${_appointmentStatus(status)}',
                              ),
                              isThreeLine: true,
                            ),
                            if (status == 'pending')
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton(
                                    onPressed: () => _setStatus(
                                      context,
                                      document.reference,
                                      'accepted',
                                    ),
                                    child: const Text('قبول'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _setStatus(
                                      context,
                                      document.reference,
                                      'rejected',
                                    ),
                                    child: const Text('رفض'),
                                  ),
                                ],
                              )
                            else if (status == 'accepted')
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton(
                                    onPressed: () => _setStatus(
                                      context,
                                      document.reference,
                                      'completed',
                                    ),
                                    child: const Text('تمت الخدمة'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _setStatus(
                                      context,
                                      document.reference,
                                      'cancelled',
                                    ),
                                    child: const Text('إلغاء'),
                                  ),
                                ],
                              ),
                          ],
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
