import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'marketplace_rules.dart';
import 'operations_features.dart';

class SettlementPaymentService {
  static Future<bool> markPaid(DocumentReference<Map<String, dynamic>> ref) async {
    final db = ref.firestore;
    final changed = await db.runTransaction<bool>((tx) async {
      final data = (await tx.get(ref)).data();
      if (data == null) throw StateError('كشف التسوية غير موجود');
      if (data['status'] == 'paid') return false;
      if (data['status'] != 'pending') throw StateError('الكشف غير جاهز للدفع');
      final codes = (data['orderCodes'] as List?)?.map((e) => '$e').toSet() ?? <String>{};
      if (codes.isEmpty || codes.length > 450) {
        throw StateError('الكشف فارغ أو يتجاوز 450 طلب');
      }
      final orders = <String, Map<String, dynamic>>{};
      for (final code in codes) {
        final value = (await tx.get(db.collection('orders').doc(code))).data();
        if (value != null) orders[code] = value;
      }
      validateSettlementOrders(ref.id, data, orders);
      tx.update(ref, {
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      for (final code in codes) {
        tx.update(db.collection('orders').doc(code), {'settlementStatus': 'paid'});
      }
      return true;
    });
    if (changed) {
      await AuditLogService.record(
        action: 'settlement_paid', targetType: 'settlement', targetId: ref.id,
      );
    }
    return changed;
  }
}

class SettlementPaidButton extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> reference;
  const SettlementPaidButton({super.key, required this.reference});
  @override
  State<SettlementPaidButton> createState() => _SettlementPaidButtonState();
}

class _SettlementPaidButtonState extends State<SettlementPaidButton> {
  bool busy = false;
  Future<void> _pay() async {
    if (busy) return;
    setState(() => busy = true);
    // Keep the messenger: the pending row may disappear after the transaction.
    final messenger = ScaffoldMessenger.of(context);
    try {
      final changed = await SettlementPaymentService.markPaid(widget.reference);
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(changed
            ? 'تم التحقق من الكشف وتسجيل الدفع' : 'هذا الكشف مدفوع مسبقاً')));
      }
    } catch (e) {
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(
            'تعذر تسجيل الدفع: ${e.toString().replaceFirst('Bad state: ', '')}')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : _pay,
    child: Text(busy ? 'جاري التحقق...' : 'تم الدفع'),
  );
}
