import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musing_app/music_grid.dart';
import 'package:musing_app/player_control2.dart';
import 'package:musing_app/player_controls.dart';
import 'package:musing_app/playlist.dart';
import 'package:musing_app/profile.dart';
import 'package:musing_app/search_delegate.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => AppScreenState();
}

class AppScreenState extends State<AppScreen> {
  int _index = 0;
  final PageController _pageController = PageController();
  late String userUid = ''; // Initialize with empty string
  bool isLoadingRecentSongs = true; // Add a loading state
  bool _hasFetchedSongs = false; // Track if songs have been fetched to avoid multiple calls

  List<dynamic> recommendedSongs = []; // Store recommended songs
  List<dynamic> recentSongs = []; // Store recent songs
  List<dynamic> genres = [
    {'name': 'Electronic', 'isSelected': false},
    {'name': 'Pop', 'isSelected': false},
    {'name': 'J-Pop', 'isSelected': false},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Safely retrieve userUid from route arguments
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is String) {
        setState(() {
          userUid = arguments;
        });
      }
    });
    _fetchRecommendedSongs(); // Fetch recommended songs when widget initializes
    _fetchRecentlyPlayedSongs(); // Fetch recently played songs
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only fetch recently played songs if they haven't been fetched yet
    if (!_hasFetchedSongs) {
      _fetchRecentlyPlayedSongs();
      _hasFetchedSongs = true;
    }
  }

  Future<void> _fetchRecommendedSongs() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('SONGS').get();

      setState(() {
        recommendedSongs = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recommended songs: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch recommended songs: $e')),
      );
    }
  }

  Future<void> _fetchRecentlyPlayedSongs() async {
    setState(() {
      isLoadingRecentSongs = true; // Set loading state to true
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final userId = user.uid;

      // Step 1: Fetch recent song IDs from RECENTS collection
      final recentsSnapshot = await FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('RECENTS')
          .orderBy('LastPlayed', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> fetchedRecentSongs = [];

      for (var doc in recentsSnapshot.docs) {
        final songId = doc.id; // Get the song ID from RECENTS
        final lastPlayed = doc['LastPlayed'];

        // Step 2: Fetch song details from SONGS collection using song ID
        final songSnapshot = await FirebaseFirestore.instance
            .collection('SONGS')
            .doc(songId)
            .get();

        if (songSnapshot.exists) {
          final songData = songSnapshot.data() as Map<String, dynamic>;
          // Add song ID and LastPlayed to the song data
          songData['id'] = songId;
          songData['LastPlayed'] = lastPlayed;
          fetchedRecentSongs.add(songData);
                }
      }

      // Step 3: Update the state
      setState(() {
        recentSongs = fetchedRecentSongs;
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recently played songs: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch recently played songs: $e')),
      );
    } finally {
      setState(() {
        isLoadingRecentSongs = false; // Set loading state to false
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> getSongsByGenre(String genre) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('SONGS')
        .where('Genre', isEqualTo: genre)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final kTabPages = <Widget>[
      CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 150,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF9011C3),
                      Color(0xFF380262),
                      Color(0xFF000000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: 34,
                      left: 0,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/brand.png',
                            height: 45,
                            width: 100,
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              showSearch(
                                context: context,
                                delegate: CustomSearchDelegate(
                                  firebaseSongs: recommendedSongs,
                                ),
                              );
                            },
                            child: Container(
                              height: 40.0,
                              width: 280.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF413E3E),
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                              child: const Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(
                                      Icons.search,
                                      color: Color(0xFFA59C9C),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Search songs, artists, genre...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'Cardo',
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: genres.map((genre) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: GradientButton(
                                  text: genre['name'] as String,
                                  onPressed: () async {
                                    if (!(genre['isSelected'] as bool)) {
                                      await _filterByGenre(genre['name'] as String);
                                    } else {
                                      _resetSearchResults();
                                    }
                                    setState(() {
                                      for (var g in genres) {
                                        if (g['name'] == genre['name']) {
                                          g['isSelected'] = !(g['isSelected'] as bool);
                                        } else {
                                          g['isSelected'] = false;
                                        }
                                      }
                                    });
                                  },
                                  colors: genre['isSelected']
                                      ? [Colors.grey, Colors.grey]
                                      : _getGradientColors(genre['name'] as String),
                                  width: 150.0,
                                  height: 50.0,
                                  fontSize: 16.0,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: SingleChildScrollView(
              child: Container(
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoadingRecentSongs)
                        const Center(child: CircularProgressIndicator()),
                      if (!isLoadingRecentSongs && recentSongs.isNotEmpty && !genres.any((genre) => genre['isSelected']))
                        MusicGrid(
                          title: 'Recently Played',
                          firebaseSongs: recentSongs,
                        ),
                      if (!isLoadingRecentSongs && recommendedSongs.isNotEmpty && !genres.any((genre) => genre['isSelected']))
                        MusicGrid(
                          title: 'Recommendations',
                          firebaseSongs: recommendedSongs,
                        ),
                      ...genres.map((genre) {
                        if (genre['isSelected'] as bool) {
                          return FutureBuilder<List<dynamic>>(
                            future: getSongsByGenre(genre['name'] as String),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              final genreSongs = snapshot.data!;
                              return MusicGrid(
                                title: genre['name'] as String,
                                firebaseSongs: genreSongs,
                              );
                            },
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      PlaylistScreen(uid: userUid),
      ProfileScreen(uid: userUid),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                _index = index;
              });
              _resetSearchResults(); // Reset search results when navigating
              if (index == 0) {
                _fetchRecentlyPlayedSongs(); // Update recent songs when navigating to the home page
              }
            },
            children: kTabPages,
          ),
          const Positioned(
            bottom: 0, // Position above the BottomNavigationBar
            left: 0,
            right: 0,
            child: PlayerControls(),
          ),
          const Positioned(
            bottom: 0, // Position above the BottomNavigationBar
            left: 0,
            right: 0,
            child: PlayerControls2(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF262525), // Set background color
        selectedItemColor: Colors.white, // Set selected icon color
        unselectedItemColor: const Color(0xFFA59C9C), // Set unselected icon color
        currentIndex: _index,
        onTap: (int index) {
          setState(() {
            _index = index;
          });
          _pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Playlist'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _filterByGenre(String genre) async {
    final songs = await getSongsByGenre(genre);
    setState(() {
      recommendedSongs = songs;
    });
  }

  void _resetSearchResults() {
    // Reset to recommended songs
    setState(() {
      recommendedSongs = []; // Clear the current list
      _fetchRecommendedSongs(); // Re-fetch recommended songs
    });
  }

  List<Color> _getGradientColors(String genreName) {
    switch (genreName) {
      case 'Electronic':
        return [const Color(0xFF8C52FF), const Color(0xFF5CE1E6)];
      case 'Pop':
        return [const Color(0xFFFF66C4), const Color(0xFFFFDE59)];
      case 'J-Pop':
        return [const Color(0xFF0CC0DF), const Color(0xFFFFDE59)];
      default:
        return [Colors.grey, Colors.grey]; // Default colors if no match
    }
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> colors;
  final double width;
  final double height;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.colors,
    this.width = 200.0,
    this.height = 60.0,
    this.fontSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontFamily: 'Cardo',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
