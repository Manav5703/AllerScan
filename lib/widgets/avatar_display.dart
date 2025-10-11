import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class AvatarDisplay extends StatelessWidget {
  final UserProfile? profile;
  final double size;
  final Color? backgroundColor;

  const AvatarDisplay({
    super.key,
    required this.profile,
    this.size = 60,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.teal.shade100;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: _buildAvatarContent(),
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Priority: Custom photo > Emoji > Default icon
    if (profile?.hasCustomPhoto() == true) {
      return Image.file(
        File(profile!.avatarPhotoPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to emoji or default if image fails to load
          return _buildEmojiOrDefault();
        },
      );
    }
    
    return _buildEmojiOrDefault();
  }

  Widget _buildEmojiOrDefault() {
    if (profile?.avatarEmoji != null) {
      return Center(
        child: Text(
          profile!.avatarEmoji!,
          style: TextStyle(fontSize: size * 0.5),
        ),
      );
    }
    
    // Default icon
    return Center(
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.teal.shade600,
      ),
    );
  }
}
