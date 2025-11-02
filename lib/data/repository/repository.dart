import '../model/song.dart';
import '../model/album.dart';
import '../model/artist.dart';
import '../source/source.dart';

abstract interface class Repository{
  Future<List<Song>?> getSongs();
  Future<List<Album>?> getAlbums();
  Future<List<Artist>?> getArtists();

  Future<List<Song>> getSongsByAlbumId(String albumId);
  Future<List<Song>> getSongsByArtistId(String artistId);
}

class DefaultRepository implements Repository{
  final _localDatasource = LocalDatasource();
  final _remoteDatasource = RemoteDatasource();

  List<Song>? _songsCache;
  List<Album>? _albumsCache;
  List<Artist>? _artistsCache;

  @override
  Future<List<Album>?> getAlbums() async  {
    if(_albumsCache != null) return _albumsCache;
    _albumsCache = await _localDatasource.loadAlbums();
    return _albumsCache;
  }

  @override
  Future<List<Artist>?> getArtists() async {
    if(_artistsCache != null) return _artistsCache;
    _artistsCache = await _localDatasource.loadArtists();
    return _artistsCache;
  }

  @override
  Future<List<Song>?> getSongs() async {
    if(_songsCache != null) return _songsCache;
    _songsCache = await _localDatasource.loadSongs();
    return _songsCache;
  }

  @override
  Future<List<Song>> getSongsByAlbumId(String albumId) async {
    final songs = await getSongs() ?? <Song>[];
    final albums = await getAlbums() ?? <Album>[];
    final album = albums.firstWhere((album) => album.id == albumId, orElse: () =>
        Album(id: albumId, name: '', image: '', songIds: const [], artists: const [], songCount: 0));
    final idSet = album.songIds.toSet();
    return songs.where((song) => idSet.contains(song.id)).toList();
  }

  @override
  Future<List<Song>> getSongsByArtistId(String artistId) async {
    final songs = await getSongs() ?? <Song>[];
    final artists = await getArtists() ?? <Artist>[];
    final artist = artists.firstWhere((artist) => artist.id == artistId, orElse: () =>
        Artist(id: artistId, name: '', image: '', songIds: const [], songCount: 0));
    final idSet = artist.songIds.toSet();
    return songs.where((song) => idSet.contains(song.id)).toList();
  }

  
  
}
