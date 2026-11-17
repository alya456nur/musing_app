import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_player_page.dart';
import 'like_button_provider.dart';
import 'my_player.dart';

class CustomSearchDelegate extends SearchDelegate {
  final List<dynamic> firebaseSongs;

  CustomSearchDelegate({required this.firebaseSongs});

  Future<void> playSong(BuildContext context, dynamic song, int index) async {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    try {
      player.setSongs(firebaseSongs, index);
      await player.playSong(song, index);
      final songId = song['id']; // Assuming each song has an 'id' field
      await _addToRecents(context, songId);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MyPlayerPage(
          firebaseSongs: firebaseSongs,
          initialIndex: index,
          isResuming: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error playing song: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to play song: $e')),
      );
    }
  }

  Future<void> _addToRecents(BuildContext context, String songId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final userId = user.uid;

      final recentsCollection = FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('RECENTS');

      // Use songId as document ID and set LastPlayed field
      await recentsCollection.doc(songId).set({
        'LastPlayed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge to update or create
    } catch (e) {
      if (kDebugMode) {
        print("Error adding to RECENTS: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update RECENTS: $e')),
      );
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      primaryColor: Colors.black,
      hintColor: Colors.white54,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: Colors.white,
          fontFamily: 'Cardo',
          fontSize: 14,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontFamily: 'Cardo',
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.white54,
          fontFamily: 'Cardo',
        ),
        border: InputBorder.none,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  String? get searchFieldLabel => 'Search songs, artists, genre...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
        color: Colors.white,
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
      color: Colors.white,
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Fetch liked songs before displaying results
    final likeButtonProvider = Provider.of<LikeButtonProvider>(context, listen: false);
    likeButtonProvider.fetchLikedSongs();

    final results = firebaseSongs.where((element) =>
    element['Title'].toLowerCase().contains(query.toLowerCase()) ||
        element['Artist'].toLowerCase().contains(query.toLowerCase()) ||
        element['Genre'].toLowerCase().contains(query.toLowerCase())
    ).toList();

    return _buildListView(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Fetch liked songs before displaying suggestions
    final likeButtonProvider = Provider.of<LikeButtonProvider>(context, listen: false);
    likeButtonProvider.fetchLikedSongs();

    final suggestions = firebaseSongs.where((element) =>
    element['Title'].toLowerCase().contains(query.toLowerCase()) ||
        element['Artist'].toLowerCase().contains(query.toLowerCase()) ||
        element['Genre'].toLowerCase().contains(query.toLowerCase())
    ).toList();

    return _buildListView(context, suggestions);
  }

  Widget _buildListView(BuildContext context, List<dynamic> songs) {
    return Container(
      color: Colors.black,
      child: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          return _buildSongTile(context, songs[index], index);
        },
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, Map<String, dynamic> song, int index) {
    final String title = song['Title'];
    final String artist = song['Artist'];
    final String genre = song['Genre'];
    final String imageUrl = song['Image'] ?? 'assets/images/track.png';

    return Consumer<LikeButtonProvider>(
      builder: (context, likeButtonProvider, child) {
        final bool isLiked = likeButtonProvider.isLiked(song['id']);

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50.0,
              height: 50.0,
              child: Image(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/track.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
          title: Text(
            '$title - $artist',
            style: const TextStyle(color: Colors.white, fontFamily: 'Cardo', fontSize: 14),
          ),
          subtitle: Text(
            genre,
            style: const TextStyle(color: Colors.white54, fontFamily: 'Cardo', fontSize: 12),
          ),
          trailing: GestureDetector(
            onTap: () {
              if (isLiked) {
                likeButtonProvider.toggleLike(song['id']);
              } else {
                likeButtonProvider.addSongToLiked(song['id']);
              }
            },
            child: AnimatedSwitcher(
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
          ),
          onTap: () async {
            await playSong(context, song, index);
          },
        );
      },
    );
  }
}
