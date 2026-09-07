part of '../advanced_features.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final code = TextEditingController();
  bool busy = false;
  String? result;
  bool valid = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final value = code.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9_-]{3,30}$').hasMatch(value)) {
      setState(() {
        valid = false;
        result = 'اكتب كود كوبون صحيح';
      });
      return;
    }

    setState(() {
      busy = true;
      result = null;
    });
    try {
      final document = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(value)
          .get();
      final data = document.data();
      if (data == null || data['active'] != true) {
        if (mounted) {
          setState(() {
            valid = false;
            result = 'الكوبون غير فعال';
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          valid = true;
          result =
              'الكوبون فعال • الخصم ${data['discount'] ?? 0} د.ع'
              '${'${data['shopName'] ?? ''}'.trim().isEmpty ? '' : '\n${data['shopName']}'}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          valid = false;
          result = 'الكوبون غير فعال أو تعذر التحقق منه';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كوبونات الخصم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: code,
              textCapitalization: TextCapitalization.characters,
              textDirection: TextDirection.ltr,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'كود الخصم',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onSubmitted: busy ? null : (_) => _check(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : _check,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.confirmation_number),
              label: Text(busy ? 'جاري التحقق...' : 'فحص الكوبون'),
            ),
            if (result != null)
              Card(
                margin: const EdgeInsets.only(top: 14),
                color: valid ? const Color(0xFFDFF5E1) : null,
                child: ListTile(
                  leading: Icon(
                    valid ? Icons.check_circle : Icons.info_outline,
                    color: valid ? Colors.green : null,
                  ),
                  title: Text(
                    result!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
