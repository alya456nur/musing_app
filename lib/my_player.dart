import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class MyPlayerProvider extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isShuffleOn = false;
  bool _isLoopOn = false;
  int _currentIndex = 0;
  List<dynamic> _firebaseSongs = [];
  List<int> _shuffleOrder = [];
  List<dynamic> _shuffledSongs = [];
  final List<dynamic> _queue = [];
  bool _isPause = false;
  final bool _isVisible = true;
  final bool _isLocalSong = false;
  late String _currentTitle = '';
  late String _currentArtist = '';
  late String _currentImage = '';
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;
  bool isPlayingSong = false;

  bool get isPlaying => _isPlaying;
  bool get isPause => _isPause;
  bool get isShuffling => _isShuffleOn;
  bool get isLooping => _isLoopOn;
  bool get isLocalSong => _isLocalSong;
  String get currentTitle => _currentTitle;
  String get currentArtist => _currentArtist;
  String get currentImage => _currentImage;
  Duration get currentPosition => _currentPosition;
  Duration get songDuration => _songDuration;
  List<dynamic>? get currentSong =>
      _firebaseSongs.isNotEmpty ? _firebaseSongs[_currentIndex] : null;

  List<dynamic> get playlist => _firebaseSongs;
  List<dynamic> get queue => _queue;
  List<dynamic> get shuffledSongs => _shuffledSongs;

  int get currentIndex => _currentIndex;

  MyPlayerProvider() {
    _audioPlayer = AudioPlayer();
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
        _handlePlaybackCompletion();
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

  void stop() async {
    await _audioPlayer.stop();
    _currentPosition = Duration.zero;
    _isPlaying = false;
    _isPause = false;

    // Move to the next song
    _skipNext();

    notifyListeners();
  }

  void setSongs(List<dynamic> songs, int initialIndex) {
    _firebaseSongs = songs;
    _currentIndex = initialIndex;
    playCurrent();
    notifyListeners();
  }

  void playCurrent() async {
    if (_firebaseSongs.isEmpty) return;
    String songUrl = _firebaseSongs[_currentIndex]['Song'];
    await _audioPlayer.play(UrlSource(songUrl));
    _currentTitle = _firebaseSongs[_currentIndex]['Title'] ?? '';
    _currentArtist = _firebaseSongs[_currentIndex]['Artist'] ?? 'Unknown Artist';
    _currentImage = _firebaseSongs[_currentIndex]['Image'] ?? '';
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> playSong(dynamic song, int index) async {
    try {
      final String? songUrl = song['Song'];
      if (songUrl != null) {
        await _audioPlayer.play(UrlSource(songUrl));
        _currentTitle = song['Title'];
        _currentArtist = song['Artist'] ?? "Unknown Artist";
        _currentImage = song['Image'] ?? '';
        _isPlaying = true;
        notifyListeners();
      } else {
        throw Exception("URI is null for song: ${song['Title']}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error playing song: $e");
      }
      throw Exception("Unable to play song: $e");
    }
  }

  void _pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    _isPause = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  void playPause() {
    if (isPlaying) {
      _pause();
    } else {
      playCurrent();
    }
  }

  void shuffleSongs() {
    _isShuffleOn = !_isShuffleOn;
    if (_isShuffleOn) {
      _generateShuffleOrder();
      _shuffledSongs = _shuffleOrder.map((index) => _firebaseSongs[index]).toList();
      setSongs(_shuffledSongs, 0);
    } else {
      setSongs(_firebaseSongs, _currentIndex);
    }
    notifyListeners();
  }

  void _generateShuffleOrder() {
    _shuffleOrder = List<int>.generate(_firebaseSongs.length, (index) => index);
    _shuffleOrder.shuffle();
  }

  void setShuffledSongs(List<dynamic> songs) {
    _shuffledSongs = songs;
  }

  void shuffle() {
    _isShuffleOn = !_isShuffleOn;
    notifyListeners();
  }

  void loop() {
    _isLoopOn = !_isLoopOn;
    notifyListeners();
  }

  void _skipNext() {
    if (_isShuffleOn) {
      _playRandom();
    } else {
      _currentIndex = (_currentIndex + 1) % _firebaseSongs.length;
      playCurrent();
    }
  }

  void _handlePlaybackCompletion() async {
    if (_firebaseSongs.isEmpty) return;

    if (_isLoopOn) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
    } else {
      skipNext();
    }
    notifyListeners();
  }

  void skipNext() {
    _audioPlayer.stop();
    _skipNext();
  }

  void _skipPrevious() {
    if (_isShuffleOn) {
      _playRandom();
    } else {
      _currentIndex = (_currentIndex - 1) % _firebaseSongs.length;
      if (_currentIndex < 0) {
        _currentIndex = _firebaseSongs.length - 1;
      }
      playCurrent();
    }
  }

  void skipPrevious() {
    _audioPlayer.stop();
    _skipPrevious();
  }

  void _playRandom() {
    _currentIndex = Random().nextInt(_firebaseSongs.length);
    playCurrent();
  }

  Future<void> stopSong() async {
    await _audioPlayer.stop();
    _currentPosition = Duration.zero;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void playNext(dynamic song) {
    if (!_firebaseSongs.contains(song)) {
      _firebaseSongs.insert(_currentIndex + 1, song);
    } else {
      _firebaseSongs.remove(song);
      _firebaseSongs.insert(_currentIndex + 1, song);
    }
    notifyListeners();
  }

  void addToQueue(dynamic song) {
    if (!_firebaseSongs.contains(song)) {
      _firebaseSongs.add(song);
    } else {
      _firebaseSongs.remove(song);
      _firebaseSongs.add(song);
    }
    notifyListeners();
  }

  void playNextPlaylist(Map<String, dynamic> songs) {
    songs.forEach((key, value) {
      for (int i = 0; i < (value as List<dynamic>).length; i++) {
        final dynamic song = value[i];
        if (song is Map<String, dynamic>) {
          if (!_firebaseSongs.contains(song)) {
            _firebaseSongs.insert(_currentIndex + 1 + i, song);
          } else {
            _firebaseSongs.remove(song);
            _firebaseSongs.insert(_currentIndex + 1 + i, song);
          }
        } else {
          if (kDebugMode) {
            print('Invalid song format: $song');
          }
        }
      }
    });
    notifyListeners();
  }

  void addToQueuePlaylist(Map<String, dynamic> songs) {
    songs.forEach((key, value) {
      for (int i = 0; i < (value as List<dynamic>).length; i++) {
        final dynamic song = value[i];
        if (song is Map<String, dynamic>) {
          if (!_firebaseSongs.contains(song)) {
            _firebaseSongs.add(song);
          } else {
            _firebaseSongs.remove(song);
            _firebaseSongs.add(song);
          }
        } else {
          if (kDebugMode) {
            print('Invalid song format: $song');
          }
        }
      }
    });
    notifyListeners();
  }

  void addToQueueMap(Map<String, dynamic> song) {
    if (!_firebaseSongs.contains(song)) {
      _firebaseSongs.add(song);
    } else {
      _firebaseSongs.remove(song);
      _firebaseSongs.add(song);
    }
    notifyListeners();
  }

  void playNextMap(Map<String, dynamic> song) {
    if (!_firebaseSongs.contains(song)) {
      _firebaseSongs.insert(_currentIndex + 1, song);
    } else {
      _firebaseSongs.remove(song);
      _firebaseSongs.insert(_currentIndex + 1, song);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
