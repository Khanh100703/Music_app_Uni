import 'package:flutter/material.dart';

import '../../data/model/artist.dart';
import '../../data/model/song.dart';
import '../../data/repository/repository.dart';

enum ChartRange { day, week, month }

class ChartTab extends StatefulWidget {
  const ChartTab({super.key});

  @override
  State<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<ChartTab> {
  final Repository _repository = DefaultRepository();
  ChartRange _range = ChartRange.day;
  bool _loading = true;
  List<Song> _songs = <Song>[];
  List<Artist> _artists = <Artist>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final songs = await _repository.getSongs() ?? <Song>[];
    final artists = await _repository.getArtists() ?? <Artist>[];
    if (!mounted) return;
    setState(() {
      _songs = songs;
      _artists = artists;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SegmentedButton<ChartRange>(
                    segments: const <ButtonSegment<ChartRange>>[
                      ButtonSegment(value: ChartRange.day, label: Text('Ngày')),
                      ButtonSegment(value: ChartRange.week, label: Text('Tuần')),
                      ButtonSegment(value: ChartRange.month, label: Text('Tháng')),
                    ],
                    selected: <ChartRange>{_range},
                    onSelectionChanged: (values) {
                      if (values.isNotEmpty) {
                        setState(() => _range = values.first);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _ChartSectionTitle(title: 'Top bài hát'),
                        ..._buildSongItems(),
                        const SizedBox(height: 24),
                        _ChartSectionTitle(title: 'Top nghệ sĩ'),
                        ..._buildArtistItems(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildSongItems() {
    final topSongs = _calculateTopSongs().take(10).toList();
    if (topSongs.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Chưa có dữ liệu bài hát'),
        ),
      ];
    }
    return topSongs
        .asMap()
        .entries
        .map(
          (entry) => _ChartListTile(
            index: entry.key,
            title: entry.value.title,
            subtitle: entry.value.artist,
            score: entry.value.score,
          ),
        )
        .toList();
  }

  List<Widget> _buildArtistItems() {
    final topArtists = _calculateTopArtists().take(10).toList();
    if (topArtists.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Chưa có dữ liệu nghệ sĩ'),
        ),
      ];
    }
    return topArtists
        .asMap()
        .entries
        .map(
          (entry) => _ChartListTile(
            index: entry.key,
            title: entry.value.artist.name,
            subtitle: '${entry.value.artist.songCount} bài hát',
            score: entry.value.score,
          ),
        )
        .toList();
  }

  List<_SongChartData> _calculateTopSongs() {
    final items = _songs
        .map(
          (song) => _SongChartData(
            title: song.title,
            artist: song.artist,
            score: _scoreForId(song.id),
          ),
        )
        .toList();
    items.sort((a, b) => b.score.compareTo(a.score));
    return items;
  }

  Iterable<_ArtistChartData> _calculateTopArtists() sync* {
    final Map<String, int> scores = <String, int>{};
    final Map<String, Artist> artistById = {
      for (final artist in _artists) artist.id: artist,
    };
    for (final song in _songs) {
      final value = _scoreForId(song.id);
      for (final artist in _artists) {
        if (artist.songIds.contains(song.id)) {
          scores[artist.id] = (scores[artist.id] ?? 0) + value;
        }
      }
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      final artist = artistById[entry.key];
      if (artist != null) {
        yield _ArtistChartData(artist: artist, score: entry.value);
      }
    }
  }

  int _scoreForId(String id) {
    final base = id.hashCode.abs();
    switch (_range) {
      case ChartRange.day:
        return 50 + (base % 60);
      case ChartRange.week:
        return 80 + (base % 90);
      case ChartRange.month:
        return 120 + (base % 120);
    }
  }
}

class _ChartSectionTitle extends StatelessWidget {
  const _ChartSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _ChartListTile extends StatelessWidget {
  const _ChartListTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.score,
  });

  final int index;
  final String title;
  final String subtitle;
  final int score;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text('${index + 1}'),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text('$score'),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: () {},
      horizontalTitleGap: 12,
      minLeadingWidth: 32,
    );
  }
}

class _SongChartData {
  _SongChartData({
    required this.title,
    required this.artist,
    required this.score,
  });

  final String title;
  final String artist;
  final int score;
}

class _ArtistChartData {
  _ArtistChartData({required this.artist, required this.score});

  final Artist artist;
  final int score;
}
