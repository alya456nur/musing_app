import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'playlist_item.dart';
import 'player_page.dart';
import 'player_provider.dart';
import 'player_controls.dart'; // Import the PlayerControls widget

class LocalScreen extends StatefulWidget {
  const LocalScreen({super.key});

  @override
  State<LocalScreen> createState() => _LocalScreenState();
}

class _LocalScreenState extends State<LocalScreen> {
  final ScrollController _scrollController = ScrollController();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<MySongModel> _songs = [];
  int _currentSongIndex = -1; // Track the index of the currently playing song

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadSongs();
  }

  Future<void> _requestPermissionAndLoadSongs() async {
    final status = await Permission.audio.request();
    if (status.isGranted) {
      await _loadSongs();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      _showPermissionRequestDialog();
    }
  }

  Future<void> _loadSongs() async {
    try {
      List<SongModel> songModels = await _audioQuery.querySongs();
      List<MySongModel> songs = songModels.map((song) => MySongModel.fromSongModel(song)).toList();
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error loading songs: $e");
      }
    }
  }

  Future<String> _getImagePath(MySongModel song) async {
    final artwork = await _audioQuery.queryArtwork(song.id, ArtworkType.AUDIO);
    if (artwork != null && artwork.isNotEmpty) {
      return 'data:image/jpeg;base64,${base64Encode(artwork)}';
    } else {
      return 'assets/images/track.png';
    }
  }

  Future<void> _playSong(MySongModel song, int index) async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    String? filePath = await _getFilePathFromUri(song.uri!);

    if (filePath != null) {
      try {
        // Set playlist and play song
        player.setPlaylist(_songs, index);
        await player.playSong(song, index);

        setState(() {
          _currentSongIndex = index;
        });

        // Show PlayerPage in modal bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PlayerPage( // Add firebaseSongs if needed
            localSongs: _songs,
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
    } else {
      if (kDebugMode) {
        print("File path is null for URI ${song.uri}");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to play song: File path is invalid')),
      );
    }
  }

  Future<String?> _getFilePathFromUri(String uri) async {
    try {
      File file = await toFile(uri);
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching file path for URI $uri: $e");
      }
      return null;
    }
  }

  void _showPermissionRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('Storage permission is required to access songs. Please grant the permission.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final status = await Permission.audio.request();
                if (status.isGranted) {
                  await _loadSongs();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Storage permission is required to access songs.')),
                  );
                }
              },
              child: const Text('Grant Permission'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(String value, MySongModel song) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    switch (value) {
      case 'Play Next':
        player.playNext(song);
        break;
      case 'Add To Queue':
        player.addToQueue(song);
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Local Songs',
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
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      for (var i = 0; i < _songs.length; i++)
                        FutureBuilder<String>(
                          future: _getImagePath(_songs[i]),
                          builder: (context, snapshot) {
                            final imagePath = snapshot.data ?? 'assets/images/track.png';
                            return PlaylistItem(
                              imagePath: imagePath,
                              title: _songs[i].title,
                              caption: _songs[i].artist ?? 'Unknown Artist',
                              itemBuilder: _buildMenuItems,
                              onTap: () {
                                if (_songs[i].uri != null) {
                                  _playSong(_songs[i], i);
                                }
                              },
                              onPlay: () {
                                // This function will be called when "Play" action is triggered in PlaylistItem
                                _playSong(_songs[i], i);
                              },
                              onSelected: (String value) {
                                _handleMenuAction(value, _songs[i]);
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PlayerControls(), // PlayerControls widget at the bottom
          ),
        ],
      ),
    );
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
    ];
  }
}
