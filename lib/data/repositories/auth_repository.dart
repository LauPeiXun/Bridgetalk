import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firestore_service.dart';

import 'package:bridgetalk/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final String _collectionName = 'users';

  // Retrive the user profile
  Future<UserModel?> getUserProfile(String uid) {
    return _firestoreService
        .getDocument(collection: _collectionName, docId: uid)
        .then((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  //Check for username register is no duplicate
  Future<bool> isUsernameDuplicate(String username) async {
    final querySnapshot = await _firestoreService.getCollection(
      _collectionName,
    );

    final input = username.trim().toLowerCase();

    for (final doc in querySnapshot.docs) {
      final existingUsername = doc['username']?.toString().trim().toLowerCase();
      if (existingUsername == input) {
        return true;
      }
    }

    return false;
  }

  // Fetch the current user's UID
  Future<String> getCurrentUserUid() async {
    return _authService.getCurrentUserUid();
  }

  // Update the username
  Future<void> updateUsername({required String username}) async {
    if (_authService.currentUser == null) return;

    await _firestoreService.updateDocument(
      collection: _collectionName,
      docId: _authService.currentUser!.uid,
      data: {'username': username},
    );
  }

  // Update the user profile
  Future<void> createUserProfile(UserModel user) async {
    final String uid = await getCurrentUserUid();
    if (uid.isNotEmpty) {
      await _firestoreService.setModel(
        collection: _collectionName,
        docId: uid,
        model: user,
        toMap: (user) => user.toMap(),
      );
    }
  }
}
