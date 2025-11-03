import 'package:flutter/material.dart';

import '../../data/model/song.dart';
import '../../services/library_controller.dart';

class AddToPlaylistSheet extends StatefulWidget {
  const AddToPlaylistSheet({super.key, required this.song});

  final Song song;

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final LibraryController _controller = LibraryController.instance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final playlists = _controller.playlists;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thêm "${widget.song.title}"',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final name = await _showCreatePlaylistDialog(context);
                    if (name != null && name.trim().isNotEmpty) {
                      await _controller.createPlaylist(name.trim());
                      if (!mounted) return;
                      Navigator.of(context).pop('Đã tạo playlist "$name"');
                    }
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Tạo playlist mới'),
                ),
                const SizedBox(height: 12),
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Chưa có playlist nào'),
                    ),
                  )
                else
                  SizedBox(
                    height: (playlists.length * 72.0).clamp(180.0, 360.0),
                    child: ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final added = playlist.songIds.contains(widget.song.id);
                        return ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.songIds.length} bài hát'),
                          trailing: added
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: added
                              ? null
                              : () async {
                                  await _controller.addSongToPlaylist(
                                    playlist.id,
                                    widget.song,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(context).pop(
                                    'Đã thêm vào "${playlist.name}"',
                                  );
                                },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String?> _showCreatePlaylistDialog(BuildContext context) async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Playlist mới'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên playlist',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(textController.text.trim());
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
    textController.dispose();
    return result;
  }
}
