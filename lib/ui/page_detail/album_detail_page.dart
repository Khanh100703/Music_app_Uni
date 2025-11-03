import 'package:flutter/material.dart';
import '../../data/model/album.dart';
import '../../data/model/song.dart';
import '../../data/repository/repository.dart';
import '../now_playing/audio_player_manager.dart';
import '../now_playing/playing.dart';

class AlbumDetailPage extends StatefulWidget {
  final Album album;
  const AlbumDetailPage({super.key, required this.album});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final repo = DefaultRepository();
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _loadSongs();
  }

  Future<List<Song>> _loadSongs() async {
    try {
      final songs = await repo.getSongsByAlbumId(widget.album.id);
      if (songs.isNotEmpty) return songs;
    } catch (_) {}
    final all = await repo.getSongs() ?? [];
    final albumName = widget.album.name.trim().toLowerCase();
    return all
        .where((s) => (s.album ?? '').trim().toLowerCase() == albumName)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    return Scaffold(
      appBar: AppBar(title: Text(album.name)),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return const Center(child: Text("Chưa có bài hát trong album này."));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _AlbumHeader(album: album, total: songs.length),
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
                  subtitle: Text(song.artist),
                  onTap: () async {
                    final manager = AudioPlayerManager();
                    if (manager.interactionsLocked) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NowPlaying(
                          playingSong: manager.currentSong ?? song,
                          songs: manager.playlist,
                        ),
                      ),
                    );
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

class _AlbumHeader extends StatelessWidget {
  final Album album;
  final int total;
  const _AlbumHeader({required this.album, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              album.image,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.album, size: 56),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(album.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (album.artists.isNotEmpty)
                  Text(album.artists.join(', '),
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
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
