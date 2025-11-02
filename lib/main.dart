import 'package:app_music/ui/home/home.dart';
import 'package:flutter/material.dart';

import 'services/account_controller.dart';
import 'services/app_settings_controller.dart';
import 'services/library_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait(<Future<void>>[
    AppSettingsController.instance.ensureInitialized(),
    LibraryController.instance.ensureInitialized(),
    AccountController.instance.ensureInitialized(),
  ]);
  runApp(const MusicApp());
}

