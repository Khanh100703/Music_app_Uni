import 'package:flutter/material.dart';

import '../../data/model/song.dart';
import '../../services/library_controller.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final LibraryController _controller = LibraryController.instance;
  bool _favoritesAsGrid = true;
  String _favoriteSort = 'recent';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thư viện'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Favorites'),
              Tab(text: 'Playlists'),
              Tab(text: 'Recently Played'),
              Tab(text: 'Downloads'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FavoritesSection(
              controller: _controller,
              favoritesAsGrid: _favoritesAsGrid,
              favoriteSort: _favoriteSort,
              onToggleLayout: () {
                setState(() => _favoritesAsGrid = !_favoritesAsGrid);
              },
              onChangeSort: (value) {
                setState(() => _favoriteSort = value);
              },
            ),
            _PlaylistsSection(controller: _controller),
            _RecentlyPlayedSection(controller: _controller),
            _DownloadsSection(controller: _controller),
          ],
        ),
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({
    required this.controller,
    required this.favoritesAsGrid,
    required this.favoriteSort,
    required this.onToggleLayout,
    required this.onChangeSort,
  });

  final LibraryController controller;
  final bool favoritesAsGrid;
  final String favoriteSort;
  final VoidCallback onToggleLayout;
  final ValueChanged<String> onChangeSort;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final favorites = controller.favoriteSongIds
            .map(controller.findSongById)
            .whereType<Song>()
            .toList();
        if (favoriteSort == 'name') {
          favorites.sort((a, b) => a.title.compareTo(b.title));
        }

        if (favorites.isEmpty) {
          return const Center(child: Text('Chưa có bài hát yêu thích'));
        }

        final toolbar = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${favorites.length} bài hát'),
              Row(
                children: [
                  IconButton(
                    onPressed: onToggleLayout,
                    icon: Icon(
                      favoritesAsGrid
                          ? Icons.grid_view
                          : Icons.view_list,
                    ),
                    tooltip: 'Đổi dạng xem',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sắp xếp',
                    initialValue: favoriteSort,
                    onSelected: onChangeSort,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'recent',
                        child: Text('Vừa thêm'),
                      ),
                      PopupMenuItem(
                        value: 'name',
                        child: Text('Tên bài'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );

        Widget content;
        if (favoritesAsGrid) {
          content = GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final song = favorites[index];
              return _FavoriteGridTile(song: song, controller: controller);
            },
          );
        } else {
          content = ListView.builder(
            itemCount: favorites.length,
            padding: const EdgeInsets.only(bottom: 24),
            itemBuilder: (context, index) {
              final song = favorites[index];
              return _FavoriteListTile(song: song, controller: controller);
            },
          );
        }

        return Column(
          children: [
            toolbar,
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

class _FavoriteGridTile extends StatelessWidget {
  const _FavoriteGridTile({required this.song, required this.controller});

  final Song song;
  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/img.png',
                image: song.image,
                fit: BoxFit.cover,
                imageErrorBuilder: (_, __, ___) =>
                    Image.asset('assets/img.png', fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite),
                color: Colors.red,
                onPressed: () {
                  controller.toggleFavorite(song);
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(content: Text('Đã gỡ khỏi Favorites')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoriteListTile extends StatelessWidget {
  const _FavoriteListTile({required this.song, required this.controller});

  final Song song;
  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/img.png',
          image: song.image,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          imageErrorBuilder: (_, __, ___) =>
              Image.asset('assets/img.png', width: 56, height: 56),
        ),
      ),
      title: Text(song.title),
      subtitle: Text(song.artist),
      trailing: IconButton(
        icon: const Icon(Icons.favorite),
        color: Colors.red,
        onPressed: () {
          controller.toggleFavorite(song);
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text('Đã gỡ khỏi Favorites')),
          );
        },
      ),
      onTap: () {},
    );
  }
}

class _PlaylistsSection extends StatefulWidget {
  const _PlaylistsSection({required this.controller});

  final LibraryController controller;

  @override
  State<_PlaylistsSection> createState() => _PlaylistsSectionState();
}

