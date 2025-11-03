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
    final playlist = manager.playlist;
    final songs = playlist.isEmpty ? <Song>[song] : playlist;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 10,
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: _MiniProgressBar(manager: manager),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (manager.interactionsLocked ||
                            manager.currentSong == null) {
                          return;
                        }
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => NowPlaying(
                              playingSong: song,
                              songs: songs,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/img.png',
                              image: song.image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              imageErrorBuilder: (_, __, ___) => Image.asset(
                                  'assets/img.png',
                                  width: 56,
                                  height: 56,
                                ),
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
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                  _MiniSkipButton(
                    manager: manager,
                    forward: false,
                  ),
                  _MiniPlayPauseButton(manager: manager),
                  _MiniSkipButton(
                    manager: manager,
                    forward: true,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Đóng mini player',
                    onPressed: () async {
                      await manager.stop();
                    },
                  ),
                ],
              ),
            ),
          ],
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

class _MiniSkipButton extends StatelessWidget {
  const _MiniSkipButton({
    required this.manager,
    required this.forward,
  });

  final AudioPlayerManager manager;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final fallback = forward
        ? manager.player.hasNext
        : manager.player.hasPrevious;
    return StreamBuilder<SequenceState?>(
      stream: manager.player.sequenceStateStream,
      builder: (context, snapshot) {
        bool hasTarget = fallback;
        if (snapshot.hasData) {
          final state = snapshot.data;
          final sequence = state?.effectiveSequence;
          final index = state?.currentIndex;
          if (sequence != null && index != null) {
            hasTarget = forward
                ? index + 1 < sequence.length
                : index - 1 >= 0 && sequence.isNotEmpty;
          }
        }
        return IconButton(
          icon: Icon(forward ? Icons.skip_next : Icons.skip_previous),
          tooltip: forward ? 'Bài tiếp theo' : 'Bài trước',
          onPressed: hasTarget
              ? () async {
                  if (forward) {
                    await manager.player.seekToNext();
                  } else {
                    await manager.player.seekToPrevious();
                  }
                  await manager.player.play();
                }
              : null,
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
        final total = state?.total?.inMilliseconds.toDouble() ?? 0.0;
        final progress = state?.progress.inMilliseconds.toDouble() ?? 0.0;
        final value = total <= 0 ? null : (progress / total).clamp(0.0, 1.0);
        return LinearProgressIndicator(
          value: value,
          minHeight: 4,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
