// ── lib/main.dart ──────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/netwok/service_locator.dart';
import 'core/sync/sync_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(const MovieMatchApp());
}
