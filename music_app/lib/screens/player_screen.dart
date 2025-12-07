import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/colors.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/audio_wave_animation.dart';

/// Player screen with full playback controls
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.isGlassTheme;
    final song = musicProvider.currentSong;

    if (song == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'no_song_playing'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              _showAddToPlaylistDialog(context, musicProvider, song);
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),

                // Album art with glassmorphism
                _buildAlbumArt(context, isGlass),

                const SizedBox(height: 48),

                // Song info
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  song.artist ?? 'Unknown Artist',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.white60),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Audio wave animation
                SizedBox(
                  height: 60,
                  child: AudioWaveAnimation(
                    isPlaying: musicProvider.isPlaying,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // Progress bar
                _buildProgressBar(context, musicProvider),

                const SizedBox(height: 32),

                // Playback controls
                _buildPlaybackControls(context, musicProvider),

                const SizedBox(height: 24),

                // Additional controls
                _buildAdditionalControls(context, musicProvider),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(BuildContext context, bool isGlass) {
    return Hero(
      tag: 'album_art',
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.width * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowPurple,
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: isGlass
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.glassWhite,
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Image.asset(
                      'assets/album.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAlbumArt(context);
                      },
                    ),
                  ),
                )
              : Image.asset(
                  'assets/album.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAlbumArt(context);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 120,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, MusicProvider musicProvider) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: AppColors.inactiveTrack,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: AppColors.overlayPurple,
          ),
          child: Slider(
            value: musicProvider.currentPosition.inSeconds.toDouble(),
            max: musicProvider.totalDuration.inSeconds.toDouble() > 0
                ? musicProvider.totalDuration.inSeconds.toDouble()
                : 1.0,
            onChanged: (value) {
              musicProvider.seekTo(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(musicProvider.currentPosition),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _formatDuration(musicProvider.totalDuration),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(
    BuildContext context,
    MusicProvider musicProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous button
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 48,
          onPressed: () => musicProvider.playPrevious(),
        ),

        // Play/Pause button
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPurpleLight,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              musicProvider.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 40,
            ),
            onPressed: () => musicProvider.togglePlayPause(),
          ),
        ),

        // Next button
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 48,
          onPressed: () => musicProvider.playNext(),
        ),
      ],
    );
  }

  Widget _buildAdditionalControls(
    BuildContext context,
    MusicProvider musicProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            size: 32, // Increased size
            color: musicProvider.isShuffled
                ? Theme.of(context).colorScheme.primary
                : AppColors.white,
          ),
          onPressed: () => musicProvider.toggleShuffle(),
        ),
        IconButton(
          icon: Icon(
            musicProvider.isRepeat
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            size: 32, // Increased size
            color: musicProvider.isRepeat
                ? Theme.of(context).colorScheme.primary
                : AppColors.white,
          ),
          onPressed: () => musicProvider.toggleRepeat(),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    MusicProvider musicProvider,
    dynamic song,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkBackground1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black54,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_playlist'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(
                            50,
                            Theme.of(context).colorScheme.primary.r.toInt(),
                            Theme.of(context).colorScheme.primary.g.toInt(),
                            Theme.of(context).colorScheme.primary.b.toInt(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        'create_playlist'.tr(),
                        style: const TextStyle(color: AppColors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showCreatePlaylistDialog(context, musicProvider, song);
                      },
                    ),
                    const Divider(color: AppColors.white10),
                    ...musicProvider.playlists.keys.map((playlistName) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.queue_music_rounded,
                            color: AppColors.white,
                          ),
                        ),
                        title: Text(
                          playlistName,
                          style: const TextStyle(color: AppColors.white),
                        ),
                        onTap: () {
                          musicProvider.addToPlaylist(playlistName, song);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'added_to'.tr(args: [playlistName]),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    if (musicProvider.playlists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'no_playlists'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.white60),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    MusicProvider musicProvider,
    dynamic song,
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
                  musicProvider.addToPlaylist(controller.text, song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('added_to'.tr(args: [controller.text])),
                    ),
                  );
                }
              },
              child: Text('create'.tr()),
            ),
          ],
        );
      },
    );
  }
}
