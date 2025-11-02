import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:app_music/ui/home/viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app_music/services/app_settings_controller.dart';
import 'package:app_music/ui/library/add_to_playlist_sheet.dart';
import 'package:app_music/ui/now_playing/mini_player.dart';

import '../../data/model/song.dart';
import '../../data/model/album.dart';
import '../../data/model/artist.dart';
import '../chart/chart.dart';
import '../library/library.dart';
import '../now_playing/playing.dart';
import '../page_detail/album_detail_page.dart';
import '../page_detail/artist_detail_page.dart';
import '../setting/setting.dart';
import '../user/account.dart';
import '../now_playing/audio_player_manager.dart' show AudioPlayerManager;

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final seed = settings.primaryColor;
        return MaterialApp(
          title: 'Music App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settings.themeMode,
          home: const MusicHomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageSate();
}

class _MusicHomePageSate extends State<MusicHomePage> {
  final List<Widget> _tab = [
    const HomeTab(),
    const ChartTab(),
    const LibraryTab(),
    const AccountTab(),
    const SettingTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Music App')),
      child: Stack(
        children: [
          CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'MusicChart',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle_outlined),
                  label: 'Account',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
            tabBuilder: (BuildContext context, int index) {
              return CupertinoTabView(builder: (_) => _tab[index]);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // đẩy mini lên trên thanh tab iOS
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    56, // 56 hợp với CupertinoTabBar
              ),
              child: AnimatedBuilder(
                animation: AppSettingsController.instance,
                builder: (context, _) {
                  if (!AppSettingsController.instance.miniPlayerEnabled) {
                    return const SizedBox.shrink();
                  }
                  return const MiniPlayer();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeTabPage();
  }
}

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  List<Song> song = [];
  late MusicAppViewModel _viewModel;
  List<Album> _albums = [];
  List<Artist> _artists = [];
  bool _loadingAlbums = true;
  bool _loadingArtists = true;

  @override
  void initState() {
    super.initState();
    _viewModel = MusicAppViewModel();
    _viewModel.loadSongs();
    observeData();
    _loadAlbums();
    _loadArtists();
  }

  @override
  void dispose() {
    _viewModel.songStream.close();
    super.dispose();
  }

  void observeData() {
    _viewModel.songStream.stream.listen((songList) {
      setState(() {
        song = songList;
      });
    });
  }

  Future<void> _loadAlbums() async {
    try {
      final String response = await rootBundle.loadString('assets/albums.json');
      final body = jsonDecode(response) as Map<String, dynamic>;
      final list = (body['albums'] as List)
          .map((e) => Album.fromJson(e))
          .toList();
      setState(() {
        _albums = list;
        _loadingAlbums = false;
      });
    } catch (_) {
      setState(() => _loadingAlbums = false);
    }
  }

  Future<void> _loadArtists() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/artists.json',
      ); // đảm bảo .json
      final body = jsonDecode(response) as Map<String, dynamic>;
      final list = (body['artists'] as List)
          .map((e) => Artist.fromJson(e))
          .toList();
      setState(() {
        _artists = list;
        _loadingArtists = false;
      });
    } catch (_) {
      setState(() => _loadingArtists = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final showLoadingSongs = song.isEmpty;

    return Scaffold(
      body: Stack(
        children: [
          // === PHẦN NỘI DUNG CHÍNH ===
          Padding(
            padding: const EdgeInsets.only(bottom: 68),
            // chừa chỗ cho mini player
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 100),
              children: [
                const _SectionHeader(title: 'Album'),
                SizedBox(
                  height: 140,
                  child: _loadingAlbums
                      ? const Center(child: CircularProgressIndicator())
                      : (_albums.isEmpty
                            ? const Center(child: Text('Chưa có album'))
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: _albums.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final a = _albums[i];
                                  return _AlbumCard(
                                    album: a,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AlbumDetailPage(album: a),
                                        ),
                                      );
                                    },
                                  );
                                },
                              )),
                ),

                const SizedBox(height: 12),
                const _SectionHeader(title: 'Ca sĩ'),
                SizedBox(
                  height: 140,
                  child: _loadingArtists
                      ? const Center(child: CircularProgressIndicator())
                      : (_artists.isEmpty
                            ? const Center(child: Text('Chưa có ca sĩ'))
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: _artists.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, i) {
                                  final ar = _artists[i];
                                  return _ArtistCard(
                                    artist: ar,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ArtistDetailPage(artist: ar),
                                        ),
                                      );
                                    },
                                  );
                                },
                              )),
                ),

                const SizedBox(height: 12),
                const _SectionHeader(title: 'Bài hát'),
                if (showLoadingSongs)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ListView.separated(
                    itemBuilder: (context, position) =>
                        _SongItemSection(parent: this, song: song[position]),
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.black,
                      thickness: 1,
                      indent: 24,
                      endIndent: 24,
                      height: 1,
                    ),
                    itemCount: song.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAlbum(Album album) {
    final lower = album.name.trim().toLowerCase();
    final byName = song
        .where((s) => (s.album ?? '').trim().toLowerCase() == lower)
        .toList();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => _FilteredSongsPage(title: album.name, songs: byName),
      ),
    );
  }

  void _openArtist(Artist artist) {
    final key = artist.name.trim().toLowerCase();
    final filtered = song
        .where((s) => s.artist.toLowerCase().contains(key))
        .toList();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => _FilteredSongsPage(title: artist.name, songs: filtered),
      ),
    );
  }

  void showBottonSheet(Song targetSong) {
    showModalBottomSheet<String>(
      context: context,
      builder: (_) => AddToPlaylistSheet(song: targetSong),
    ).then((value) {
      if (value != null && value.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value)),
        );
      }
    });
  }

  Future<void> navigate(Song songs) async {
    final manager = AudioPlayerManager();
    await manager.updateSongUrl(
      songs.source,
      song: songs,
      playlist: song,
      isNewSong: true,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) {
          return NowPlaying(songs: song, playingSong: songs);
        },
      ),
    );
  }
}

// ====== Widgets phụ ======

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/img.png',
              image: album.image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              imageErrorBuilder: (_, __, ___) =>
                  Image.asset('assets/img.png', width: 100, height: 100),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 100,
            child: Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistCard({required this.artist, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(artist.image),
            onBackgroundImageError: (_, __) {},
            child: artist.image.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 110,
            child: Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongItemSection extends StatelessWidget {
  const _SongItemSection({required this.parent, required this.song, super.key});

  final _HomeTabPageState parent;
  final Song song;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/img.png',
          image: song.image,
          width: 48,
          height: 48,
          imageErrorBuilder: (_, __, ___) =>
              Image.asset('assets/img.png', width: 48, height: 48),
        ),
      ),
      title: Text(song.title),
      subtitle: Text(song.artist),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () => parent.showBottonSheet(song),
      ),
      onTap: () => parent.navigate(song),
    );
  }
}

class _FilteredSongsPage extends StatelessWidget {
  final String title;
  final List<Song> songs;

  const _FilteredSongsPage({
    required this.title,
    required this.songs,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: songs.isEmpty
          ? const Center(child: Text("Chưa có bài hát"))
          : ListView.separated(
              itemCount: songs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = songs[i];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/img.png',
                      image: s.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (_, __, ___) =>
                          const Icon(Icons.music_note),
                    ),
                  ),
                  title: Text(s.title),
                  subtitle: Text('${s.artist} • ${s.album ?? ""}'),
                  onTap: () {
                    // TODO: play bài hát s hoặc chuyển NowPlaying
                  },
                );
              },
            ),
    );
  }
}
