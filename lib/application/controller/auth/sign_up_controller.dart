import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_cloud_messaging.dart';
import 'package:bridgetalk/data/repositories/auth_repository.dart';
import 'package:bridgetalk/data/models/user_model.dart';

class SignUpController {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final AuthRepository _authRepo = AuthRepository();
  final FirebaseCloudMessagingService _cloudMessagingService =
      FirebaseCloudMessagingService();

  Future<String?> registerUser({
    required String email,
    required String password,
    required String username,
    required String role,
    required String gender,
  }) async {
    try {
      final userCredential = await _firebaseAuthService.createAccount(
        email: email,
        password: password,
      );

      if (userCredential == null) {
        throw Exception('User creation failed.');
      }

      final uid = userCredential.user?.uid;

      final fcmToken = await _cloudMessagingService.getToken();

      late UserModel newUser;

      if (role == 'Parent') {
        newUser = UserModel(
          uid: uid,
          email: email,
          username: username,
          role: role,
          gender: gender,
          fcmToken: fcmToken,
          childrenIds: [],
          createdAt: DateTime.now(),
        );
      } else {
        newUser = UserModel(
          uid: uid,
          email: email,
          username: username,
          role: role,
          gender: gender,
          fcmToken: fcmToken,
          fatherId: null,
          motherId: null,
          createdAt: DateTime.now(),
        );
      }

      await _authRepo.createUserProfile(newUser);
    } catch (e) {
      return e.toString();
    }
    return null;
  }

  //Check for username register is no duplicate
  Future<bool> isUsernameDuplicate(String username) async {
    return await _authRepo.isUsernameDuplicate(username);
  }
}
