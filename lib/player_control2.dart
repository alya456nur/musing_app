import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_player_page.dart';
import 'my_player.dart';

class PlayerControls2 extends StatefulWidget {
  const PlayerControls2({super.key});

  @override
  PlayerControls2State createState() => PlayerControls2State();
}

class PlayerControls2State extends State<PlayerControls2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isVisible = true;

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

  void _showPlayerPage(BuildContext context, MyPlayerProvider player) {
    // Show PlayerPage in modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MyPlayerPage(
        firebaseSongs: player.playlist,
        initialIndex: player.currentIndex,
        isResuming: true, // Set to true to resume playback
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        Consumer<MyPlayerProvider>(
          builder: (context, player, child) {
            return Visibility(
              visible: player.isPlaying || player.isPause,
              child: SlideTransition(
                position: _offsetAnimation,
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      // User swiped Right
                      _slidePlayerControls();
                      player.stopSong();
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: Image(
                                  image: NetworkImage(player.currentImage),
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
                                  const SizedBox(height: 5),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ClipRect(
                                      child: SizedBox(
                                        width: 150,
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
                                player.shuffleSongs();
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
