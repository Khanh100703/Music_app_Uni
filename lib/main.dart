import 'package:app_music/ui/home/home.dart';
import 'package:flutter/material.dart';

import 'data/repository/repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await init ngắn gọn, tránh chờ vô hạn
  runApp(MusicApp());
}


