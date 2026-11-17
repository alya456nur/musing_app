import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DownloadProvider with ChangeNotifier {
  final Set<String> _downloadSongs = {};
  late final String userId;

  DownloadProvider(this.userId);

  bool isDownloaded(String songId) {
    return _downloadSongs.contains(songId);
  }

  Future<void> fetchDownloadsSongs() async {
    try {
      final downloadPlaylistDoc = await FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('PLAYLISTS')
          .doc('Downloads')
          .get();

      if (downloadPlaylistDoc.exists) {
        final downloadPlaylistData = downloadPlaylistDoc.data();
        if (downloadPlaylistData != null && downloadPlaylistData.containsKey('songs')) {
          _downloadSongs.clear();
          _downloadSongs.addAll(List<String>.from(downloadPlaylistData['songs']));
        }
      } else {
        // Create Downloads playlist if it doesn't exist
        await _createDownloadsPlaylist();
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching downloaded songs: $e');
      }
    }
  }

  Future<void> toggleDownload(BuildContext context, String songId) async {
    if (_downloadSongs.contains(songId)) {
      // Show a confirmation dialog before removing the download
      bool confirmRemove = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black, // Set background color to black
            title: const Text(
              'Remove Download',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            content: const Text(
              'Are you sure you want to remove this song from downloads?',
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false); // Return false to indicate cancel
                },
              ),
              TextButton(
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true); // Return true to indicate confirmation
                },
              ),
            ],
          );
        },
      );

      if (confirmRemove == true) {
        _downloadSongs.remove(songId);
      }
    } else {
      _downloadSongs.add(songId);
    }

    try {
      await _updateDownloadsPlaylist();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating download status: $e');
      }
    }
  }

  Future<void> addSongToDownloads(String songId) async {
    if (!_downloadSongs.contains(songId)) {
      _downloadSongs.add(songId);

      try {
        await _updateDownloadsPlaylist();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error adding song to downloaded songs: $e');
        }
      }
    }
  }

  Future<void> addPlaylistToDownloads(Map<String, List<dynamic>> songIds) async {
    bool addedAnySong = false;

    // Iterate over entries of the songIds map
    for (var entry in songIds.entries) {
      String playlistId = entry.key;
      List<dynamic> songs = entry.value;

      for (var songId in songs) {
        if (!_downloadSongs.contains(songId)) {
          _downloadSongs.add(songId);
          addedAnySong = true;
        }
      }
    }

    if (addedAnySong) {
      try {
        await _updateDownloadsPlaylist();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error adding playlist to downloaded songs: $e');
        }
      }
    }
  }

  Future<void> _createDownloadsPlaylist() async {
    try {
      await FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('PLAYLISTS')
          .doc('Downloads')
          .set({'songs': []});
    } catch (e) {
      if (kDebugMode) {
        print('Error creating Downloads playlist: $e');
      }
    }
  }

  Future<void> _updateDownloadsPlaylist() async {
    try {
      final playlistRef = FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('PLAYLISTS')
          .doc('Downloads');

      await playlistRef.set({
        'songs': _downloadSongs.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating Downloads playlist: $e');
      }
    }
  }

  Future<void> clearDownloads() async {
    _downloadSongs.clear();
    try {
      await _updateDownloadsPlaylist();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing downloads: $e');
      }
    }
  }
}
