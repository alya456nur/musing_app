import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musing_app/track.dart';
import 'package:provider/provider.dart';

import 'download_provider.dart';
import 'my_player.dart';

class PlaylistScreen extends StatefulWidget {
  final String uid;
  const PlaylistScreen({super.key, required this.uid});

  @override
  State<PlaylistScreen> createState() => PlaylistScreenState();
}

class PlaylistScreenState extends State<PlaylistScreen> {
  final ScrollController _scrollController = ScrollController();

  List<String> playlists = [];
  Map<String, int> songCounts = {};
  Map<String, dynamic> playlistSongs = {};

  @override
  void initState() {
    super.initState();
    _fetchPlaylistsAndSongCounts();
  }

  Future<void> _fetchPlaylistsAndSongCounts() async {
    final firestore = FirebaseFirestore.instance;
    try {
      final playlistSnapshot = await firestore
          .collection('USER')
          .doc(widget.uid)
          .collection('PLAYLISTS')
          .get();

      final newPlaylists = playlistSnapshot.docs.map((doc) => doc.id).toList();
      final newSongCounts = <String, int>{};
      final newPlaylistSongs = <String, dynamic>{};

      for (var doc in playlistSnapshot.docs) {
        final songField = doc['songs'] as List<dynamic>? ?? [];
        newSongCounts[doc.id] = songField.length;
        newPlaylistSongs[doc.id] = songField;
      }

      setState(() {
        playlists = newPlaylists;
        songCounts = newSongCounts;
        playlistSongs = newPlaylistSongs;
      });

      // Ensure Liked Songs and Downloads playlists exist
      await _ensureDefaultPlaylistsExist();
    } catch (e) {
      setState(() {
        playlists = [];
        songCounts = {};
        playlistSongs = {};
      });
    }
  }

