import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../model/song.dart';
import '../model/album.dart';
import '../model/artist.dart';


abstract interface class Datasource{
  Future<List<Song>?> loadSongs();
  Future<List<Album>?> loadAlbums();
  Future<List<Artist>?> loadArtists();
}

class RemoteDatasource implements Datasource{
  @override
  Future<List<Song>?> loadSongs() async{
    const url = 'https://thantrieu.com/resources/braniumapis/songs.json';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if(response.statusCode == 200){
      final bodyContent = utf8.decode(response.bodyBytes);
      var songWrapper = jsonDecode(bodyContent) as Map;
      var songList = songWrapper['songs'] as List;
      List<Song> songs = songList.map((song) => Song.fromJson(song)).toList();
      return songs;
    } else{
      return null;
    }
  }

  @override
  Future<List<Album>?> loadAlbums() async => null;

  @override
  Future<List<Artist>?> loadArtists() async => null;
}

class LocalDatasource implements Datasource{
  @override
  Future<List<Song>?> loadSongs() async{
    final String reponse = await rootBundle.loadString('assets/songs.json');
    final jsonBody = jsonDecode(reponse) as Map;
    final songList = jsonBody['songs'] as List;
    List<Song> songs = songList.map((song) => Song.fromJson(song)).toList();
    return songs;
  }

  @override
  Future<List<Album>?> loadAlbums() async {
    final String reponse = await rootBundle.loadString('assets/albums.json');
    final jsonBody = jsonDecode(reponse) as Map;
    final albumList = jsonBody['albums'] as List;
    List<Album> albums = albumList.map((album) => Album.fromJson(album)).toList();
    return albums;
  }

  @override
  Future<List<Artist>?> loadArtists() async {
    final String reponse = await rootBundle.loadString('assets/artists.json');
    final jsonBody = jsonDecode(reponse) as Map;
    final artistList = jsonBody['artists'] as List;
    List<Artist> artists = artistList.map((artist) => Artist.fromJson(artist)).toList();
    return artists;
  }
}