import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AppData extends ChangeNotifier {
  static final AppData shared = AppData();

  // Global Context:
  final navigatorKey = GlobalKey<NavigatorState>();

  Uuid uuid = Uuid();
}
