import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musing_app/player_control2.dart';
import 'package:provider/provider.dart';

import 'download_provider.dart';
import 'firebase_player_page.dart';
import 'my_player.dart';

class TrackListScreen extends StatefulWidget {
  final String playlistTitle;
  final String playlistId;

  const TrackListScreen({
    super.key,
    required this.playlistTitle,
    required this.playlistId,
  });

  @override
  TrackListScreenState createState() => TrackListScreenState();
}

class TrackListScreenState extends State<TrackListScreen> {
  List<Map<String, dynamic>> downloadSongs = [];
  String userId = '';
  bool isLoadingDownloads = false;

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
      });
      _fetchPlaylistsSongs();
    }
  }

  Future<void> _fetchPlaylistsSongs() async {
    setState(() {
      isLoadingDownloads = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      // Fetch song IDs from USER > userId > PLAYLISTS > Downloads
      final songsDoc = await FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('PLAYLISTS')
          .doc(widget.playlistId)
          .get();

      if (!songsDoc.exists || !songsDoc.data()!.containsKey('songs')) {
        throw 'No downloads found';
      }

      List<dynamic> songIds = songsDoc.data()!['songs'];
      List<Map<String, dynamic>> fetchedPlaylistSongs = [];

      for (var songId in songIds) {
        // Fetch song details from SONGS collection using song ID
        final songSnapshot = await FirebaseFirestore.instance
            .collection('SONGS')
            .doc(songId)
            .get();

        if (songSnapshot.exists) {
          final songData = songSnapshot.data() as Map<String, dynamic>;
          // Add song ID to the song data
          songData['id'] = songId;
          fetchedPlaylistSongs.add(songData);
                }
      }

      setState(() {
        downloadSongs = fetchedPlaylistSongs;
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
        isLoadingDownloads = false;
      });
    }
  }

  void _handleMenuAction(BuildContext context, String value, String trackId, Map<String,dynamic> track) async {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    switch (value) {
      case 'Play Next':
        player.playNextMap(track);
        break;
      case 'Add To Queue':
        player.addToQueue(track);
        break;
      case 'Download':
        downloadProvider.addSongToDownloads(trackId);
        break;
      case 'Remove':
        _showRemoveDialog(trackId);
        break;
    }
  }

  Future<void> _showRemoveDialog(String trackId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Song',style: TextStyle(color: Colors.red)),
          backgroundColor: const Color(0xFF151515),
          content: const Text('Are you sure you want to remove this song from the playlist?',
            style: TextStyle(color: Colors.white),),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',style: TextStyle(color: Colors.white),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove',style: TextStyle(color: Colors.red),),
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
        .doc(widget.playlistId);

    await playlistDoc.update({
      'songs': FieldValue.arrayRemove([trackId]),
    });

    setState(() {
      downloadSongs.removeWhere((song) => song['id'] == trackId);
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
        value: 'Download',
        child: Text('Download', style: TextStyle(color: Colors.white)),
      ),
      const PopupMenuItem<String>(
        value: 'Remove',
        child: Text('Remove from playlist', style: TextStyle(color: Colors.white)),
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

  Future<void> _playSong(Map<String, dynamic> song, int index) async {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    final songId = song['id'];

    try {
      player.setSongs(downloadSongs, index);
      await player.playSong(song, index);

      await _addToRecents(songId);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MyPlayerPage(
          firebaseSongs: downloadSongs,
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

      await recentsCollection.doc(songId).set({
        'LastPlayed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
        title: Text(
          widget.playlistTitle,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Cardo',
          ),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          isLoadingDownloads
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : ListView.builder(
            itemCount: downloadSongs.length,
            itemBuilder: (context, index) {
              final track = downloadSongs[index];
              final trackId = track['id'];

              return GestureDetector(
                onTap: () {
                  _playSong(track, index);
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
                    onSelected: (value) => _handleMenuAction(context, value, trackId, track),
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: const Color(0xFF151515),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                ),
              );
            },
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PlayerControls2(),
          ),
        ],
      ),
    );
  }
}
