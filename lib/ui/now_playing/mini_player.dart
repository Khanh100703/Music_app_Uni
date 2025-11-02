import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/model/song.dart';
import '../../services/app_settings_controller.dart';
import '../library/add_to_playlist_sheet.dart';
import 'audio_player_manager.dart';
import 'playing.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppSettingsController.instance.miniPlayerEnabled) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<Song?>(
      valueListenable: AudioPlayerManager.currentSongNotifier,
      builder: (context, song, _) {
        if (song == null) return const SizedBox.shrink();
        return _MiniPlayerContent(song: song);
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  const _MiniPlayerContent({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final manager = AudioPlayerManager();
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      elevation: 8,
      child: InkWell(
        onTap: () {
          final playlist = manager.playlist ?? <Song>[song];
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => NowPlaying(
                playingSong: song,
                songs: playlist,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/img.png',
                  image: song.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) =>
                      Image.asset('assets/img.png', width: 56, height: 56),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    _MiniProgressBar(manager: manager),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.queue_music),
                tooltip: 'Thêm vào playlist',
                onPressed: () {
                  showModalBottomSheet<String>(
                    context: context,
                    builder: (_) => AddToPlaylistSheet(song: song),
                  ).then((value) {
                    if (value != null && value.isNotEmpty) {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(content: Text(value)),
                      );
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
              _MiniPlayPauseButton(manager: manager),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayPauseButton extends StatelessWidget {
  const _MiniPlayPauseButton({required this.manager});

  final AudioPlayerManager manager;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: manager.player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? false;
        final processing = state?.processingState;
        if (processing == ProcessingState.loading ||
            processing == ProcessingState.buffering) {
          return const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        return IconButton(
          iconSize: 32,
          onPressed: () {
            if (playing) {
              manager.player.pause();
            } else {
              manager.player.play();
            }
          },
          icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill),
        );
      },
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({required this.manager});

  final AudioPlayerManager manager;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DurationState>(
      stream: manager.durationState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null || state.total == null || state.total == Duration.zero) {
          return const SizedBox(height: 4);
        }
        final progress = state.progress.inMilliseconds.toDouble();
        final total = state.total!.inMilliseconds.toDouble();
        final value = total == 0 ? 0.0 : (progress / total).clamp(0.0, 1.0);
        return LinearProgressIndicator(
          value: value,
          minHeight: 4,
        );
      },
    );
  }
}
