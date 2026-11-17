import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_page.dart';
import 'firebase_player_page.dart'; // Import MyPlayerPage
import 'player_provider.dart';

class PlayerControls extends StatefulWidget {
  const PlayerControls({super.key});

  @override
  PlayerControlsState createState() => PlayerControlsState();
}

class PlayerControlsState extends State<PlayerControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isVisible = true;
  bool get isVisible => _isVisible;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(_controller);
  }

  void _slidePlayerControls() {
    setState(() {
      _isVisible = !_isVisible;
    });
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  void stopControl() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPlayerPage(BuildContext context, PlayerProvider player) {
    // Show PlayerPage in modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerPage(
        localSongs: player.playlist,// Pass widget.firebaseSongs to MyPlayerPage
        initialIndex: player.currentIndex,
        isResuming: false,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_isVisible)
          Positioned(
            right: 10,
            bottom: 10,
            child: FloatingActionButton(
              onPressed: _slidePlayerControls,
              backgroundColor: Colors.grey,
              child: const Icon(Icons.music_note, color: Colors.black),
            ),
          ),
        Consumer<PlayerProvider>(
          builder: (context, player, child) {
            return Visibility(
              visible: player.isPlaying || player.isPause,
              child: SlideTransition(
                position: _offsetAnimation,
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      // User swiped Right
                      player.stop();
                      _slidePlayerControls();
                    }
                  },
                  onTap: () => _showPlayerPage(context, player),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: const Color(0xFF262525),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            player.currentImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                player.currentImage!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/track.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ClipRect(
                                      child: SizedBox(
                                        child: Text(
                                          player.currentTitle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5), // Adjust spacing as needed
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ClipRect(
                                      child: SizedBox(
                                        width: 150, // Example width limit
                                        child: Text(
                                          player.currentArtist,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                color: player.isShuffling ? Colors.green : Colors.white,
                              ),
                              onPressed: () {
                                player.toggleShuffle();
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                player.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                player.isPlaying ? player.pause() : player.resume();
                              },
                            ),
                          ],
                        ),
                        Slider(
                          activeColor: Colors.white,
                          inactiveColor: Colors.grey,
                          value: player.currentPosition.inSeconds.toDouble(),
                          max: player.songDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            player.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}