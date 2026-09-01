import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'shop_store.dart';

part 'operations/order_actions.dart';
part 'operations/order_management.dart';
part 'operations/business_management.dart';
part 'operations/risk_and_audit.dart';

const operationsYellow = Color(0xFFFFD400);

String opMoney(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

DateTime opDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String orderStatusLabel(String status) {
  switch (status) {
    case 'accepted':
      return 'مقبول';
    case 'on_the_way':
      return 'الزبون بالطريق';
    case 'completed':
      return 'منفذ';
    case 'cancelled':
      return 'ملغي';
    case 'expired':
      return 'منتهي';
    default:
      return 'جديد';
  }
}
