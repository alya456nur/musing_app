import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:musing_app/player_control2.dart';
import 'package:provider/provider.dart';

import 'download_provider.dart';
import 'firebase_player_page.dart';
import 'my_player.dart';

class DownloadScreen extends StatefulWidget{
  const DownloadScreen({super.key});


  @override
  DownloadScreenState createState() => DownloadScreenState();
}

class DownloadScreenState extends State<DownloadScreen> {
  late List<dynamic> downloadSongs = [];
  late String userId;
  bool isLoadingDownloads = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
        _fetchDownloads();
      });
    }
  }

  Future<void> _fetchDownloads() async {
    setState(() {
      isLoadingDownloads = true; // Set loading state to true
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final userId = user.uid;

      // Step 1: Fetch song IDs from USER > userId > PLAYLISTS > Downloads
      final downloadsDoc = await FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('PLAYLISTS')
          .doc('Downloads')
          .get();

      if (!downloadsDoc.exists || !downloadsDoc.data()!.containsKey('songs')) {
        throw 'No downloads found';
      }

      List<dynamic> songIds = downloadsDoc.data()?['songs'];
      List<Map<String, dynamic>> fetchedDownloadSongs = [];

      for (var songId in songIds) {
        // Step 2: Fetch song details from SONGS collection using song ID
        final songSnapshot = await FirebaseFirestore.instance
            .collection('SONGS')
            .doc(songId)
            .get();

        if (songSnapshot.exists) {
          final songData = songSnapshot.data() as Map<String, dynamic>;
          // Add song ID to the song data
          songData['id'] = songId;
          fetchedDownloadSongs.add(songData);
                }
      }

      // Step 3: Update the state
      setState(() {
        downloadSongs = fetchedDownloadSongs;
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error fetching downloaded songs: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch downloaded songs: $e')),
      );
    } finally {
      setState(() {
        isLoadingDownloads = false; // Set loading state to false
      });
    }
  }


  Future<void> _showRemoveDialog(String trackId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Song'),
          content: const Text('Are you sure you want to remove this song from downloads?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromPlaylist(trackId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFromPlaylist(String trackId) async {
    final firestore = FirebaseFirestore.instance;
    final playlistDoc = firestore
        .collection('USER')
        .doc(userId)
        .collection('PLAYLISTS')
        .doc('Downloads');

    await playlistDoc.update({
      'songs': FieldValue.arrayRemove([trackId]),
    });

    setState(() {
      downloadSongs.removeWhere((track) => track['id'] == trackId); // Remove from local list
    });
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    return [
      const PopupMenuItem<String>(
        value: 'Play Next',
        child: Text('Play Next', style: TextStyle(color: Colors.white)),
      ),
      const PopupMenuItem<String>(
        value: 'Add To Queue',
        child: Text('Add To Queue', style: TextStyle(color: Colors.white)),
      ),
      const PopupMenuItem<String>(
        value: 'Remove',
        child: Text('Remove from downloads', style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  Widget _buildLeadingWidget(dynamic track) {
    final String? imageUrl = track['Image']; // Replace with your actual field for image URL
    final Widget defaultImage = Image.asset(
      'assets/images/track.png', // Replace with your default asset image path
      width: 56,
      height: 56,
      fit: BoxFit.cover,
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return defaultImage;
    }
  }

  Future<void> _playSong(dynamic song, int index) async {
    final player = Provider.of<MyPlayerProvider>(context, listen: false); // Replace with actual user ID
    final songId = song['id']; // Assuming each song has an 'id' field

    try {
      // Set playlist and play song
      player.setSongs(downloadSongs, index);
      await player.playSong(song, index);

      // Add song ID to user's RECENTS collection
      await _addToRecents(songId);

      // Show PlayerPage in modal bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MyPlayerPage(
          firebaseSongs: downloadSongs, // Pass widget.firebaseSongs to MyPlayerPage
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

  void _handleMenuAction(BuildContext context, String value, String trackId, Map<String,dynamic> track) async {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    switch (value) {
      case 'Play Next':
        player.playNext(track);
        break;
      case 'Add To Queue':
        player.addToQueue(track);
        break;
      case 'Remove':
        _showRemoveDialog(trackId);
        break;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Downloads",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cardo',
          ),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          userId.isNotEmpty
              ? ListView.builder(
            itemCount: downloadSongs.length,
            itemBuilder: (context, index) {
              final track = downloadSongs[index];
              return GestureDetector(
                onTap: () {
                  _playSong(track, index); // Play song when tapped
                },
                child: ListTile(
                  leading: _buildLeadingWidget(track),
                  title: Text(
                    track['Title'] ?? 'Unknown Title',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    track['Artist'] ?? 'Unknown Artist',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (context) => _buildMenuItems(context),
                    onSelected: (value) =>
                        _handleMenuAction(context, value, track['id'],track),
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: const Color(0xFF151515),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                ),
              );
            },
          )
              : const Center(
            child: CircularProgressIndicator(),
          ),
          const Positioned(
            bottom: 0, // Position above the BottomNavigationBar
            left: 0,
            right: 0,
            child: PlayerControls2(),
          ),
        ],
      ),
    );
  }
}
