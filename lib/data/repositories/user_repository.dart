import 'dart:io';
import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_storage_service.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firestore_service.dart';
import 'package:bridgetalk/data/models/mood_model.dart';

import 'package:bridgetalk/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final String _collectionName = 'users';
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  final String _userProfileImagePath = 'user_profile_image';
  final FirebaseStorageService _firebaseStorageService =
      FirebaseStorageService();

  Future<void> uploadProfilePicture(String uid, File imageFile) async {
    await _firebaseStorageService.uploadImage(
      _userProfileImagePath,
      '$uid.png',
      imageFile,
    );
  }

  Future<String?> getProfileImageUrl(String uid) async {
    return await _firebaseStorageService.getImage(
      _userProfileImagePath,
      '$uid.png',
    );
  }

  Future<UserModel?> getCurrentUserModel() async {
    return await _firestoreService
        .getDocument(
          collection: _collectionName,
          docId: _firebaseAuthService.currentUserId!,
        )
        .then((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  Future<UserModel?> getUserById(String uid) async {
    return await _firestoreService
        .getDocument(collection: _collectionName, docId: uid)
        .then((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  Future<String?> getCurrentUsername(String uid) async {
    return await _firestoreService
        .getDocument(collection: _collectionName, docId: uid)
        .then((snapshot) {
          if (snapshot.exists) {
            return snapshot.data()!['username'];
          }
          return null;
        });
  }

  Future<MoodModel?> getCurrentUserMood() async {
    final uid = _firebaseAuthService.currentUserId!;

    try {
      final snapshots =
          await _firestoreService
              .getDataByPath(
                pathSegments: [_collectionName, uid, 'moods'],
                orderByField: 'timestamp',
                descending: true,
              )
              .first;

      if (snapshots.docs.isNotEmpty) {
        return MoodModel.fromMap(
          snapshots.docs.first.data() as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching mood: $e');
      }
      return null;
    }
  }
}
