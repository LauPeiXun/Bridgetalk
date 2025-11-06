import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';

class ForgotPasswordController {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  Future<String?> forgotPassword(String email) async {
    try {
      await _firebaseAuthService.resetPassword(email: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
