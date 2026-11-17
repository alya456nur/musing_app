import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'my_player.dart';
import 'firebase_player_page.dart';

class MusicGrid extends StatefulWidget {
  final String title;
  final List<dynamic> firebaseSongs;

  const MusicGrid({
    super.key,
    required this.title,
    required this.firebaseSongs,
  });

  @override
  MusicGridState createState() => MusicGridState();
}

class MusicGridState extends State<MusicGrid> {
  late List<dynamic> albums; // Initialize as empty list

  @override
  void initState() {
    super.initState();
    albums = widget.firebaseSongs; // Initialize albums with widget.firebaseSongs
  }

  Future<void> _playSong(dynamic song, int index) async {
    final player = Provider.of<MyPlayerProvider>(context, listen: false); // Replace with actual user ID
    final songId = song['id']; // Assuming each song has an 'id' field

    try {
      player.setSongs(albums, index);
      await player.playSong(song, index);

      // Add song ID to user's RECENTS collection
      await _addToRecents(songId);

      // Show PlayerPage in modal bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MyPlayerPage(
          firebaseSongs: albums, // Pass widget.firebaseSongs to MyPlayerPage
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

  Future<void> _addToRecents(String songId) async {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        albums.isEmpty
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            String imageUrl = album['Image']; // Handle 'Image' field properly
            if (imageUrl.isEmpty) {
              imageUrl = 'assets/images/track.png'; // Fallback to default image
            }

            return GestureDetector(
              onTap: () {
                _playSong(album, index);
                // Pass album and index to _playSong
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageUrl.startsWith('http')
                              ? NetworkImage(imageUrl) // Use NetworkImage for URLs
                              : AssetImage(imageUrl) as ImageProvider, // Use AssetImage for local images
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album['Title'] ?? '', // Handle null cases for 'Title'
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    album['Artist'] ?? '', // Handle null cases for 'Artist'
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
