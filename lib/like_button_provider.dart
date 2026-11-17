import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikeButtonProvider with ChangeNotifier {
  final Set<String> _likedSongs = {};
  late final String userId;

  LikeButtonProvider(this.userId);

  bool isLiked(String songId) {
    return _likedSongs.contains(songId);
  }

  Future<void> fetchLikedSongs() async {
    try {
      final likedPlaylistDoc = await FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('PLAYLISTS')
          .doc('Liked Songs')
          .get();

      if (likedPlaylistDoc.exists) {
        final likedPlaylistData = likedPlaylistDoc.data();
        if (likedPlaylistData != null && likedPlaylistData.containsKey('songs')) {
          _likedSongs.clear();
          _likedSongs.addAll(List<String>.from(likedPlaylistData['songs']));
        }
      } else {
        // Create Liked Songs playlist if it doesn't exist
        await _createLikedSongsPlaylist();
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching liked songs: $e');
      }
    }
  }

  Future<void> toggleLike(String songId) async {
    if (_likedSongs.contains(songId)) {
      _likedSongs.remove(songId);
    } else {
      _likedSongs.add(songId);
    }

    try {
      await _updateLikedSongsPlaylist();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating liked status: $e');
      }
    }
    notifyListeners();
  }

  Future<void> addSongToLiked(String songId) async {
    if (!_likedSongs.contains(songId)) {
      _likedSongs.add(songId);

      try {
        await _updateLikedSongsPlaylist();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error adding song to liked songs: $e');
        }
      }
    }
  }

  Future<void> _createLikedSongsPlaylist() async {
    try {
      await FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('PLAYLISTS')
          .doc('Liked Songs')
          .set({'songs': []});
    } catch (e) {
      if (kDebugMode) {
        print('Error creating Liked Songs playlist: $e');
      }
    }
  }

  Future<void> _updateLikedSongsPlaylist() async {
    try {
      final playlistRef = FirebaseFirestore.instance
          .collection('USER')
          .doc(userId)
          .collection('PLAYLISTS')
          .doc('Liked Songs');

      await playlistRef.set({
        'songs': _likedSongs.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating Liked Songs playlist: $e');
      }
    }
  }
}
