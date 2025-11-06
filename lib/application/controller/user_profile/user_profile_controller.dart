import 'dart:io';
import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';
import 'package:bridgetalk/data/models/mood_model.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';
import 'package:bridgetalk/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';

class UserProfileController {
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  Future<void> uploadCurrentUserProfilePicture(File imageFile) async {
    String? uid = await getCurrentUserId();
    if (uid != null) {
      await _userRepository.uploadProfilePicture(uid, imageFile);
    }
  }

  Future<String?> getCurrentUserProfileImageUrl() async {
    String? uid = await getCurrentUserId();
    if (uid != null) {
      return await _userRepository.getProfileImageUrl(uid);
    }
    return null;
  }

  Future<String?> getProfileImageUrl(String uid) async {
    return await _userRepository.getProfileImageUrl(uid);
  }

  Future<void> signOut(BuildContext context) async {
    await _firebaseAuthService.signOut();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<String?> getCurrentUsername() async {
    final String? uid = _firebaseAuthService.currentUser?.uid;
    if (uid != null) {
      return await _userRepository.getCurrentUsername(uid);
    } else {
      return null;
    }
  }

  Future<String?> getCurrentUserId() async {
    return _firebaseAuthService.currentUser?.uid;
  }

  Future<MoodModel?> getCurrentUserMood() async {
    return await _userRepository.getCurrentUserMood();
  }
}
