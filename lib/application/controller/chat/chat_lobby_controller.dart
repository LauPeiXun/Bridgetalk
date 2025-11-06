import 'package:bridgetalk/data/models/user_model.dart';
import 'package:bridgetalk/data/repositories/chat_repository.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_cloud_messaging.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';

class ChatLobbyController {
  final ChatRepository _chatRepository = ChatRepository();
  final UserRepository _userRepository = UserRepository();

  Stream<List<Map<String, dynamic>>> getUserStream() async* {
    List<String> targetUserIds = await getTargetUserIds();
    if (targetUserIds.isEmpty) return;
    yield* _chatRepository.streamTargetUsers(targetUserIds);
  }

  Future<UserModel?> getCurrentUserModel() async {
    UserModel? userData = await _userRepository.getCurrentUserModel();
    return userData;
  }

  Future<List<String>> getTargetUserIds() async {
    List<String> targetUserIds = [];
    UserModel? userData = await getCurrentUserModel();
    if (userData == null) return targetUserIds;

    // If user is a Parent, get their children IDs
    if (userData.role == "Parent") {
      targetUserIds = List<String>.from(userData.childrenIds ?? []);
    }
    // If user is a Child, get their Father and/or Mother IDs
    else if (userData.role == "Child") {
      if ((userData.fatherId ?? "").isNotEmpty) {
        targetUserIds.add(userData.fatherId!);
      }
      if ((userData.motherId ?? "").isNotEmpty) {
        targetUserIds.add(userData.motherId!);
      }
    }
    return targetUserIds;
  }

  void requestNotificationPermission() {
    FirebaseCloudMessagingService().requestNotificationPermission();
  }

  void initializeFirebaseMessaging() {
    FirebaseCloudMessagingService().initializeFirebaseMessaging();
  }
}