  Future<void> _ensureDefaultPlaylistsExist() async {
    final firestore = FirebaseFirestore.instance;
    try {
      await _createPermanentPlaylist(firestore, 'Liked Songs', 'Liked Songs');
      await _createPermanentPlaylist(firestore, 'Downloads', 'Downloads');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to ensure default playlists exist: $e');
      }
    }
  }

  Future<void> _createPermanentPlaylist(
      FirebaseFirestore firestore, String name, String id) async {
    final playlistDoc =
    firestore.collection('USER').doc(widget.uid).collection('PLAYLISTS').doc(id);

    final existingDoc = await playlistDoc.get();
    if (!existingDoc.exists) {
      await playlistDoc.set({
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
        'permanent': true,
        'songs': [],
      });

      setState(() {
        playlists.add(id);
        songCounts[id] = 0; // Initialize count for new playlist
        playlistSongs[id] = []; // Initialize songs array for new playlist
      });
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context, bool isPermanent) {
    return [
      if (!isPermanent)
        const PopupMenuItem<String>(
          value: 'Rename',
          child: Text('Rename', style: TextStyle(color: Colors.white)),
        ),
      if (!isPermanent)
        const PopupMenuItem<String>(
          value: 'Delete',
          child: Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      const PopupMenuItem<String>(
        value: 'Play Next',
        child: Text('Play Next', style: TextStyle(color: Colors.white)),
      ),
      const PopupMenuItem<String>(
        value: 'Add to Queue',
        child: Text('Add to Queue', style: TextStyle(color: Colors.white)),
      ),
      const PopupMenuItem<String>(
        value: 'Download',
        child: Text('Download', style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  void addPlaylist(String playlistName) async {
    final firestore = FirebaseFirestore.instance;
    final playlistDoc = firestore
        .collection('USER')
        .doc(widget.uid)
        .collection('PLAYLISTS')
        .doc(playlistName);

    try {
      await playlistDoc.set({
        'name': playlistName,
        'created_at': FieldValue.serverTimestamp(),
        'songs': []
      });

      setState(() {
        playlists.add(playlistName);
        songCounts[playlistName] = 0; // Initialize count for new playlist
        playlistSongs[playlistName] = []; // Initialize songs array for new playlist
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist has been added successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add playlist'),
        ),
      );
    }
  }

  void renamePlaylist(int index, String newName) async {
    final firestore = FirebaseFirestore.instance;
    final oldName = playlists[index];
    final oldDoc = firestore
        .collection('USER')
        .doc(widget.uid)
        .collection('PLAYLISTS')
        .doc(oldName);
    final newDoc = firestore
        .collection('USER')
        .doc(widget.uid)
        .collection('PLAYLISTS')
        .doc(newName);

    try {
      final oldPlaylistData = await oldDoc.get();

      await firestore.runTransaction((transaction) async {
        transaction.set(newDoc, oldPlaylistData.data()!);
        transaction.delete(oldDoc);
      });

      setState(() {
        playlists[index] = newName;
        songCounts[newName] = songCounts.remove(oldName) ?? 0; // Move count to new name
        playlistSongs[newName] = playlistSongs.remove(oldName) ?? []; // Move songs to new name
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to rename playlist'),
        ),
      );
    }
  }

  void deletePlaylist(int index) async {
    final firestore = FirebaseFirestore.instance;
    final name = playlists[index];
    final playlistDoc = firestore
        .collection('USER')
        .doc(widget.uid)
        .collection('PLAYLISTS')
        .doc(name);

    try {
      await playlistDoc.delete();

      setState(() {
        playlists.removeAt(index);
        songCounts.remove(name);
        playlistSongs.remove(name);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete playlist'),
        ),
      );
    }
  }

  void _showRenamePlaylistDialog(BuildContext context, int index) {
    String newPlaylistName = playlists[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Rename Playlist',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF151515),
          content: TextField(
            onChanged: (value) {
              newPlaylistName = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter new playlist name',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white), // Change input text color here
            controller: TextEditingController(text: newPlaylistName),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (newPlaylistName.isNotEmpty) {
                  renamePlaylist(index, newPlaylistName);
                }
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Rename', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Playlist',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF151515),
          content: const Text(
            'Are you sure you want to delete this playlist?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                deletePlaylist(index);
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPlaylistDialog(BuildContext context) {
    String newPlaylistName = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Add New Playlist',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF151515),
          content: TextField(
            onChanged: (value) {
              newPlaylistName = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter playlist name',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (newPlaylistName.isNotEmpty) {
                  addPlaylist(newPlaylistName);
                }
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(String value, int index) {
    final player = Provider.of<MyPlayerProvider>(context, listen: false);
    final player2 = Provider.of<DownloadProvider>(context, listen: false);
    switch (value) {
      case 'Rename':
        _showRenamePlaylistDialog(context, index);        break;
      case 'Delete':
        _showDeleteConfirmationDialog(context, index);
        break;
      case 'Play Next':
        player.playNextPlaylist({playlists[index]: playlistSongs[playlists[index]]});
        break;
      case 'Add to Queue':
        player.addToQueuePlaylist({playlists[index]: playlistSongs[playlists[index]]});
        break;
      case 'Download':
        player2.addPlaylistToDownloads({playlists[index]: playlistSongs[playlists[index]]});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Playlists',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cardo',
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (var i = 0; i < playlists.length; i++)
                PlaylistItem(
                  title: playlists[i],
                  caption: '${songCounts[playlists[i]]} Song${songCounts[playlists[i]] == 1 ? '' : 's'}',
                  itemBuilder: (context) => _buildMenuItems(context, i < 2),
                  onSelected: (value) => _handleMenuSelection(value, i),
                  isPermanent: songCounts[playlists[i]] == null,
                  playlistId: playlists[i],
                  songs: playlistSongs[playlists[i]] ?? [],
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          _showAddPlaylistDialog(context);
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class PlaylistItem extends StatelessWidget {
  final String title;
  final String caption;
  final PopupMenuItemBuilder<String> itemBuilder;
  final Function(String) onSelected;
  final bool isPermanent;
  final String playlistId;
  final List<dynamic> songs;

  const PlaylistItem({
    super.key,
    required this.title,
    required this.caption,
    required this.itemBuilder,
    required this.onSelected,
    this.isPermanent = false,
    required this.playlistId,
    required this.songs,
  });

  Future<String> _getImageUrl() async {
    if (songs.isEmpty) return 'assets/images/track.png';

    String lastSongId = songs.last;
    DocumentSnapshot songSnapshot = await FirebaseFirestore.instance.collection('SONGS').doc(lastSongId).get();
    if (songSnapshot.exists) {
      String imageUrl = songSnapshot['Image'] ?? '';
      return imageUrl.isNotEmpty ? imageUrl : 'assets/images/track.png';
    } else {
      return 'assets/images/track.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getImageUrl(),
      builder: (context, snapshot) {
        String imagePath = snapshot.data ?? 'assets/images/track.png';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackListScreen(playlistTitle: title,playlistId: playlistId),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: imagePath.startsWith('http')
                          ? NetworkImage(imagePath)
                          : AssetImage(imagePath) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Cardo',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4), // Adjust spacing between title and caption
                      Text(
                        caption,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                          fontFamily: 'Cardo', // Adjust color and style as needed
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPermanent)
                  PopupMenuButton<String>(
                    itemBuilder: itemBuilder,
                    onSelected: onSelected,
                    color: const Color(0xFF151515),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}