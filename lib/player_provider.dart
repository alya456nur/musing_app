import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:uri_to_file/uri_to_file.dart';


class PlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isPause = false;
  bool _isShuffling = false;
  bool _isLooping = false;
  bool isVisible = true;
  final bool _isLocalSong = true;
  String _currentTitle = '';
  String _currentArtist = '';
  Uint8List? _currentImage;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;
  List<MySongModel> _playlist = [];
  final List<MySongModel> _queue = [];
  int _currentIndex = 0;

  bool get isPlaying => _isPlaying;
  bool get isPause => _isPause;
  bool get isShuffling => _isShuffling;
  bool get isLooping => _isLooping;
  bool get isLocalSong => _isLocalSong;
  String get currentTitle => _currentTitle;
  String get currentArtist => _currentArtist;
  Uint8List? get currentImage => _currentImage;
  Duration get currentPosition => _currentPosition;
  Duration get songDuration => _songDuration;
  MySongModel? get currentSong =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;

  List<MySongModel> get playlist => _playlist;
  List<MySongModel> get queue => _queue;

  int get currentIndex => _currentIndex;

  PlayerProvider() {
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _isPlaying = true;
        _isPause = false;
      } else if (state == PlayerState.paused) {
        _isPlaying = false;
        _isPause = true;
      } else if (state == PlayerState.stopped) {
        _isPlaying = false;
        _isPause = false;
        _currentPosition = Duration.zero;
      } else if (state == PlayerState.completed) {
        _handlePlaybackCompletion(); // Handle playback completion
      }
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _songDuration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _currentPosition = newPosition;
      notifyListeners();
    });
  }

  void setPlaylist(List<MySongModel> playlist, int index) {
    _playlist = playlist;
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> playSong(MySongModel song, int index) async {
    if (song.uri != null) {
      try {
        final file = await toFile(song.uri!);
        await _audioPlayer.play(DeviceFileSource(file.path));
        _currentTitle = song.title;
        _currentArtist = song.artist ?? "Unknown Artist";
        _currentImage = await _loadArtwork(song.id);
        _currentIndex = index;
      } catch (e) {
        if (kDebugMode) {
          print("Error playing song: $e");
        }
        throw Exception("Unable to create media player: $e");
      }
    } else {
      if (kDebugMode) {
        print("URI is null for song: ${song.title}");
      }
      throw Exception("Unable to create media player: URI is null");
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }
  void stop() async {
    await _audioPlayer.stop();
    _currentPosition = Duration.zero;
    _isPlaying = false;
    _isPause = false;

    notifyListeners();
  }

  Future<void> stopSong() async {
    await _audioPlayer.stop();
    _currentPosition = Duration.zero;
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> toggleShuffle() async {
    _isShuffling = !_isShuffling;
    setPlaylist(_playlist, _currentIndex);
    notifyListeners();
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
    notifyListeners(); // Notify listeners when loop state changes
  }

  void _handlePlaybackCompletion() async {
    if (_playlist.isEmpty) return; // Handle empty playlist case

    if (_isLooping) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
    } else {
      await skipToNext();
    }
    notifyListeners(); // Notify listeners on completion
  }

  Future<void> skipToNext() async {
    if (_isShuffling) {
      _playRandomSong();
    } else {
      await _skipToNextInPlaylist();
    }
  }

  Future<void> skipToPrevious() async {
    if (_currentPosition.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
    } else {
      if (_currentIndex > 0) {
        await _playSongAtIndex(_currentIndex - 1);
      }
    }
  }

  Future<void> _playRandomSong() async {
    if (_playlist.isNotEmpty) {
      final random = Random();
      final newIndex = random.nextInt(_playlist.length);
      await _playSongAtIndex(newIndex);
    }
  }

  Future<void> _skipToNextInPlaylist() async {
    if (_currentIndex < _playlist.length - 1) {
      await _playSongAtIndex(_currentIndex + 1);
    } else {
      await stopSong(); // Stop the song if no more songs in the playlist
    }
  }

  void playNext(MySongModel song) {
    // Ensure the song isn't already in the playlist before adding
    if (!_playlist.contains(song)) {
      if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
        _playlist.insert(_currentIndex + 1, song);
      } else {
        _playlist.add(song);
      }
    } else {
      // If the song is already in the playlist, remove it and then insert it next
      _playlist.remove(song);
      _playlist.insert(_currentIndex + 1, song);
    }
    notifyListeners();
  }

  void addToQueue(MySongModel song) {
    if (!_playlist.contains(song)) {
      _playlist.add(song);
    } else {
      // If the song is already in the playlist, remove it and then add it to the end
      _playlist.remove(song);
      _playlist.add(song);
    }
    notifyListeners();
  }

  Future<void> _playSongAtIndex(int index) async {
    final song = _playlist[index];
    await playSong(song, index);
  }

  Future<Uint8List?> _loadArtwork(int songId) async {
    final artwork =
    await OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO);
    if (artwork != null && artwork.isNotEmpty) {
      return artwork;
    } else {
      return null;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class MySongModel {
  final int id;
  final String title;
  final String? artist;
  final String? uri; // This can store both audio URI (for playback) and image URI (for artwork)
  final bool isLocal; // Flag to differentiate between local and Firebase songs

  MySongModel({
    required this.id,
    required this.title,
    this.artist,
    this.uri,
    this.isLocal = true, // Default to local song
  });

  factory MySongModel.fromSongModel(SongModel song) {
    return MySongModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      uri: song.uri,
    );
  }
}

