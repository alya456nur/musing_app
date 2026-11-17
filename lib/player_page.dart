import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'my_player.dart';
import 'player_provider.dart';

class PlayerPage extends StatefulWidget {
  final List<MySongModel> localSongs;
  final int initialIndex;
  final bool isResuming;

  const PlayerPage({
    super.key,
    required this.localSongs,
    required this.initialIndex,
    this.isResuming = false,
  });

  @override
  PlayerPageState createState() => PlayerPageState();
}

class PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late List<MySongModel> _tempSongs;// Temporary song list for "Up Next" tab
  List<int> _shuffleOrder = [];
  String _lyrics = "No lyrics are available for this song.";
  late TabController _tabController;
  late DraggableScrollableController _draggableScrollableController;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tempSongs = List.from(widget.localSongs); // Initialize with local songs
    _tabController = TabController(length: 2, vsync: this);
    _draggableScrollableController = DraggableScrollableController();

    if (Provider.of<PlayerProvider>(context, listen: false).isShuffling) {
      _generateShuffleOrder();
    }
    if (!widget.isResuming) {
      _playCurrentSong();
    }
    _fetchLyrics();

    // Listen for tab changes and expand the sheet
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _draggableScrollableController.animateTo(
          0.9, // Expand to max size
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // Listen for player changes
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final player2 = Provider.of<MyPlayerProvider>(context, listen: false);
    player.addListener(_onPlayerStateChanged);
    player2.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    player.removeListener(_onPlayerStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    if (player.isPlaying && player.currentPosition >= player.songDuration) {
      if (_isLooping) {
        _playCurrentSong();
      } else {
        _skipToNext();
      }
    }
  }

  void _generateShuffleOrder() {
    _shuffleOrder = List<int>.generate(widget.localSongs.length, (index) => index);
    _shuffleOrder.shuffle();
    _tempSongs = _shuffleOrder.map((index) => widget.localSongs[index]).toList();
  }

  Future<void> _playCurrentSong() async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final player2 = Provider.of<MyPlayerProvider>(context, listen: false);
    final song = _tempSongs[_currentIndex]; // Play based on _tempSongs
    if (song.uri != null) {
      await player.playSong(song, _currentIndex);
      player2.stopSong();
    }
    setState(() {
      // Update song details when starting a new song
      _fetchLyrics();
    });
  }

  Future<Uint8List?> _getSongArtwork(MySongModel song) async {
        // Local song artwork handling
        final artwork = await OnAudioQuery().queryArtwork(song.id, ArtworkType.AUDIO);
        if (artwork != null && artwork.isNotEmpty) {
          return artwork;
        }
        return null;
  }

  Future<void> _fetchLyrics() async {
    final song = _tempSongs[_currentIndex];
    String fetchedLyrics = await _getLyricsForSong(song.title, song.artist ?? "Unknown Artist");

    setState(() {
      _lyrics = fetchedLyrics.isNotEmpty ? fetchedLyrics : "No lyrics are available for this song.";
    });
  }

  Future<String> _getLyricsForSong(String title, String artist) async {
    await Future.delayed(const Duration(seconds: 1));
    return "";
  }

  void _skipToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    } else if (_isLooping) {
      setState(() {
        _currentIndex = _tempSongs.length - 1;
      });
    }
    _playCurrentSong();
  }

  void _skipToNext() {
    if (_currentIndex < _tempSongs.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else if (_isLooping) {
      setState(() {
        _currentIndex = 0;
      });
    }
    _playCurrentSong();
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  void _toggleShuffle() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    player.toggleShuffle();
    setState(() {
      if (player.isShuffling) {
        _generateShuffleOrder();
        _tempSongs = _shuffleOrder.map((index) => widget.localSongs[index]).toList();
      } else {
        _tempSongs = List.from(widget.localSongs); // Reset to original local order
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = _tempSongs[_currentIndex]; // Display current song based on _tempSongs

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: AppBar(
            title: const Text(
              "Now Playing",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 40.0), // Change the back arrow icon here
              onPressed: () {
                Navigator.of(context).pop(); // This will pop the current route and animate back
              },
            ),
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Consumer<PlayerProvider>(
                builder: (context, player, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align all children to the left
                    children: [
                      const SizedBox(height: 20),
                      Center( // Center the image
                        child: FutureBuilder<Uint8List?>(
                          future: _getSongArtwork(song),
                          builder: (context, snapshot) {
                            final artwork = snapshot.data ?? player.currentImage;
                            return Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                image: artwork != null
                                    ? DecorationImage(
                                  image: MemoryImage(artwork),
                                  fit: BoxFit.cover,
                                )
                                    : const DecorationImage(
                                  image: AssetImage('assets/images/track.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              song.artist ?? 'Unknown Artist',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Slider(
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
                        min: 0.0,
                        max: player.songDuration.inSeconds.toDouble(),
                        value: player.currentPosition.inSeconds.toDouble(),
                        onChanged: (value) {
                          player.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(player.currentPosition),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _formatDuration(player.songDuration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              size: 30.0,
                              color: player.isShuffling ? Colors.green : Colors.white,
                            ),
                            onPressed: _toggleShuffle,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 40.0,
                            ),
                            onPressed: _skipToPrevious,
                          ),
                          IconButton(
                            icon: Icon(
                              player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: Colors.white,
                              size: 80.0, // Adjusted icon size
                            ),
                            onPressed: () {
                              player.isPlaying ? player.pause() : player.resume();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 40.0,
                            ),
                            onPressed: _skipToNext,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.loop,
                              size: 30.0,
                              color: _isLooping ? Colors.green : Colors.white,
                            ),
                            onPressed: _toggleLoop,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ],
          ),
          _buildDraggableScrollableSheet(),
        ],
      ),
    );
  }


  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildDraggableScrollableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.2,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 50,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                tabs: const [
                  Tab(text: 'Up Next'),
                  Tab(text: 'Lyrics'),
                ],
                labelColor: Colors.white,
                indicatorColor: Colors.white,
                controller: _tabController,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUpNextTab(scrollController), // Pass scrollController here
                    _buildLyricsTab(scrollController), // Pass scrollController here
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpNextTab(ScrollController scrollController) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ReorderableListView(
        scrollController: scrollController,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final MySongModel song = _tempSongs.removeAt(oldIndex);
            _tempSongs.insert(newIndex, song);

            // Update currentIndex to match the reordered list
            if (_currentIndex == oldIndex) {
              _currentIndex = newIndex;
              player.setPlaylist(_tempSongs, _currentIndex);
            } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
              _currentIndex--;
              player.setPlaylist(_tempSongs, _currentIndex);
            } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
              _currentIndex++;
              player.setPlaylist(_tempSongs, _currentIndex);
            }
          });
        },
        children: _tempSongs.map((song) {
          final bool isPlaying = _tempSongs.indexOf(song) == _currentIndex;

          return Dismissible(
            key: Key(song.id.toString()),
            background: Container(
              alignment: Alignment.centerRight,
              color: Colors.red,
              child: const Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
            onDismissed: (direction) {
              setState(() {
                _tempSongs.remove(song);
                player.setPlaylist(_tempSongs, _currentIndex);
                player.playSong(song, _currentIndex);
                if (_currentIndex >= _tempSongs.length) {
                  _currentIndex = _tempSongs.length - 1;
                  player.setPlaylist(_tempSongs, _currentIndex);
                }
                // If the dismissed song is currently playing, stop it and play the next song
                if (_currentIndex == _tempSongs.indexOf(song)) {
                  _currentIndex++; // Play the next song
                  player.setPlaylist(_tempSongs, _currentIndex);
                  if (_currentIndex >= _tempSongs.length) {
                    _currentIndex = 0; // Wrap around to the beginning of the list
                    player.setPlaylist(_tempSongs, _currentIndex);
                  }
                  _playCurrentSong();
                }
              });
            },
            child: ListTile(
              tileColor: isPlaying ? Colors.grey[850] : Colors.transparent,
              leading: FutureBuilder<Uint8List?>(
                future: _getSongArtwork(song),
                builder: (context, snapshot) {
                  final artwork = snapshot.data;
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      image: DecorationImage(
                        image: artwork != null
                            ? MemoryImage(artwork)
                            : const AssetImage('assets/images/track.png') as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              title: Text(
                song.title,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                song.artist ?? 'Unknown Artist',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() {
                  _currentIndex = _tempSongs.indexOf(song);
                  _playCurrentSong();
                });
              },
              trailing: SizedBox(
                width: 40,
                child: IconButton(
                  icon: const Icon(Icons.drag_handle),
                  color: Colors.white,
                  onPressed: () {},
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLyricsTab(ScrollController scrollController) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Text(
          _lyrics,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}