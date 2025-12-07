import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/colors.dart';
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

/// Home screen displaying the music library
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request storage permission
    if (await Permission.storage.request().isGranted ||
        await Permission.audio.request().isGranted) {
      if (!mounted) return;
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      await musicProvider.loadSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.isGlassTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'my_music'.tr(),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isGlass
                ? [
                    AppColors.darkBackground1,
                    AppColors.darkBackground2,
                    AppColors.darkBackground1,
                  ]
                : [
                    AppColors.darkerBackground1,
                    AppColors.darkerBackground2,
                    AppColors.darkerBackground1,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Segmented Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text('tab_songs'.tr()),
                      icon: const Icon(Icons.music_note_rounded),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('tab_playlists'.tr()),
                      icon: const Icon(Icons.queue_music_rounded),
                    ),
                  ],
                  selected: {_selectedIndex},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedIndex = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.primary;
                      }
                      return isGlass ? AppColors.white10 : AppColors.grey800;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.white;
                      }
                      return AppColors.white70;
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _selectedIndex == 0
                    ? _buildSongsTab(context, musicProvider, isGlass)
                    : _buildPlaylistsTab(context, musicProvider, isGlass),
              ),

              // Mini player
              if (musicProvider.currentSong != null)
                _buildMiniPlayer(context, musicProvider, isGlass),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongsTab(
    BuildContext context,
    MusicProvider musicProvider,
    bool isGlass,
  ) {
    return Column(
      children: [
        // Song count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _buildGlassContainer(
            isGlass: isGlass,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'songs_count'.tr(
                      args: [musicProvider.songs.length.toString()],
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Songs list
        Expanded(
          child: musicProvider.songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 64,
                        color: AppColors.white10,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_music_found'.tr(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: musicProvider.songs.length,
                  itemBuilder: (context, index) {
                    final song = musicProvider.songs[index];
                    final isCurrentSong =
                        musicProvider.currentSong?.id == song.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSongTile(
                        context,
                        song,
                        isCurrentSong,
                        isGlass,
                        musicProvider,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsTab(
    BuildContext context,
    MusicProvider musicProvider,
    bool isGlass,
  ) {
    final playlists = musicProvider.playlists.keys.toList();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Create new playlist card
          return InkWell(
            onTap: () => _showCreatePlaylistDialog(context, musicProvider),
            child: _buildGlassContainer(
              isGlass: isGlass,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'new_playlist'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final playlistName = playlists[index - 1];
        final songCount = musicProvider.playlists[playlistName]?.length ?? 0;

        return InkWell(
          onTap: () {
            // Play playlist (load into queue and play first song)
            final songs = musicProvider.playlists[playlistName];
            if (songs != null && songs.isNotEmpty) {
              musicProvider.playSong(songs.first, playlist: songs);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playlist is empty'),
                ), // Need translation but user didn't ask
              );
            }
          },
          onLongPress: () {
            // Delete option?
            _showDeletePlaylistDialog(context, musicProvider, playlistName);
          },
          child: _buildGlassContainer(
            isGlass: isGlass,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 48,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    playlistName,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$songCount songs', // Need translation
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    MusicProvider musicProvider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('create_playlist'.tr()),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'playlist_name'.tr(),
              hintText: 'playlist_name'.tr(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  musicProvider.createNewPlaylist(controller.text);
                  Navigator.pop(context);
                }
              },
              child: Text('create'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePlaylistDialog(
    BuildContext context,
    MusicProvider musicProvider,
    String playlistName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Playlist'),
          content: Text('Are you sure you want to delete "$playlistName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                musicProvider.deletePlaylist(playlistName);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: AppColors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassContainer({required bool isGlass, required Widget child}) {
    if (isGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            child: child,
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlack,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }
  }

  Widget _buildSongTile(
    BuildContext context,
    SongModel song,
    bool isCurrentSong,
    bool isGlass,
    MusicProvider musicProvider,
  ) {
    return _buildGlassContainer(
      isGlass: isGlass,
      child: InkWell(
        onTap: () {
          musicProvider.playSong(song);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlayerScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Album art or music icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isCurrentSong
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? 'unknown_artist'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Duration
              Text(
                _formatDuration(Duration(milliseconds: song.duration ?? 0)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),

              // Playing indicator
              if (isCurrentSong)
                Icon(
                  musicProvider.isPlaying
                      ? Icons.graphic_eq_rounded
                      : Icons.pause_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(
    BuildContext context,
    MusicProvider musicProvider,
    bool isGlass,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
      child: _buildGlassContainer(
        isGlass: isGlass,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Album art
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      musicProvider.currentSong!.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      musicProvider.currentSong!.artist ??
                          'unknown_artist'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Play/Pause button
              IconButton(
                icon: Icon(
                  musicProvider.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  size: 40,
                ),
                onPressed: () => musicProvider.togglePlayPause(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
