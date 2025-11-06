import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bridgetalk/data/models/parent_link_model.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firestore_service.dart';

class ParentLinkRepository {
  final FirestoreService _firestoreService;

  ParentLinkRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  // CRUD: Read user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestoreService.getDocument(
      collection: 'users',
      docId: userId,
    );
    return doc.data();
  }

  // CRUD: Read connections
  Future<List<ParentLinkModel>> getConnections(String parentId) async {
    final querySnapshot = await _firestoreService
        .streamCollection(
          collection: 'connections',
          queryBuilder: (query) => query.where('parentId', isEqualTo: parentId),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    List<ParentLinkModel> connections = [];
    for (var doc in querySnapshot.docs) {
      try {
        final data = doc.data();
        final childId = data['childId']?.toString();

        if (childId == null) {
          continue;
        }

        final childDoc = await _firestoreService.getDocument(
          collection: 'users',
          docId: childId,
        );

        if (childDoc.exists) {
          final childData = childDoc.data();
          connections.add(
            ParentLinkModel.fromMap({
              ...data,
              'childUsername': childData?['username'],
            }, doc.id),
          );
        }
      } catch (e) {
        continue;
      }
    }
    return connections;
  }

  // CRUD: Read received requests
  Future<List<Map<String, dynamic>>> getReceivedRequests(
    String receiverId,
  ) async {
    final querySnapshot = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('receiverId', isEqualTo: receiverId.trim())
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    return querySnapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
  }

  // CRUD: Read sent requests
  Future<List<Map<String, dynamic>>> getSentRequests(String senderID) async {
    final querySnapshot = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('senderId', isEqualTo: senderID.trim())
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    return querySnapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
  }

  // CRUD: Read users
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (final doc in querySnapshot.docs) {
        doc.data();
      }

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // CRUD: Read user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final querySnapshot = await _firestoreService
        .streamCollection(
          collection: 'users',
          queryBuilder: (query) => query.where('username', isEqualTo: username),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    if (querySnapshot.docs.isEmpty) return null;
    final doc = querySnapshot.docs.firstWhere(
      (snapshot) => !snapshot.metadata.isFromCache,
    );
    return {...doc.data(), 'id': doc.id};
  }

  // CRUD: Create connection
  Future<void> createConnection({
    required String childId,
    required String parentId,
    required String parentRole,
  }) async {
    await _firestoreService.addData(
      collection: 'connections',
      data: {
        'childId': childId,
        'parentId': parentId,
        'parentRole': parentRole,
        'sparkPoint': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await _firestoreService.updateDocument(
      collection: "users",
      docId: parentId,
      data: {
        "childrenIds": FieldValue.arrayUnion([childId]),
      },
    );

    if (parentRole == 'father') {
      await _firestoreService.updateDocument(
        collection: "users",
        docId: childId,
        data: {"FatherId": parentId},
      );
    } else if (parentRole == 'mother') {
      await _firestoreService.updateDocument(
        collection: "users",
        docId: childId,
        data: {"MotherId": parentId},
      );
    }
  }

  // CRUD: Read request by ID
  Future<Map<String, dynamic>?> getRequestById(String requestId) async {
    final doc = await _firestoreService.getDocument(
      collection: 'connection_requests',
      docId: requestId,
    );

    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  // CRUD: Delete request
  Future<void> deleteRequest(String requestId) async {
    await _firestoreService.deleteDocument(
      collection: 'connection_requests',
      docId: requestId,
    );
  }

  // CRUD: Create request
  Future<void> createRequest({
    required String senderId,
    required String receiverId,
    required String senderUsername,
    required String receiverUsername,
    required String parentRole,
  }) async {
    await _firestoreService.addData(
      collection: 'connection_requests',
      data: {
        'senderId': senderId,
        'receiverId': receiverId,
        'senderUsername': senderUsername,
        'receiverUsername': receiverUsername,
        'status': 'pending',
        'parentRole': parentRole,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> updateRequestStatus({
    required String senderUsername,
    required String receiverUsername,
    required String status,
  }) async {
    final query = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('senderUsername', isEqualTo: senderUsername)
                  .where('receiverUsername', isEqualTo: receiverUsername),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    for (final doc in query.docs) {
      await _firestoreService.updateDocument(
        collection: 'connection_requests',
        docId: doc.id,
        data: {'status': status},
      );
    }
  }
}
