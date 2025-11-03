import 'package:flutter/material.dart';
import '../../data/model/artist.dart';
import '../../data/model/song.dart';
import '../../data/repository/repository.dart';
import '../now_playing/audio_player_manager.dart';
import '../now_playing/playing.dart';

class ArtistDetailPage extends StatefulWidget {
  final Artist artist;
  const ArtistDetailPage({super.key, required this.artist});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  final repo = DefaultRepository();
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _loadSongs();
  }

  Future<List<Song>> _loadSongs() async {
    try {
      final songs = await repo.getSongsByArtistId(widget.artist.id);
      if (songs.isNotEmpty) return songs;
    } catch (_) {}
    final all = await repo.getSongs() ?? [];
    final key = widget.artist.name.trim().toLowerCase();
    return all.where((s) => s.artist.toLowerCase().contains(key)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final artist = widget.artist;
    return Scaffold(
      appBar: AppBar(title: Text(artist.name)),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return const Center(child: Text("Chưa có bài hát của ca sĩ này."));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _ArtistHeader(artist: artist, total: songs.length),
              const Divider(),
              ...songs.map(
                    (song) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.music_note),
                    ),
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.album ?? ''),
                  onTap: () async {
                    final manager = AudioPlayerManager();
                    if (manager.interactionsLocked) {
                      return;
                    }
                    if (manager.isNowPlayingOpen) {
                      return;
                    }
                    final success = await manager.playSongs(
                      songs,
                      startSong: song,
                    );
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không thể phát bài hát này.'),
                        ),
                      );
                      return;
                    }
                    if (!Navigator.of(context).mounted) return;
                    manager.setNowPlayingOpen(true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NowPlaying(
                          playingSong: manager.currentSong ?? song,
                          songs: manager.playlist,
                        ),
                      ),
                    ).whenComplete(() {
                      manager.setNowPlayingOpen(false);
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ArtistHeader extends StatelessWidget {
  final Artist artist;
  final int total;
  const _ArtistHeader({required this.artist, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(artist.image),
            onBackgroundImageError: (_, __) {},
            child: artist.image.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artist.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('$total bài hát',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
