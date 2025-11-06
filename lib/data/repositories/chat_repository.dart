import 'package:bridgetalk/Insfrastructure/firebase_services/firestore_service.dart';
import 'package:bridgetalk/data/models/message_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class ChatRepository {
  final FirestoreService _firestoreService = FirestoreService();

  final chatRoomColletion = 'chat_rooms';
  final messageCollection = 'messages';

  Future<void> sendMessage({
    required String chatRoomId,
    required Message message,
  }) async {
    await _firestoreService.addDataByPath(
      pathSegments: [chatRoomColletion, chatRoomId, messageCollection],
      data: message.toMap(),
    );
  }

  /// Fetch messages from a specific chat room
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestoreService.getDataByPath(
      pathSegments: [chatRoomColletion, chatRoomId, messageCollection],
      orderByField: 'timestamp',
      descending: false,
    );
  }

  Stream<List<Map<String, dynamic>>> streamTargetUsers(
    List<String> targetUserIds,
  ) {
    if (targetUserIds.isEmpty) {
      return Stream.value(<Map<String, dynamic>>[]);
    }

    // Stream user documents from Firestore
    return _firestoreService
        .streamCollection(
          collection: 'users',
          queryBuilder: (q) => q.where('uid', whereIn: targetUserIds),
        )
        .switchMap((userSnapshot) {
          final userDocs = userSnapshot.docs;
          final userStreams = userDocs.map((doc) {
            final userData = doc.data();
            final uid = userData['uid'];

            // Stream the latest mood for each user
            final moodStream = _firestoreService
                .streamCollection(
                  collection: 'users/$uid/moods',
                  queryBuilder:
                      (q) => q.orderBy('timestamp', descending: true).limit(1),
                )
                .map((moodSnap) {
                  final moodDoc =
                      moodSnap.docs.isNotEmpty
                          ? moodSnap.docs.first.data()
                          : {};

                  userData['emoji'] = moodDoc['emoji'] ?? '😶';
                  userData['mood'] = moodDoc['mood'] ?? '';
                  return userData;
                });

            return moodStream;
          });

          // Combine all mood streams into one stream of list
          return Rx.combineLatestList(userStreams);
        });
  }

  /// Delete a message from the chat room
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _firestoreService.deleteDataByPath(
      pathSegments: [
        chatRoomColletion,
        chatRoomId,
        messageCollection,
        messageId,
      ],
    );
  }
}
