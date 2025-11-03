
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/model/song.dart';
import '../../services/app_settings_controller.dart';
import '../../services/library_controller.dart';

class AudioPlayerManager {
  AudioPlayerManager._internal() {
    durationState = Rx.combineLatest3<Duration, Duration, Duration?, DurationState>(
      player.positionStream,
      player.bufferedPositionStream,
      player.durationStream,
      (position, buffered, total) => DurationState(
        progress: position,
        buffered: buffered,
        total: total,
      ),
    ).asBroadcastStream();
    _sequenceSub = player.sequenceStateStream.listen(_handleSequenceChanged);
  }

  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  final AudioPlayer player = AudioPlayer();
  late final Stream<DurationState> durationState;
  StreamSubscription<SequenceState?>? _sequenceSub;
  ConcatenatingAudioSource? _audioSource;

  static final ValueNotifier<Song?> currentSongNotifier = ValueNotifier(null);

  Song? _currentSong;
  List<Song> _playlist = <Song>[];

  Song? get currentSong => _currentSong;
  List<Song> get playlist => List.unmodifiable(_playlist);
  bool queueMatches(List<Song> songs) => _hasSamePlaylist(songs);

  Future<bool> playSongs(
    List<Song> songs, {
    required Song startSong,
  }) async {
    if (songs.isEmpty) return false;
    final startIndex = songs.indexWhere((s) => s.id == startSong.id);
    if (startIndex == -1) return false;

    final needsNewPlaylist = !_hasSamePlaylist(songs);

    try {
      if (needsNewPlaylist || _audioSource == null) {
        _playlist = List<Song>.from(songs);
        _audioSource = ConcatenatingAudioSource(
          children: _playlist
              .map((song) => AudioSource.uri(Uri.parse(song.source)))
              .toList(),
        );
        await player.setAudioSource(
          _audioSource!,
          initialIndex: startIndex,
          initialPosition: Duration.zero,
        );
      } else {
        await player.seek(Duration.zero, index: startIndex);
      }

      await player.setLoopMode(_loopModeFromSettings());
      await player.setShuffleModeEnabled(false);
      await player.play();

      _updateCurrentSong(startIndex);
      await LibraryController.instance.logRecentlyPlayed(_currentSong!);
      return true;
    } on PlayerException catch (error, stackTrace) {
      debugPrint('Audio error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } on PlayerInterruptedException catch (error) {
      debugPrint('Playback interrupted: $error');
    } catch (error, stackTrace) {
      debugPrint('Unexpected audio error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return false;
  }

  Future<void> updateLoopMode(DefaultLoopMode mode) async {
    await player.setLoopMode(_loopModeFromSettings(modeOverride: mode));
  }

  Future<void> stop() async {
    await player.stop();
    _currentSong = null;
    currentSongNotifier.value = null;
  }

  void _handleSequenceChanged(SequenceState? state) {
    final index = state?.currentIndex;
    if (index == null || _playlist.isEmpty) return;
    if (index < 0 || index >= _playlist.length) return;
    _updateCurrentSong(index, logHistory: true);
  }

  void _updateCurrentSong(int index, {bool logHistory = false}) {
    if (_playlist.isEmpty || index < 0 || index >= _playlist.length) return;
    final nextSong = _playlist[index];
    if (_currentSong?.id == nextSong.id) return;
    _currentSong = nextSong;
    currentSongNotifier.value = nextSong;
    if (logHistory) {
      unawaited(LibraryController.instance.logRecentlyPlayed(nextSong));
    }
  }

  bool _hasSamePlaylist(List<Song> songs) {
    if (_playlist.length != songs.length) return false;
    for (var i = 0; i < songs.length; i++) {
      if (_playlist[i].id != songs[i].id) return false;
    }
    return true;
  }

  LoopMode _loopModeFromSettings({DefaultLoopMode? modeOverride}) {
    final mode = modeOverride ?? AppSettingsController.instance.defaultLoopMode;
    switch (mode) {
      case DefaultLoopMode.one:
        return LoopMode.one;
      case DefaultLoopMode.all:
        return LoopMode.all;
      case DefaultLoopMode.off:
        return LoopMode.off;
    }
  }

  void dispose() {
    unawaited(_sequenceSub?.cancel());
    player.dispose();
    currentSongNotifier.value = null;
  }
}

class DurationState {
  const DurationState({
    required this.progress,
    required this.buffered,
    required this.total,
  });

  final Duration progress;
  final Duration buffered;
  final Duration? total;
}