class _PlaylistsSectionState extends State<_PlaylistsSection> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final playlists = widget.controller.playlists;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${playlists.length} playlist',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _createPlaylist(context),
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Playlist mới'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: playlists.isEmpty
                  ? const Center(child: Text('Chưa có playlist nào'))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 64),
                      onReorder: (oldIndex, newIndex) {
                        widget.controller.reorderPlaylists(oldIndex, newIndex);
                      },
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          key: ValueKey(playlist.id),
                          leading: const Icon(Icons.drag_handle),
                          title: Text(playlist.name),
                          subtitle:
                              Text('${playlist.songIds.length} bài hát'),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () =>
                                _showPlaylistActions(context, playlist),
                          ),
                          onTap: () => _openPlaylist(context, playlist),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final name = await _promptForText(context, 'Playlist mới', 'Tên playlist');
    if (name != null && name.trim().isNotEmpty) {
      await widget.controller.createPlaylist(name.trim());
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Đã tạo playlist "$name"')),
      );
    }
  }

  Future<void> _showPlaylistActions(
    BuildContext context,
    PlaylistEntry playlist,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Đổi tên'),
                onTap: () => Navigator.pop(context, 'rename'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xoá playlist'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'rename') {
      final name = await _promptForText(context, 'Đổi tên', 'Tên mới',
          initialValue: playlist.name);
      if (name != null && name.trim().isNotEmpty) {
        await widget.controller.renamePlaylist(playlist.id, name.trim());
      }
    } else if (action == 'delete') {
      await widget.controller.deletePlaylist(playlist.id);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Đã xoá "${playlist.name}"')),
      );
    }
  }

  Future<void> _openPlaylist(
    BuildContext context,
    PlaylistEntry playlist,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  final songs = widget.controller.songsForPlaylist(playlist);
                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          playlist.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text('${songs.length} bài hát'),
                      ),
                      Expanded(
                        child: songs.isEmpty
                            ? const Center(
                                child: Text('Playlist chưa có bài hát'),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: songs.length,
                                itemBuilder: (context, index) {
                                  final song = songs[index];
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: FadeInImage.assetNetwork(
                                        placeholder: 'assets/img.png',
                                        image: song.image,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        imageErrorBuilder: (_, __, ___) =>
                                            Image.asset('assets/img.png',
                                                width: 48, height: 48),
                                      ),
                                    ),
                                    title: Text(song.title),
                                    subtitle: Text(song.artist),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => widget.controller
                                          .removeSongFromPlaylist(
                                              playlist.id, song),
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
          },
        );
      },
    );
  }

  Future<String?> _promptForText(
    BuildContext context,
    String title,
    String label, {
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: label),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập thông tin';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }
}

class _RecentlyPlayedSection extends StatelessWidget {
  const _RecentlyPlayedSection({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final items = controller.recentlyPlayed;
        if (items.isEmpty) {
          return const Center(child: Text('Chưa nghe bài hát nào gần đây'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final entry = items[index];
            final song = controller.findSongById(entry.songId);
            if (song == null) {
              return const SizedBox.shrink();
            }
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/img.png',
                  image: song.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) =>
                      Image.asset('assets/img.png', width: 56, height: 56),
                ),
              ),
              title: Text(song.title),
              subtitle: Text(
                'Nghe gần nhất: ${_formatRelativeTime(entry.lastPlayed)}',
              ),
            );
          },
        );
      },
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 1) return 'vừa xong';
    if (duration.inHours < 1) return '${duration.inMinutes} phút trước';
    if (duration.inHours < 24) return '${duration.inHours} giờ trước';
    return '${duration.inDays} ngày trước';
  }
}

class _DownloadsSection extends StatelessWidget {
  const _DownloadsSection({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              value: controller.downloadsVisible,
              onChanged: (value) {
                controller.setDownloadsVisible(value);
              },
              title: const Text('Hiển thị mục tải xuống'),
            ),
            const SizedBox(height: 12),
            if (controller.downloadsVisible)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tải xuống',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tính năng tải xuống sẽ được cập nhật trong phiên bản tiếp theo.',
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text('Mục tải xuống đang ẩn.'),
          ],
        );
      },
    );
  }
}
