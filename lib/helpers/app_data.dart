import 'package:flutter/material.dart';
import 'package:flutter_geo_hash/flutter_geo_hash.dart';
import 'package:uuid/uuid.dart';

class AppData extends ChangeNotifier {
  static final AppData shared = AppData();

  // Global Context:
  final navigatorKey = GlobalKey<NavigatorState>();

  Uuid uuid = Uuid();

  final geoHash = MyGeoHash();
}
