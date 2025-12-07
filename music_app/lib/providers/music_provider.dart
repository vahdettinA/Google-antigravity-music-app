import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

/// Music player provider managing playback state and playlist
class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<SongModel> _songs = [];
  List<SongModel> _currentPlaylist = [];
  SongModel? _currentSong;
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isShuffled = false;
  bool _isRepeat = false;

  // Playlists: {'Favorites': [song1, song2], 'My Workout': [...]}
  final Map<String, List<SongModel>> _playlists = {};

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  List<SongModel> get songs => _songs;
  List<SongModel> get currentPlaylist => _currentPlaylist;
  Map<String, List<SongModel>> get playlists => _playlists;
  SongModel? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isShuffled => _isShuffled;
  bool get isRepeat => _isRepeat;

  MusicProvider() {
    _init();
  }

  void _init() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Listen to playback completion
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });

    loadPlaylists();
  }

  /// Load all songs from device
  Future<void> loadSongs() async {
    try {
      _songs.clear();
      // Common music directories on Android
      List<String> musicPaths = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Audio',
      ];

      for (var path in musicPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          try {
            final entities = dir.listSync(recursive: true);
            for (var entity in entities) {
              if (entity is File) {
                if (entity.path.toLowerCase().endsWith('.mp3') ||
                    entity.path.toLowerCase().endsWith('.m4a') ||
                    entity.path.toLowerCase().endsWith('.wav')) {
                  String fileName = entity.path.split('/').last;
                  String title = fileName.substring(
                    0,
                    fileName.lastIndexOf('.'),
                  );

                  _songs.add(
                    SongModel(
                      id: entity.path.hashCode.toString(),
                      title: title,
                      artist: 'Unknown Artist',
                      data: entity.path,
                      duration: 0,
                    ),
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('Error reading directory $path: $e');
          }
        }
      }

      _currentPlaylist = List.from(_songs);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading songs: $e');
    }
  }

  /// Play a specific song
  Future<void> playSong(SongModel song, {List<SongModel>? playlist}) async {
    try {
      if (playlist != null) {
        _currentPlaylist = playlist;
      }

      _currentSong = song;
      _currentIndex = _currentPlaylist.indexWhere((s) => s.id == song.id);

      await _audioPlayer.setFilePath(song.data);
      await _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  /// Play next song
  Future<void> playNext() async {
    if (_currentPlaylist.isEmpty) return;

    if (_isRepeat && _currentSong != null) {
      await playSong(_currentSong!);
      return;
    }

    int nextIndex = (_currentIndex + 1) % _currentPlaylist.length;
    await playSong(_currentPlaylist[nextIndex]);
  }

  /// Play previous song
  Future<void> playPrevious() async {
    if (_currentPlaylist.isEmpty) return;

    if (_currentPosition.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }

    int prevIndex =
        (_currentIndex - 1 + _currentPlaylist.length) % _currentPlaylist.length;
    await playSong(_currentPlaylist[prevIndex]);
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Toggle shuffle
  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _currentPlaylist.shuffle();
      if (_currentSong != null) {
        _currentIndex = _currentPlaylist.indexWhere(
          (s) => s.id == _currentSong!.id,
        );
      }
    } else {
      _currentPlaylist = List.from(_songs);
      if (_currentSong != null) {
        _currentIndex = _currentPlaylist.indexWhere(
          (s) => s.id == _currentSong!.id,
        );
      }
    }
    notifyListeners();
  }

  /// Toggle repeat
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  /// Create a temporary playlist queue from selected songs (internal use mostly)
  void createQueue(List<SongModel> songs) {
    _currentPlaylist = songs;
    notifyListeners();
  }

  /// Create a new user playlist
  void createNewPlaylist(String name) {
    if (!_playlists.containsKey(name)) {
      _playlists[name] = [];
      savePlaylists();
      notifyListeners();
    }
  }

  /// Add song to a specific playlist
  void addToPlaylist(String playlistName, SongModel song) {
    if (_playlists.containsKey(playlistName)) {
      if (!_playlists[playlistName]!.any((s) => s.id == song.id)) {
        _playlists[playlistName]!.add(song);
        savePlaylists();
        notifyListeners();
      }
    }
  }

  /// Remove song from playlist
  void removeFromPlaylist(String playlistName, SongModel song) {
    if (_playlists.containsKey(playlistName)) {
      _playlists[playlistName]!.removeWhere((s) => s.id == song.id);
      savePlaylists();
      notifyListeners();
    }
  }

  /// Delete a playlist
  void deletePlaylist(String name) {
    _playlists.remove(name);
    savePlaylists();
    notifyListeners();
  }

  Future<void> savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = {};
    _playlists.forEach((key, value) {
      jsonMap[key] = value.map((e) => e.toJson()).toList();
    });
    await prefs.setString('playlists', json.encode(jsonMap));
  }

  Future<void> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('playlists');
    if (jsonStr != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      _playlists.clear();
      jsonMap.forEach((key, value) {
        final List<dynamic> list = value;
        _playlists[key] = list.map((e) => SongModel.fromJson(e)).toList();
      });
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
