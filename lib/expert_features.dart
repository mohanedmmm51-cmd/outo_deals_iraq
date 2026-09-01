import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_core.dart' as legacy;

part 'expert_features/expert_center.dart';
part 'expert_features/tire_advice.dart';
part 'expert_features/battery_advisor.dart';
part 'expert_features/maintenance.dart';
part 'expert_features/size_request.dart';

const yellow = Color(0xFFFFD400);

String money(int n) => n.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

Widget expertButton(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  Color color,
  VoidCallback onTap,
) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 45, color: Colors.black),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.arrow_back_ios_new, size: 18),
        ],
      ),
    ),
  );
}
