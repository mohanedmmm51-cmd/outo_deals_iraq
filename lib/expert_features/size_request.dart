part of '../expert_features.dart';

class RequestSizePage extends StatefulWidget {
  const RequestSizePage({super.key});

  @override
  State<RequestSizePage> createState() => _RequestSizePageState();
}

class _RequestSizePageState extends State<RequestSizePage> {
  static const _storageKey = 'pending_tire_size_requests';
  final _formKey = GlobalKey<FormState>();
  final _size = TextEditingController();
  final _brand = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _size.dispose();
    _brand.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final request = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'size': _size.text.trim(),
      'brand': _brand.text.trim(),
      'notes': _notes.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_storageKey) ?? <String>[];
      existing.add(jsonEncode(request));
      await prefs.setStringList(_storageKey, existing);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تم إرسال طلب القياس'),
          content: const Text(
            'تم حفظ طلبك. عند ربط قاعدة بيانات المحلات راح يظهر الطلب لأصحاب المحلات مباشرة بدون رقم هاتف الزبون.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ الطلب. حاول مرة ثانية.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب قياس')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.straighten, size: 78, color: Color(0xff111111)),
              const SizedBox(height: 10),
              const Text(
                'اطلب قياس إطار غير موجود',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'دخل القياس، وإذا تريد أضف الماركة أو ملاحظة. ما نطلب رقم هاتفك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _size,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'قياس الإطار',
                  hintText: 'مثال: 225/45/17',
                  prefixIcon: Icon(Icons.tire_repair),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب قياس الإطار'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brand,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'الماركة أو النوع (اختياري)',
                  hintText: 'مثال: هانكوك أو صيني',
                  prefixIcon: Icon(Icons.sell_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  hintText: 'أي تفاصيل إضافية عن الطلب',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.campaign_outlined),
                label: const Text('إرسال الطلب للمحلات'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff111111),
                  foregroundColor: yellow,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
