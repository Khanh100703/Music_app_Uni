import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/model/song.dart';
import '../data/repository/repository.dart';

class PlaylistEntry {
  PlaylistEntry({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaylistEntry.fromJson(Map<String, dynamic> json) {
    return PlaylistEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      songIds: List<String>.from(json['songIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  String name;
  final List<String> songIds;
  DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PlayedEntry {
  PlayedEntry({required this.songId, required this.lastPlayed});

  factory PlayedEntry.fromJson(Map<String, dynamic> json) {
    return PlayedEntry(
      songId: json['songId'] as String,
      lastPlayed: DateTime.parse(json['lastPlayed'] as String),
    );
  }

  final String songId;
  DateTime lastPlayed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'songId': songId,
        'lastPlayed': lastPlayed.toIso8601String(),
      };
}

class LibraryController extends ChangeNotifier {
  LibraryController._internal();

  static final LibraryController instance = LibraryController._internal();

  static const _keyFavorites = 'library.favorites';
  static const _keyPlaylists = 'library.playlists';
  static const _keyHistory = 'library.history';
  static const _keyDownloadsVisible = 'library.downloadsVisible';

  final Repository _repository = DefaultRepository();
  late SharedPreferences _prefs;

  bool _initialized = false;
  bool _downloadsVisible = true;

  final List<Song> _allSongs = <Song>[];
  final List<String> _favoriteOrder = <String>[];
  final List<PlaylistEntry> _playlists = <PlaylistEntry>[];
  final List<PlayedEntry> _recentlyPlayed = <PlayedEntry>[];

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadLibrary();
    _initialized = true;
  }

  Future<void> _loadLibrary() async {
    final songs = await _repository.getSongs() ?? <Song>[];
    _allSongs
      ..clear()
      ..addAll(songs);

    final favorites = _prefs.getStringList(_keyFavorites) ?? <String>[];
    _favoriteOrder
      ..clear()
      ..addAll(favorites);

    final playlistsJson = _prefs.getString(_keyPlaylists);
    if (playlistsJson != null && playlistsJson.isNotEmpty) {
      final raw = jsonDecode(playlistsJson) as List;
      _playlists
        ..clear()
        ..addAll(
          raw.map((e) => PlaylistEntry.fromJson(e as Map<String, dynamic>)),
        );
    }

    final historyJson = _prefs.getString(_keyHistory);
    if (historyJson != null && historyJson.isNotEmpty) {
      final raw = jsonDecode(historyJson) as List;
      _recentlyPlayed
        ..clear()
        ..addAll(
          raw.map((e) => PlayedEntry.fromJson(e as Map<String, dynamic>)),
        );
    }

    _downloadsVisible = _prefs.getBool(_keyDownloadsVisible) ?? true;
    notifyListeners();
  }

  List<Song> get allSongs => List.unmodifiable(_allSongs);
  List<String> get favoriteSongIds => List.unmodifiable(_favoriteOrder);
  List<PlaylistEntry> get playlists => List.unmodifiable(_playlists);
  List<PlayedEntry> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  bool get downloadsVisible => _downloadsVisible;

  Song? findSongById(String id) {
    return _allSongs.firstWhereOrNull((song) => song.id == id);
  }

  void toggleFavorite(Song song) {
    if (_favoriteOrder.contains(song.id)) {
      _favoriteOrder.remove(song.id);
    } else {
      _favoriteOrder.insert(0, song.id);
    }
    _prefs.setStringList(_keyFavorites, _favoriteOrder);
    notifyListeners();
  }

  bool isFavorite(String songId) => _favoriteOrder.contains(songId);

  Future<void> createPlaylist(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();
    _playlists.add(
      PlaylistEntry(
        id: id,
        name: name,
        songIds: <String>[],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String id, String name) async {
    final playlist = _playlists.firstWhereOrNull((p) => p.id == id);
    if (playlist == null) return;
    playlist
      ..name = name
      ..updatedAt = DateTime.now();
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> reorderPlaylists(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final playlist = _playlists.removeAt(oldIndex);
    _playlists.insert(newIndex, playlist);
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlist = _playlists.firstWhereOrNull((p) => p.id == playlistId);
    if (playlist == null) return;
    if (!playlist.songIds.contains(song.id)) {
      playlist.songIds.add(song.id);
      playlist.updatedAt = DateTime.now();
      await _persistPlaylists();
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    final playlist = _playlists.firstWhereOrNull((p) => p.id == playlistId);
    if (playlist == null) return;
    playlist.songIds.remove(song.id);
    playlist.updatedAt = DateTime.now();
    await _persistPlaylists();
    notifyListeners();
  }

  List<Song> songsForPlaylist(PlaylistEntry playlist) {
    return playlist.songIds
        .map(findSongById)
        .whereType<Song>()
        .toList(growable: false);
  }

  Future<void> logRecentlyPlayed(Song song) async {
    final existingIndex = _recentlyPlayed.indexWhere((e) => e.songId == song.id);
    if (existingIndex != -1) {
      _recentlyPlayed.removeAt(existingIndex);
    }
    _recentlyPlayed.insert(
      0,
      PlayedEntry(songId: song.id, lastPlayed: DateTime.now()),
    );
    if (_recentlyPlayed.length > 10) {
      _recentlyPlayed.removeRange(10, _recentlyPlayed.length);
    }
    await _persistHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _recentlyPlayed.clear();
    await _prefs.remove(_keyHistory);
    notifyListeners();
  }

  Future<void> setDownloadsVisible(bool value) async {
    _downloadsVisible = value;
    await _prefs.setBool(_keyDownloadsVisible, value);
    notifyListeners();
  }

  Future<void> _persistPlaylists() async {
    final encoded = jsonEncode(_playlists.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyPlaylists, encoded);
  }

  Future<void> _persistHistory() async {
    final encoded = jsonEncode(_recentlyPlayed.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyHistory, encoded);
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
