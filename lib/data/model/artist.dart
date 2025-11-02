
class Artist {
  final String id;
  final String name;
  final String image;
  final List<String> songIds;
  final int songCount;

  Artist({
    required this.id,
    required this.name,
    required this.image,
    required this.songIds,
    required this.songCount,
  });

  factory Artist.fromJson(Map<String, dynamic> j) => Artist(
    id: j['id'],
    name: j['name'],
    image: j['image'] ?? '',
    songIds: (j['song_ids'] as List).map((e) => e.toString()).toList(),
    songCount: j['song_count'] ?? (j['song_ids'] as List).length,
  );
}
