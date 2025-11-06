import 'dart:io';

import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_vertex_ai.dart';
import 'package:bridgetalk/data/models/message_model.dart';
import 'package:bridgetalk/data/models/user_model.dart';
import 'package:bridgetalk/data/repositories/chat_repository.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatRoomController {
  final ChatRepository _chatRepository = ChatRepository();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseVertextAi firebaseVertextAi = FirebaseVertextAi();

  // Fetch User list
  Stream<List<Map<String, dynamic>>> getUserStream() async* {
    final userData = await _userRepository.getCurrentUserModel();
    if (userData == null) return;

    List<String> targetUserIds = [];

    if (userData.role == "Parent") {
      targetUserIds = List<String>.from(userData.childrenIds ?? []);
    } else if (userData.role == "Child") {
      if ((userData.fatherId ?? "").toString().isNotEmpty) {
        targetUserIds.add(userData.fatherId!);
      }
      if ((userData.motherId ?? "").toString().isNotEmpty) {
        targetUserIds.add(userData.motherId!);
      }
    }

    if (targetUserIds.isEmpty) return;

    yield* _chatRepository.streamTargetUsers(targetUserIds);
  }

  Future<void> sendMessage({
    String? recipientId,
    String? chatRoomId,
    required String message,
  }) async {
    final String currentUserID = await _authService.getCurrentUserUid();
    final Timestamp timestamp = Timestamp.now();

    // 1️⃣ 如果传入 recipientId（个人聊天）
    if (recipientId != null) {
      final newMessage = Message(
        senderId: currentUserID,
        receiverId: recipientId,
        message: message,
        timestamp: timestamp.toString(),
      );

      final chatRoomId = await getChatRoomId(recipientId);
      await _chatRepository.sendMessage(
        chatRoomId: chatRoomId,
        message: newMessage,
      );

      // ✨ SparkPoint update
      await _updateSparkOnChat(currentUserID, recipientId);
    }
    //
    else if (chatRoomId != null) {
      final newMessage = Message(
        senderId: currentUserID,
        message: message,
        timestamp: timestamp.toString(),
      );
      await _chatRepository.sendMessage(
        chatRoomId: chatRoomId,
        message: newMessage,
      );
    }
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(
    String? otherUserId,
    String? chatRoomId,
  ) async {
    if (otherUserId != null && chatRoomId == null) {
      chatRoomId = await getChatRoomId(otherUserId);
    }
    return _chatRepository.getMessages(chatRoomId!);
  }

  Future<UserModel?> getCurrentUserModel() async {
    return await _userRepository.getCurrentUserModel();
  }

  Future<void> deleteMessage(otherUserId, messageId) async {
    String chatRoomId = await getChatRoomId(otherUserId);
    await _chatRepository.deleteMessage(chatRoomId, messageId);
  }

  Future<void> deleteMessageFromGroup(groupChatRoomId, messageId) async {
    await _chatRepository.deleteMessage(groupChatRoomId, messageId);
  }

  Future<String> getChatRoomId(String otherUserId) async {
    UserModel? currentUserModel = await _userRepository.getCurrentUserModel();

    List<String> ids = [currentUserModel!.uid!, otherUserId];
    ids.sort();

    return ids.join("_");
  }

  Future<void> uploadProfilePicture(String uid, File imageFile) async {
    await _userRepository.uploadProfilePicture(uid, imageFile);
  }

  Future<String?> getProfileImageUrl(String uid) async {
    return await _userRepository.getProfileImageUrl(uid);
  }

  Future<void> _updateSparkOnChat(String senderId, String receiverId) async {
    final connectionsRef = FirebaseFirestore.instance.collection('connections');

    final connectionQuery =
        await connectionsRef
            .where('childId', whereIn: [senderId, receiverId])
            .where('parentId', whereIn: [senderId, receiverId])
            .get();

    for (final doc in connectionQuery.docs) {
      final data = doc.data();
      final lastChat = data['lastChat']?.toDate();
      final now = DateTime.now();

      // 如果今天已经更新过 spark 就跳过
      if (lastChat != null &&
          lastChat.year == now.year &&
          lastChat.month == now.month &&
          lastChat.day == now.day) {
        continue;
      }

      final currentSpark = data['sparkPoint'] ?? 0;

      await connectionsRef.doc(doc.id).update({
        'sparkPoint': currentSpark + 5,
        'lastChat': Timestamp.now(),
      });
    }
  }

  Future<String?> generateProfanityWordResult(
    String message,
    mood,
    emoji,
    role,
    List<String> profanityWordContain,
  ) async {
    try {
      String? senderRole, receiverRole;
      if (role.toLowerCase() == 'child') {
        receiverRole = 'Child';
        senderRole = 'Parent';
      } else if (role.toLowerCase() == 'parent') {
        receiverRole = 'Parent';
        senderRole = 'Child';
      }

      final promptText = '''
A $senderRole wrote the following message to their $receiverRole:

"$message"

And current $receiverRole mood: $mood
also Profanity Word Detected : ${profanityWordContain.join(', ')}

Please respond in  as follows:

Your $role mood :  $emoji $mood
Profanity Word Detected : ${profanityWordContain.join(', ')}

How This Might Affect Your $role: Describe how the $senderRole message might affect the $receiverRole emotional state, especially considering the current mood: "$mood". Explain the possible reactions or feelings the $receiverRole may experience. Make sure to communicate as if you're talking to a friend, being kind and empathetic also the result should be around 40 words only and just one paragraph is enough."

Please make sure have line break between each paragraph. Keep the tone warm and conversational, as if you're giving advice to a friend. Avoid using '*', and follow only the format given. Do not add any titles like "Here's the breakdown" or summaries at the bottom also not numbering.
''';

      String aiResponse = await firebaseVertextAi.processPrompt(promptText);

      return aiResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating suggestion: $e');
      }
      return null;
    }
  }

  Future<String?> generateProfanityWordSuggestion(
    String message,
    receiverMood,
    emoji,
    role,
    List<String> profanityWordContain,
  ) async {
    try {
      String? senderRole, receiverRole;
      if (role.toLowerCase() == 'child') {
        receiverRole = 'Child';
        senderRole = 'Parent';
      } else if (role.toLowerCase() == 'parent') {
        receiverRole = 'Parent';
        senderRole = 'Child';
      }

      final promptText = '''
A $senderRole wrote the following message to their $receiverRole:

"$message"

Profanity words detected in the message: ${profanityWordContain.join(', ')}

The $receiverRole's current emotional state is: "$receiverMood"

Please provide only a revised version of the message that is more emotionally supportive and appropriate for healthy communication between a $senderRole and a $receiverRole. The revised message must:

- Acknowledge the $receiverRole's mood using empathetic language, such as "I know you're feeling...", "I understand you're going through...", or similar.
- Avoid using any gendered terms (e.g., mom, dad, son, daughter).
- Maintain the original intent of the message.
- Be respectful, clear, and easy to understand.
- Reflect a suitable tone for a $senderRole speaking to a $receiverRole (not like a friend).
- Contain **minimum 10 words**.

Respond with only the revised message. Do not include any explanations, labels, summaries, or formatting. Just return the improved message.
''';

      String aiResponse = await firebaseVertextAi.processPrompt(promptText);

      return aiResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating suggestion: $e');
      }
      return null;
    }
  }
}
