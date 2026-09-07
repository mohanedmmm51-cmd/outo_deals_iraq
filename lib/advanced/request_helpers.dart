part of '../advanced_features.dart';

Future<User> _ensureAdvancedCustomer() async {
  var user = FirebaseAuth.instance.currentUser;
  user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
  if (user == null) throw StateError('تعذر تثبيت هوية المستخدم');
  return user;
}

DateTime _advancedDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String _appointmentDate(DateTime value) {
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}/${value.month}/${value.day} - ${value.hour}:$minute';
}

String _appointmentStatus(String value) {
  switch (value) {
    case 'accepted':
      return 'مقبول';
    case 'completed':
      return 'مكتمل';
    case 'rejected':
      return 'مرفوض';
    case 'cancelled':
      return 'ملغي';
    default:
      return 'بانتظار موافقة المحل';
  }
}
