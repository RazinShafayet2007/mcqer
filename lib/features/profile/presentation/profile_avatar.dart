import 'dart:io';

import 'package:flutter/material.dart';

import '../../exams/domain/models.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    this.radius = 28,
  });

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imagePath = user.profileImagePath;
    final initials = _initials(user.name);

    if (imagePath != null && imagePath.isNotEmpty) {
      final provider = imagePath.startsWith('http') ? NetworkImage(imagePath) as ImageProvider : FileImage(File(imagePath));
      return CircleAvatar(
        radius: radius,
        backgroundImage: provider,
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(
        initials,
        style: TextStyle(fontSize: radius * 0.6, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
