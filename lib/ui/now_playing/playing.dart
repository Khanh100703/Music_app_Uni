import 'dart:async';
import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/model/song.dart';
import '../../services/library_controller.dart';
import '../library/add_to_playlist_sheet.dart';
import 'audio_player_manager.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key, required this.playingSong, required this.songs});

  final Song playingSong;
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return NowPlayingPage(songs: songs, playingSong: playingSong);
  }
}

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({
    super.key,
    required this.songs,
    required this.playingSong,
  });

  final Song playingSong;
  final List<Song> songs;

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimationController;
  late AudioPlayerManager _audioPlayerManager;
  late int _selectedItemIndex;
  late Song _song;
  bool _isShuffle = false;
  late LoopMode _loopMode;
  final LibraryController _libraryController = LibraryController.instance;
  StreamSubscription<int?>? _indexSubscription;

  @override
  void initState() {
    super.initState();
    _song = widget.playingSong;
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _audioPlayerManager = AudioPlayerManager();
    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
    _loopMode = _audioPlayerManager.player.loopMode;
    _listenToIndexChanges();
    _initialisePlayback();
  }

  void _initialisePlayback() {
    Future.microtask(() async {
      final sameQueue = _audioPlayerManager.queueMatches(widget.songs);
      final sameSong = _audioPlayerManager.currentSong?.id == _song.id;
      var success = true;
      if (!(sameQueue && sameSong)) {
        success = await _audioPlayerManager.playSongs(
          widget.songs,
          startSong: _song,
        );
      }
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Không thể phát bài hát này.')),
        );
        Navigator.of(context).maybePop();
        return;
      }
      if (_audioPlayerManager.player.playing) {
        _playRotationAnimation();
      }
      if (mounted) {
        setState(() {
          _loopMode = _audioPlayerManager.player.loopMode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWith = MediaQuery.of(context).size.width;
    const delta = 64;
    final radius = (screenWith - delta) / 2;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Now Playing'),
        trailing: IconButton(
          onPressed: _showAddToPlaylist,
          icon: const Icon(Icons.more_horiz),
        ),
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_song.album),
              const SizedBox(height: 16),
              Text("_ ___ _"),
              const SizedBox(height: 16),
              RotationTransition(
                turns: Tween(
                  begin: 0.0,
                  end: 1.0,
                ).animate(_imageAnimationController),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: FadeInImage.assetNetwork(
                    placeholder: "assets/img.png",
                    image: _song.image,
                    width: screenWith - delta,
                    height: screenWith - delta,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        "assets/img.png",
                        width: screenWith - delta,
                        height: screenWith - delta,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 64, bottom: 16),
                child: SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        onPressed: _showAddToPlaylist,
                        icon: const Icon(Icons.queue_music),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Column(
                        children: [
                          Text(
                            _song.title,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.color,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _song.artist,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.color,
                                ),
                          ),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: _libraryController,
                        builder: (context, _) {
                          final isFavorite =
                              _libraryController.isFavorite(_song.id);
                          return IconButton(
                            onPressed: _toggleFavorite,
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            color: isFavorite
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 32,
                  bottom: 16,
                  left: 24,
                  right: 24,
                ),
                child: _progressBar(),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 0,
                  bottom: 16,
                  left: 24,
                  right: 24,
                ),
                child: _mediaButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    unawaited(_indexSubscription?.cancel());
    super.dispose();
  }

  void _listenToIndexChanges() {
    _indexSubscription?.cancel();
    _indexSubscription =
        _audioPlayerManager.player.currentIndexStream.listen((index) {
      if (index == null) return;
      final queue = _audioPlayerManager.playlist;
      if (queue.isEmpty || index < 0 || index >= queue.length) return;
      final nextSong = queue[index];
      if (mounted) {
        setState(() {
          _selectedItemIndex = index;
          _song = nextSong;
        });
        if (_audioPlayerManager.player.playing) {
          _playRotationAnimation();
        }
      }
    });
  }

  Widget _mediaButton() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MediaButtonControl(
            function: _setShuffle,
            icon: Icons.shuffle,
            color: _getShuffleColor(),
            size: 24,
          ),
          MediaButtonControl(
            function: () {
              _setPrevSong();
            },
            icon: Icons.skip_previous,
            color: Colors.deepPurple,
            size: 36,
          ),
          _playButton(),
          MediaButtonControl(
            function: () {
              _setNextSong();
            },
            icon: Icons.skip_next,
            color: Colors.deepPurple,
            size: 36,
          ),
          MediaButtonControl(
            function: _setupRepeatOption,
            icon: _repeatingIcon(),
            color: _getRepeatIconColor(),
            size: 24,
          ),
        ],
      ),
    );
  }

  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          total: total,
          buffered: buffered,
          onSeek: _audioPlayerManager.player.seek,
          barHeight: 5.0,
          barCapShape: BarCapShape.round,
          baseBarColor: Colors.grey.withOpacity(0.3),
          progressBarColor: Colors.green,
          bufferedBarColor: Colors.grey.withOpacity(0.3),
          thumbColor: Colors.deepPurple,
          thumbGlowColor: Colors.grey.withOpacity(0.3),
          thumbRadius: 5.0,
        );
      },
    );
  }

  StreamBuilder<PlayerState> _playButton() {
    return StreamBuilder(
      stream: _audioPlayerManager.player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          _pauseRotationAnimation();
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: 48,
            height: 48,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.play();
            },
            icon: Icons.play_arrow,
            color: null,
            size: 48,
          );
        } else if (processingState != ProcessingState.completed) {
          _playRotationAnimation();
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.pause();
              _pauseRotationAnimation();
            },
            icon: Icons.pause,
            color: null,
            size: 48,
          );
        } else {
          if (processingState == ProcessingState.completed) {
            _stopRotationAnimation();
            _resetRotationAnimation();
          }
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.seek(Duration.zero);
              _resetRotationAnimation();
              _playRotationAnimation();
            },
            icon: Icons.replay,
            color: null,
            size: 48,
          );
        }
      },
    );
  }

  void _setShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
    });
    _audioPlayerManager.player.setShuffleModeEnabled(_isShuffle);
    if (_isShuffle) {
      _audioPlayerManager.player.shuffle();
    }
  }

  Color? _getShuffleColor() {
    return _isShuffle ? Colors.deepPurple : Colors.grey;
  }

  Future<void> _setNextSong() async {
    if (_isShuffle) {
      final queue = _audioPlayerManager.playlist;
      if (queue.isEmpty) return;
      final randomIndex = Random().nextInt(queue.length);
      await _audioPlayerManager.playSongs(queue, startSong: queue[randomIndex]);
      return;
    }
    if (_audioPlayerManager.player.hasNext) {
      await _audioPlayerManager.player.seekToNext();
      await _audioPlayerManager.player.play();
    } else if (_loopMode == LoopMode.all &&
        _audioPlayerManager.playlist.isNotEmpty) {
      await _audioPlayerManager.player.seek(
        Duration.zero,
        index: 0,
      );
      await _audioPlayerManager.player.play();
    }
  }

  Future<void> _setPrevSong() async {
    if (_isShuffle) {
      final queue = _audioPlayerManager.playlist;
      if (queue.isEmpty) return;
      final randomIndex = Random().nextInt(queue.length);
      await _audioPlayerManager.playSongs(queue, startSong: queue[randomIndex]);
      return;
    }
    final currentPosition = _audioPlayerManager.player.position;
    if (currentPosition > const Duration(seconds: 3)) {
      await _audioPlayerManager.player.seek(Duration.zero);
      return;
    }
    if (_audioPlayerManager.player.hasPrevious) {
      await _audioPlayerManager.player.seekToPrevious();
      await _audioPlayerManager.player.play();
    } else if (_loopMode == LoopMode.all &&
        _audioPlayerManager.playlist.isNotEmpty) {
      final lastIndex = _audioPlayerManager.playlist.length - 1;
      await _audioPlayerManager.player.seek(
        Duration.zero,
        index: lastIndex,
      );
      await _audioPlayerManager.player.play();
    }
  }

  void _setupRepeatOption() {
    setState(() {
      switch (_loopMode) {
        case LoopMode.off:
          _loopMode = LoopMode.one;
          break;
        case LoopMode.one:
          _loopMode = LoopMode.all;
          break;
        case LoopMode.all:
          _loopMode = LoopMode.off;
          break;
      }
      _audioPlayerManager.player.setLoopMode(_loopMode);
    });
  }

  IconData _repeatingIcon(){
    return switch(_loopMode){
      LoopMode.one => Icons.repeat_one,
      LoopMode.all => Icons.repeat_on,
      _ => Icons.repeat,
    };
  }

  Color? _getRepeatIconColor(){
    return _loopMode == LoopMode.off
        ? Colors.grey
        : Colors.deepPurple;
  }

  void _showAddToPlaylist() {
    showModalBottomSheet<String>(
      context: context,
      builder: (_) => AddToPlaylistSheet(song: _song),
    ).then((value) {
      if (!mounted || value == null || value.isEmpty) return;
      _showSnackBar(value);
    });
  }

  void _toggleFavorite() {
    _libraryController.toggleFavorite(_song);
    final message = _libraryController.isFavorite(_song.id)
        ? 'Đã thêm vào Yêu thích'
        : 'Đã xoá khỏi Yêu thích';
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }


  void _playRotationAnimation() {
    _imageAnimationController.repeat(period: const Duration(seconds: 20));
  }

  void _pauseRotationAnimation() {
    _imageAnimationController.stop(canceled: false);
  }

  void _stopRotationAnimation() {
    _imageAnimationController.stop(canceled: false);
  }

  void _resetRotationAnimation() {
    _imageAnimationController.value = 0.0;
  }
}

class MediaButtonControl extends StatefulWidget {
  const MediaButtonControl({
    super.key,
    required this.function,
    required this.icon,
    required this.color,
    required this.size,
  });

  final void Function()? function;
  final IconData icon;
  final double? size;
  final Color? color;

  @override
  State<StatefulWidget> createState() => _MediaButtonControlState();
}

class _MediaButtonControlState extends State<MediaButtonControl> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.function,
      icon: Icon(widget.icon),
      iconSize: widget.size,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
