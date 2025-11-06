import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';

class LoginController {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  Future<String?> login(String email, String password) async {
    try {
      await _firebaseAuthService.signIn(email: email, password: password);
      return null;
    } catch (e) {
      if (e is Exception) {
        return e.toString().replaceFirst('Exception: ', '');
      }
      return 'An unexpected error occurred.';
    }
  }
}
