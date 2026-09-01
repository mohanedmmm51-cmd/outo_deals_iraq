import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shop_store.dart';

const advancedYellow = Color(0xFFFFD400);

String advMoney(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

class LocalCustomerStore {
  static const _favorites = 'adi_favorites_v1';
  static const _points = 'adi_points_v1';
  static const _referral = 'adi_referral_v1';

  static Future<Set<String>> favorites() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_favorites) ?? const <String>[]).toSet();
  }

  static Future<void> toggleFavorite(String id) async {
    final p = await SharedPreferences.getInstance();
    final set = (p.getStringList(_favorites) ?? <String>[]).toSet();
    set.contains(id) ? set.remove(id) : set.add(id);
    await p.setStringList(_favorites, set.toList());
  }

  static Future<int> points() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_points) ?? 0;
  }

  static Future<void> addPoints(int value) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_points, (p.getInt(_points) ?? 0) + value);
  }

  static Future<String> referralCode() async {
    final p = await SharedPreferences.getInstance();
    var code = p.getString(_referral);
    if (code == null || code.isEmpty) {
      final s = DateTime.now().millisecondsSinceEpoch.toString();
      code = 'ADI-${s.substring(s.length - 6)}';
      await p.setString(_referral, code);
    }
    return code;
  }
}

part 'advanced/advanced_hub.dart';
part 'advanced/customer_services.dart';
part 'advanced/shop_tools.dart';
