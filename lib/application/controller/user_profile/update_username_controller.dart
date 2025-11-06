import 'package:bridgetalk/data/repositories/auth_repository.dart';

class UpdateUsernameController {
  final AuthRepository _authRepository = AuthRepository();
  Future<void> updateUsername(String username) {
    return _authRepository.updateUsername(username: username);
  }

  Future<bool> isUsernameDuplicate(String username) async {
    return await _authRepository.isUsernameDuplicate(username);
  }
}
