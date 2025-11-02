import '../../data/model/song.dart';
import 'dart:async';

import '../../data/repository/repository.dart';

class MusicAppViewModel {
  StreamController<List<Song>> songStream = StreamController();

  void loadSongs() {
    final repository = DefaultRepository();
    repository.getSongs().then((value) => songStream.add(value!));
  }
}