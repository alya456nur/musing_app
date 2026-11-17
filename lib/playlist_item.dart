import 'package:flutter/material.dart';

class PlaylistItem extends StatelessWidget {
  final dynamic imagePath;
  final String title;
  final String caption;
  final Function onTap;
  final Function onPlay;
  final Function(String) onSelected;
  final List<PopupMenuEntry<String>> Function(BuildContext) itemBuilder;

  const PlaylistItem({
    super.key,
    required this.imagePath,
    required this.title,
    required this.caption,
    required this.onTap,
    required this.onPlay,
    required this.onSelected,
    required this.itemBuilder,
  });

  Widget _buildLeadingWidget() {
    if (imagePath is String && (imagePath.startsWith('http://') || imagePath.startsWith('https://'))) {
      // Network image URL
      return Image.network(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else if (imagePath is String) {
      // Local asset image
      return Image.asset(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else if (imagePath is Uri) {
      // Network image URI (e.g., data:image/jpeg;base64,...)
      return Image.network(
        imagePath.toString(),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else {
      // Default image if none of the above cases match
      return Image.asset(
        'assets/default_image.png',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeadingWidget(),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        caption,
        style: const TextStyle(
          color: Colors.white70,
        ),
      ),
      onTap: () => onTap(),
      trailing: PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: itemBuilder,
        color: const Color(0xFF262525),
      ),
    );
  }
}
