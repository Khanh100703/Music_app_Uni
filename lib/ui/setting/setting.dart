import 'package:flutter/material.dart';

import '../../services/app_settings_controller.dart';
import '../../services/library_controller.dart';

class SettingTab extends StatefulWidget {
  const SettingTab({super.key});

  @override
  State<SettingTab> createState() => _SettingTabState();
}

class _SettingTabState extends State<SettingTab> {
  final AppSettingsController _settings = AppSettingsController.instance;
  final LibraryController _library = LibraryController.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSectionTitle('Playback'),
              _buildPlaybackSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Appearance'),
              _buildAppearanceSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Data & Privacy'),
              _buildDataPrivacySection(),
              const SizedBox(height: 24),
              _buildSectionTitle('About'),
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildPlaybackSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Loop mode mặc định'),
            trailing: DropdownButton<DefaultLoopMode>(
              value: _settings.defaultLoopMode,
              onChanged: (value) {
                if (value != null) {
                  _settings.setDefaultLoopMode(value);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: DefaultLoopMode.off,
                  child: Text('Tắt'),
                ),
                DropdownMenuItem(
                  value: DefaultLoopMode.one,
                  child: Text('Lặp một bài'),
                ),
                DropdownMenuItem(
                  value: DefaultLoopMode.all,
                  child: Text('Lặp toàn bộ'),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Auto-play bài tiếp theo'),
            value: _settings.autoPlayNext,
            onChanged: _settings.setAutoPlayNext,
          ),
          SwitchListTile(
            title: const Text('Mở Mini-player mặc định'),
            value: _settings.miniPlayerEnabled,
            onChanged: _settings.setMiniPlayerEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Theme'),
                DropdownButton<ThemeMode>(
                  value: _settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _settings.setThemeMode(value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Primary color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _settings.availablePrimaryColors.map((color) {
                final selected = _settings.primaryColor == color;
                return GestureDetector(
                  onTap: () => _settings.setPrimaryColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPrivacySection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history_toggle_off),
            title: const Text('Xoá lịch sử nghe'),
            onTap: () async {
              await _library.clearHistory();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xoá lịch sử nghe.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Đặt lại cài đặt'),
            onTap: () async {
              await _settings.reset();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đặt lại cài đặt mặc định.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Phiên bản'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Giấy phép mã nguồn mở'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Music App',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }
}
