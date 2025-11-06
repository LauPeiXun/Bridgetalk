import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_cloud_messaging.dart';
import 'package:bridgetalk/data/models/user_model.dart';
import 'package:bridgetalk/data/repositories/auth_repository.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';

class SosController {
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  final FirebaseCloudMessagingService firebaseCloudMessagingService =
      FirebaseCloudMessagingService();

  String sosTopic = '';

  Future<bool> sendSOSNotification({
    required String recipient,
    required String mood,
    required String message,
  }) async {
    try {
      String? senderUid = await _authRepo.getCurrentUserUid();

      if (senderUid.isEmpty) {
        if (kDebugMode) {
          print('Sender UID is null or empty');
        }
        return false;
      }
      // Get the user profile
      UserModel? sender = await _authRepo.getUserProfile(senderUid);

      if (sender == null) {
        if (kDebugMode) {
          print('Sender profile not found');
        }
        return false;
      }

      String motherId = sender.motherId ?? '';
      String fatherId = sender.fatherId ?? '';

      if (recipient == 'Mother') {
        await _sendNotificationToParent(motherId, sender, message, mood);
      } else if (recipient == 'Father') {
        await _sendNotificationToParent(fatherId, sender, message, mood);
      } else if (recipient == 'Both') {
        await _sendNotificationToParent(motherId, sender, message, mood);
        await _sendNotificationToParent(fatherId, sender, message, mood);
      } else {
        if (kDebugMode) {
          print('Invalid recipient type: $recipient');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending SOS notification: $e');
      }
      return false;
    }

    return true;
  }

  // Method to send notification to a parent
  Future<void> _sendNotificationToParent(
    String parentId,
    UserModel sender,
    String message,
    String mood,
  ) async {
    if (parentId.isEmpty) return;

    if (message.isEmpty) {
      message = " ";
    }

    UserModel? parent = await _authRepo.getUserProfile(parentId);

    if (parent != null && parent.fcmToken != null) {
      await sendNotification(
        title: '[${sender.username}] is Feeling $mood, Please Respond',
        body: message,
        targetFcmToken: parent.fcmToken!,
      );
    } else {
      if (kDebugMode) {
        print('Parent with ID $parentId not found or FCM token is null');
      }
    }
  }

  Future<void> sendNotification({
    required String targetFcmToken,
    required String title,
    required String body,
  }) async {
    await firebaseCloudMessagingService.sendNotification(
      targetFcmToken: targetFcmToken,
      title: title,
      body: body,
    );
  }

  Future<UserModel?> getUserData() async {
    UserModel? userModel = await _userRepository.getCurrentUserModel();
    return userModel;
  }
}
