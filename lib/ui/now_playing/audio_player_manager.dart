
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/model/song.dart';

class AudioPlayerManager {
  AudioPlayerManager._internal();
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  final player = AudioPlayer();
  Stream<DurationState>? durationState;

  static final ValueNotifier<Song?> currentSongNotifier = ValueNotifier(null);
  Song? _currentSong;
  List<Song>? _playlist;

  String songUrl = '';


  void prepare({bool isNewSong = false}) {
      durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
        player.positionStream,
        player.playbackEventStream,
            (position, playbackEvent) =>
            DurationState(
              progress: position,
              buffered: playbackEvent.bufferedPosition,
              total: playbackEvent.duration,
            )
        );
    if (isNewSong){
      player.setUrl(songUrl);
    }
  }


  void updateSongUrl(String url, {Song? song, List<Song>? playlist, bool isNewSong = false}) {
    songUrl = url;
    _currentSong = song ?? _currentSong;
    _playlist = playlist ?? _playlist;
    currentSongNotifier.value = _currentSong;
    if (isNewSong) {
      prepare();
    } else {
      prepare(isNewSong: true);
    }
  }


  Song? get currentSong => _currentSong;


  List<Song>? get playlist => _playlist;


  Future<void> stop() async {
    await player.stop();
    currentSongNotifier.value = null;
  }

  void dispose() {
    player.dispose();
    currentSongNotifier.value = null;
  }
}

class DurationState {
  const DurationState({
    required this.progress,
    required this.buffered,
    this.total,
  });

  final Duration progress;
  final Duration buffered;
  final Duration? total;
}
