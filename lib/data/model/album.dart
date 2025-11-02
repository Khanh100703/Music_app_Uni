
class Album {
  final String id;
  final String name;
  final String image;
  final List<String> songIds;
  final List<String> artists;
  final int songCount;

  Album({
    required this.id,
    required this.name,
    required this.image,
    required this.songIds,
    required this.artists,
    required this.songCount,
  });

  factory Album.fromJson(Map<String, dynamic> j) => Album(
    id: j['id'],
    name: j['name'],
    image: j['image'] ?? '',
    songIds: (j['song_ids'] as List).map((e) => e.toString()).toList(),
    artists: (j['artists'] as List?)?.map((e) => e.toString()).toList() ?? [],
    songCount: j['song_count'] ?? (j['song_ids'] as List).length,
  );
}
