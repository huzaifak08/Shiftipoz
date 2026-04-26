import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/cache/init_cache.dart';
import 'package:shiftipoz/helpers/app_data.dart';
import 'package:shiftipoz/helpers/theme.dart';
import 'package:shiftipoz/providers/app_provider_container.dart';
import 'package:shiftipoz/views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Cache:
  await LocalCacheManager.initDatabase();

  await Firebase.initializeApp();

  runApp(
    ProviderScope(
      child: UncontrolledProviderScope(
        container: AppProviderContainer.instance,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shiftipoz',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppData.shared.navigatorKey,
      theme: ShiftipozTheme.lightTheme,
      darkTheme: ShiftipozTheme.darkTheme,
      home: const SplashView(),
    );
  }
}

// dart run build_runner build --delete-conflicting-outputs
