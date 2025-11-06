import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';

class ResetPasswordController {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  Future<void> resetPassword(String oldPassword, String newPassword) async {
    if (oldPassword != newPassword) {
      await _firebaseAuthService.resetPasswordFromCurrentSession(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    }
  }
}
