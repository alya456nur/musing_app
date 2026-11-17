import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musing_app/player_provider.dart';
import 'package:provider/provider.dart';
import 'my_player.dart';
import 'like_button_provider.dart';
import 'download_provider.dart';

class MyPlayerPage extends StatefulWidget {
  final List<dynamic> firebaseSongs;
  final int initialIndex;
  final bool isResuming;

  const MyPlayerPage({
    super.key,
    required this.firebaseSongs,
    required this.initialIndex,
    this.isResuming = false,
  });

  @override
  MyPlayerPageState createState() => MyPlayerPageState();
}

class MyPlayerPageState extends State<MyPlayerPage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late List<dynamic> _tempSongs;// Temporary song list for "Up Next" tab
  List<int> _shuffleOrder = [];
  String _lyrics = "No lyrics are available for this song.";
  late TabController _tabController;
  late DraggableScrollableController _draggableScrollableController;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tempSongs = List.from(widget.firebaseSongs); // Initialize with local songs
    _tabController = TabController(length: 2, vsync: this);
    _draggableScrollableController = DraggableScrollableController();


    if (Provider.of<MyPlayerProvider>(context, listen: false).isShuffling) {
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
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    final player2 = Provider.of<PlayerProvider>(context, listen: false);
    player.addListener(_onPlayerStateChanged);
    player2.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    player.removeListener(_onPlayerStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    if (player.isPlaying && player.currentPosition >= player.songDuration) {
      if (_isLooping) {
        _playCurrentSong();
      } else {
        _skipToNext();
      }
    }
  }


  Future<void> _playCurrentSong() async {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    final player2 = Provider.of<PlayerProvider>(context, listen: false);
    final song = _tempSongs[_currentIndex]; // Play based on _tempSongs
    if (song['Song'] != null) {
      await player.playSong(song, _currentIndex);
      player2.stopSong();
    }
    setState(() {
      // Update song details when starting a new song
      _fetchLyrics();
    });
  }

  Future<void> _fetchLyrics() async {
    final song = _tempSongs[_currentIndex];
    String fetchedLyrics = await _getLyricsForSong(song['Title'], song['Song'] ?? "Unknown Artist");

    setState(() {
      _lyrics = fetchedLyrics.isNotEmpty ? fetchedLyrics : "No lyrics are available for this song.";
    });
  }

  Future<String> _getLyricsForSong(String title, String artist) async {
    await Future.delayed(const Duration(seconds: 1));
    return "";
  }

  void _skipToPrevious() {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    } else if (_isLooping) {
      setState(() {
        _currentIndex = _tempSongs.length - 1;
        player.setSongs(_tempSongs, _currentIndex);
      });
    }
    _playCurrentSong();
  }

  void _skipToNext() {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    if (_currentIndex < _tempSongs.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else if (_isLooping) {
      setState(() {
        _currentIndex = 0;
        player.setSongs(_tempSongs, _currentIndex);
      });
    }
    _playCurrentSong();
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  void _generateShuffleOrder() {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    _shuffleOrder = List<int>.generate(widget.firebaseSongs.length, (index) => index);
    _shuffleOrder.shuffle();
    player.setShuffledSongs(_shuffleOrder.map((index) => widget.firebaseSongs[index]).toList());
  }

  void _toggleShuffle() {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    player.shuffleSongs(); // Toggle shuffle mode in MyPlayerProvider

    setState(() {
      if (player.isShuffling) {
        _generateShuffleOrder();
        _tempSongs = player.shuffledSongs;
      } else {
        _tempSongs = List.from(widget.firebaseSongs); // Reset to original local order
      }
      player.setSongs(_tempSongs, _currentIndex);
    });
  }

  void _showPlaylistSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'User not logged in';
    }

    final userId = user.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black, // Set background color to black
      isScrollControlled: true, // Allows full screen height
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('USER')
                  .doc(userId)
                  .collection('PLAYLISTS')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No playlists found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final playlists = snapshot.data!.docs;

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Add Song To Playlist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          var playlist = playlists[index];
                          List<dynamic> songs = playlist['songs'] ?? [];
                          String? lastSongId = songs.isNotEmpty ? songs.last : null;

                          if (songs.isEmpty) {
                            return Container(
                              height: 80,
                              padding: const EdgeInsets.symmetric(vertical: 5.0),
                              child: ListTile(
                                leading: _buildLeadingWidget(null),
                                title: Text(
                                  playlist['name'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  '0 songs',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                onTap: () {
                                  final song = _tempSongs[_currentIndex];
                                  _addSongToPlaylist(userId, playlist.id, song['id'], context);
                                },
                              ),
                            );
                          }

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('SONGS')
                                .doc(lastSongId)
                                .get(),
                            builder: (context, songSnapshot) {
                              if (songSnapshot.connectionState == ConnectionState.waiting) {
                                return ListTile(
                                  leading: _buildLeadingWidget(null),
                                  title: const Text('Loading...'),
                                );
                              }
                              if (songSnapshot.hasError) {
                                return ListTile(
                                  leading: _buildLeadingWidget(null),
                                  title: const Text(
                                    'Error loading song details',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                              if (!songSnapshot.hasData || !songSnapshot.data!.exists) {
                                return ListTile(
                                  leading: _buildLeadingWidget(null),
                                  title: const Text('Song not found'),
                                );
                              }

                              final songData = songSnapshot.data!;
                              return Container(
                                height: 80,
                                padding: const EdgeInsets.symmetric(vertical: 5.0),
                                child: ListTile(
                                  leading: _buildLeadingWidget(songData),
                                  title: Text(
                                    playlist['name'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    '${songs.length} songs',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  onTap: () {
                                    final song = _tempSongs[_currentIndex];
                                    _addSongToPlaylist(userId, playlist.id, song['id'], context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLeadingWidget(DocumentSnapshot? songSnapshot) {
    if (songSnapshot == null) {
      return Image.asset(
        'assets/images/track.png', // Default asset image path
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    }

    final String? imageUrl = songSnapshot['Image'] as String?;
    final Widget defaultImage = Image.asset(
      'assets/images/track.png', // Default asset image path
      width: 50,
      height: 50,
      fit: BoxFit.cover,
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return defaultImage; // Return default image if imageUrl is null or empty
    }
  }

  void _addSongToPlaylist(String userId, String playlistId, String songId, BuildContext context) {
    FirebaseFirestore.instance
        .collection('USER')
        .doc(userId)
        .collection('PLAYLISTS')
        .doc(playlistId)
        .update({
      'songs': FieldValue.arrayUnion([songId]),
    }).then((_) {
      Navigator.pop(context); // Close the bottom sheet
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add song: $error')),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    final song = _tempSongs[_currentIndex]; // Display current song based on _tempSongs
    final likeButtonProvider = Provider.of<LikeButtonProvider>(context, listen: false);
    likeButtonProvider.fetchLikedSongs();
    bool isLiked = likeButtonProvider.isLiked(song['id']);
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    downloadProvider.fetchDownloadsSongs();
    bool isDownloaded = downloadProvider.isDownloaded(song['id']);

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
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 40.0),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            elevation: 0,
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Consumer<MyPlayerProvider>(
                  builder: (context, player, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: song['Image'] != null && song['Image'].isNotEmpty
                              ? Image.network(
                            song['Image'], // Assuming 'Image' is the field storing the image URL
                            width: 350,
                            height: 300,
                            fit: BoxFit.cover,
                          )
                              : Image.asset(
                            'assets/images/track.png', // Local asset image
                            width: 350,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 40, // Set height limit
                                width: double.infinity, // Set width limit
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    song['Title'],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cardo',
                                    ),
                                    textAlign: TextAlign.left,
                                    maxLines: 1, // Set to 1 line for horizontal scrolling
                                    overflow: TextOverflow.visible, // Allow overflow to be visible for scrolling
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                song['Artist'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cardo',
                                ),
                                textAlign: TextAlign.left,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF262525), // Background color
                                        foregroundColor: Colors.white, // Icon and label color
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20.0),
                                        ),
                                        elevation: 0, // Remove shadow
                                      ),
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        switchInCurve: Curves.easeIn,
                                        switchOutCurve: Curves.easeOut,
                                        transitionBuilder: (child, animation) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          );
                                        },
                                        child: isLiked
                                            ? const Icon(
                                          Icons.favorite,
                                          key: Key('filled'),
                                          color: Colors.red,
                                        )
                                            : const Icon(
                                          Icons.favorite_border_outlined,
                                          key: Key('border'),
                                          color: Colors.white,
                                        ),
                                      ),
                                      label: const Text('Like', style: TextStyle(color: Colors.white)),
                                      onPressed: (){
                                        if (isLiked) {
                                          likeButtonProvider.toggleLike(song['id']);
                                        } else {
                                          likeButtonProvider.addSongToLiked(song['id']);
                                        }
                                        setState(() {
                                          isLiked = !isLiked; // Toggle the liked state
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    CustomIconButton(
                                      icon: Icons.playlist_add,
                                      label: 'Save',
                                      onPressed: () {
                                        _showPlaylistSheet(context);
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF262525), // Background color
                                        foregroundColor: Colors.white, // Icon and label color
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20.0),
                                        ),
                                        elevation: 0, // Remove shadow
                                      ),
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        switchInCurve: Curves.easeIn,
                                        switchOutCurve: Curves.easeOut,
                                        transitionBuilder: (child, animation) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          );
                                        },
                                        child: isDownloaded
                                            ? const Icon(
                                          Icons.check_circle,
                                          key: Key('check_circle'),
                                          color: Colors.white,
                                        )
                                            : const Icon(
                                          Icons.download,
                                          key: Key('download'),
                                          color: Colors.white,
                                        ),
                                      ),
                                      label: const Text('Download', style: TextStyle(color: Colors.white)),
                                      onPressed: (){
                                        if (isDownloaded) {
                                          downloadProvider.toggleDownload(context, song['id']);
                                        } else {
                                          downloadProvider.addSongToDownloads(song['id']);
                                        }
                                        setState(() {
                                          isDownloaded = !isDownloaded; // Toggle the liked state
                                        });
                                      },
                                    ),
                                    CustomIconButton(
                                      icon: Icons.download,
                                      label: 'Download',
                                      onPressed: () {
                                        // Handle download action
                                      },
                                    ),
                                  ],
                                ),
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
                                color: player.isShuffling ? Colors.green : Colors.white,
                                size: 30.0,
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
                                size: 80.0,
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
                                color: _isLooping ? Colors.green : Colors.white,
                                size: 30.0,
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
      initialChildSize: 0.1,
      minChildSize: 0.1,
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
          child: SingleChildScrollView(
            controller: scrollController,
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
                const SizedBox(height: 8),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7, // Adjust height as needed
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
          ),
        );
      },
    );
  }


  Widget _buildUpNextTab(ScrollController scrollController) {
    List<dynamic> songs = _tempSongs;
    List<dynamic> firebase = widget.firebaseSongs;
    final player = Provider.of<MyPlayerProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ReorderableListView(
        scrollController: scrollController,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final dynamic song = _tempSongs.removeAt(oldIndex);
            _tempSongs.insert(newIndex, song);

            // Update currentIndex to match the reordered list
            if (_currentIndex == oldIndex) {
              _currentIndex = newIndex;
            } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
              _currentIndex--;
            } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
              _currentIndex++;
            }

            player.setSongs(_tempSongs, _currentIndex);
          });
        },
        children: _tempSongs.map((song) {
          final bool isPlaying = _tempSongs.indexOf(song) == _currentIndex;

          return Dismissible(
            key: Key(song['id'].toString()),
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
                int dismissedIndex = _tempSongs.indexOf(song);
                _tempSongs.removeAt(dismissedIndex);

                // Adjust currentIndex if needed
                if (dismissedIndex < _currentIndex) {
                  _currentIndex--;
                } else if (dismissedIndex == _currentIndex) {
                  if (_currentIndex >= _tempSongs.length) {
                    _currentIndex = _tempSongs.isEmpty ? 0 : _tempSongs.length - 1;
                  }
                  player.skipNext();
                }

                // Update player's song list and index
                player.setSongs(_tempSongs, _currentIndex);
              });
            },
            child: ListTile(
              tileColor: isPlaying ? Colors.grey[300] : Colors.transparent, // Lighter color for currently playing song
              leading: Image.network(
                song['Image'], // Assuming 'Image' is the field storing the image URL
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              title: Text(
                song['Title'],
                style: TextStyle(color: isPlaying ? Colors.green : Colors.white), // Adjust text color for currently playing song
              ),
              subtitle: Text(
                song['Artist'] ?? 'Unknown Artist',
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                setState(() {
                  _currentIndex = _tempSongs.indexOf(song);
                  player.setSongs(_tempSongs, _currentIndex);
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


class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF262525), // Background color
        foregroundColor: Colors.white, // Icon and label color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 0, // Remove shadow
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      onPressed: onPressed,
    );
  }
}


