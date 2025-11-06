import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_cloud_messaging.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

ValueNotifier<FirebaseAuthService> authService = ValueNotifier(
  FirebaseAuthService(),
);

class FirebaseAuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseCloudMessagingService fcmService =
      FirebaseCloudMessagingService();
  final FirestoreService firestoreService = FirestoreService();

  String? get currentUserId => firebaseAuth.currentUser?.uid;
  User? get currentUser => firebaseAuth.currentUser;

  Future<bool> isUserLoggedIn() async => firebaseAuth.currentUser != null;

  /// Fetch the current user's UID
  Future<String> getCurrentUserUid() async {
    return currentUser!.uid;
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      listenForCurrentUserFCMTokenRefresh();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign in failed.');
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }
  
  /// Create an account with email and password
  Future<UserCredential?> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      return await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Sign Out the current user
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  /// Forgot password
  Future<void> resetPassword({required String email}) async {
    return await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Update the current user's password
  Future<void> resetPasswordFromCurrentSession({
    required String oldPassword,
    required String newPassword,
  }) async {
    User? user = firebaseAuth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    await user.reauthenticateWithCredential(credential);

    return await user.updatePassword(newPassword);
  }

  /// Delete the current user's account
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  /// Get the current user's email
  Future<String?> getCurrentUserEmail() async {
    return firebaseAuth.currentUser?.email;
  }

  // Check current user fcm token and listen for token refresh
  Future<void> listenForCurrentUserFCMTokenRefresh() async {
    if (currentUser != null && currentUser!.uid.isNotEmpty) {
      final userDoc = firestoreService.getDocument(
        collection: 'users',
        docId: currentUser!.uid,
      );

      final userSnapshot = await userDoc;
      if (!userSnapshot.exists) return;

      final userData = userSnapshot.data();
      String? currentTokenInDb = userData?['fcmtoken'];

      final deviceToken = await fcmService.getToken();

      if (deviceToken != currentTokenInDb) {
        await firestoreService.updateDocument(
          collection: 'users',
          docId: currentUser!.uid,
          data: {'fcmtoken': deviceToken},
        );
      }

      fcmService.listenForTokenRefresh((newToken) async {
        if (newToken != deviceToken) {
          await firestoreService.updateDocument(
            collection: 'users',
            docId: currentUser!.uid,
            data: {'fcmtoken': newToken},
          );
        }
      });
    }
  }
}
