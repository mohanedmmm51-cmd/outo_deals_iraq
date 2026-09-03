import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'support_system.dart';

export 'support_system.dart' show SupportPage;

part 'app_core/models_and_api.dart';
part 'app_core/customer_pages.dart';
part 'app_core/shop_pages.dart';
part 'app_core/home_pages.dart';
part 'app_core/catalog_pages.dart';
