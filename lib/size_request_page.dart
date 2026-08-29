import 'dart:math' as math;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const _sizeRequestYellow = Color(0xFFFFD400);

class EnhancedSizeRequestPage extends StatefulWidget {
  const EnhancedSizeRequestPage({super.key});

  @override
  State<EnhancedSizeRequestPage> createState() => _EnhancedSizeRequestPageState();
}

class _EnhancedSizeRequestPageState extends State<EnhancedSizeRequestPage> {
  final type = TextEditingController(text: 'إطار');
  final size = TextEditingController();

  bool busy = false;
  String? requestCode;
  String? error;

  @override
  void dispose() {
    type.dispose();
    size.dispose();
    super.dispose();
  }

  String _createRequestCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final random = math.Random.secure().nextInt(9000) + 1000;
    return 'SIZE-${now.substring(now.length - 6)}-$random';
  }

  Future<void> _submit() async {
    final wantedType = type.text.trim();
    final wantedSize = size.text.trim();

    if (wantedSize.isEmpty) {
      setState(() => error = 'اكتب القياس المطلوب أولاً');
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    final code = _createRequestCode();

    try {
      await FirebaseFirestore.instance.collection('size_requests').doc(code).set({
        'requestCode': code,
        'type': wantedType.isEmpty ? 'إطار' : wantedType,
        'size': wantedSize,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'responses': <Map<String, dynamic>>[],
      });

      if (!mounted) return;
      setState(() {
        requestCode = code;
        busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = 'تعذر إرسال الطلب للمحلات: $e';
      });
    }
  }

  void _newRequest() {
    setState(() {
      requestCode = null;
      error = null;
      size.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(requestCode == null ? 'طلب قياس' : 'كود طلب القياس'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: requestCode == null ? _requestForm() : _ticket(),
      ),
    );
  }

  Widget _requestForm() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Icon(Icons.straighten, size: 76, color: _sizeRequestYellow),
        const SizedBox(height: 10),
        const Text(
          'ما لكيت القياس؟',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'أرسل القياس المطلوب للمحلات وبعدها احتفظ بكود الطلب.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        TextField(
          controller: type,
          decoration: const InputDecoration(
            labelText: 'النوع',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: size,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'القياس المطلوب',
            hintText: 'مثال: 205/55 R16',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _sizeRequestYellow,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: busy ? null : _submit,
          icon: const Icon(Icons.qr_code_2),
          label: Text(
            busy ? 'جاري إنشاء الطلب...' : 'إرسال وإنشاء الكود',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _ticket() {
    final code = requestCode!;
    final requestType = type.text.trim().isEmpty ? 'إطار' : type.text.trim();
    final requestSize = size.text.trim();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 72),
        const SizedBox(height: 8),
        const Text(
          'تم إرسال طلبك للمحلات',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        Card(
          color: _sizeRequestYellow,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Text('كود الطلب'),
                const SizedBox(height: 5),
                SelectableText(
                  code,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$requestType • $requestSize',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'QR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: code,
                  width: 190,
                  height: 190,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Text(
                  'الباركود',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: code,
                  height: 85,
                  drawText: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'احتفظ بالكود. يستخدم لتحديد طلبك عند توفر القياس.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _newRequest,
          icon: const Icon(Icons.add),
          label: const Text('طلب قياس جديد'),
        ),
      ],
    );
  }
}
