import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/model/song.dart';
import 'audio_player_manager.dart';
import 'playing.dart';

Future<void> showNowPlayingPage({
  required BuildContext context,
  required AudioPlayerManager manager,
  required List<Song> fallbackQueue,
  required Song fallbackSong,
}) async {
  if (manager.interactionsLocked || manager.isNowPlayingOpen) {
    return;
  }
  final queue = manager.playlist.isEmpty ? fallbackQueue : manager.playlist;
  final playing = manager.currentSong ?? fallbackSong;
  manager.setNowPlayingOpen(true);
  await Navigator.of(context)
      .push(
        CupertinoPageRoute(
          builder: (_) => NowPlaying(
            songs: queue,
            playingSong: playing,
          ),
        ),
      )
      .whenComplete(() {
    manager.setNowPlayingOpen(false);
  });
}
