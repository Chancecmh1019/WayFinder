import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wayfinder/app.dart';
import 'package:wayfinder/data/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 設定螢幕方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 初始化 Hive 本地儲存
  await HiveService.initialize();

  runApp(
    const ProviderScope(
      child: WayFinderApp(),
    ),
  );
}
