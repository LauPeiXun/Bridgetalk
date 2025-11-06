import 'package:bridgetalk/data/models/child_link_model.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildLinkRepository {
  final FirestoreService _firestoreService;

  ChildLinkRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  // CRUD: Read user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestoreService.getDocument(
      collection: 'users',
      docId: userId,
    );

    if (!doc.exists) return null;
    return doc.data();
  }

  Future<List<ChildLinkModel>> getConnections(String childId) async {
    // Get the first emitted snapshot from the stream
    final snapshot = await _firestoreService
        .streamCollection(
          collection: 'connections',
          queryBuilder: (query) => query.where('childId', isEqualTo: childId),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    List<ChildLinkModel> connections = [];

    for (var doc in snapshot.docs) {
      final connectionData = doc.data();
      final parentId = connectionData['parentId'] as String;

      final parentDoc = await _firestoreService.getDocument(
        collection: 'users',
        docId: parentId,
      );

      if (parentDoc.exists) {
        final parentData = parentDoc.data();
        connections.add(
          ChildLinkModel.fromFirestore({
            ...connectionData,
            'username': parentData?['username'],
          }, doc.id),
        );
      }
    }

    return connections;
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

  // CRUD: Read received requests
  Future<List<Map<String, dynamic>>> getReceivedRequests(
    String receiverId,
  ) async {
    final receivedRequests = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('receiverId', isEqualTo: receiverId)
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    final receivedRequestsOldFormat = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('to', isEqualTo: receiverId)
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    return [
      ...receivedRequests.docs.map((doc) => {...doc.data(), 'id': doc.id}),
      ...receivedRequestsOldFormat.docs.map(
        (doc) => {...doc.data(), 'id': doc.id},
      ),
    ];
  }

  // CRUD: Read parent users
  Future<List<Map<String, dynamic>>> searchParents(String query) async {
    final parentDocsLower = await _firestoreService
        .streamCollection(
          collection: 'users',
          queryBuilder: (query) => query.where('role', isEqualTo: 'parent'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    final parentDocsUpper = await _firestoreService
        .streamCollection(
          collection: 'users',
          queryBuilder: (query) => query.where('role', isEqualTo: 'Parent'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    return [
      ...parentDocsLower.docs,
      ...parentDocsUpper.docs,
    ].map((doc) => doc.data()).toList();
  }

  // CRUD: Read parent by username
  Future<Map<String, dynamic>?> getParentByUsername(String username) async {
    final parentQuery = await _firestoreService
        .streamCollection(
          collection: 'users',
          queryBuilder:
              (query) => query
                  .where('username', isEqualTo: username)
                  .where('role', whereIn: ['parent', 'Parent']),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    if (parentQuery.docs.isEmpty) return null;
    final doc = parentQuery.docs.firstWhere(
      (snapshot) => !snapshot.metadata.isFromCache,
    );
    return {...doc.data(), 'uid': doc.id};
  }

  // CRUD: Create connection request
  Future<void> createConnectionRequest({
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

  // CRUD: Check existing parent role
  Future<bool> checkExistingParentRole({
    required String childId,
    required String parentRole,
  }) async {
    final existingConnections = await _firestoreService
        .streamCollection(
          collection: 'connections',
          queryBuilder:
              (query) => query
                  .where('childId', isEqualTo: childId)
                  .where('parentRole', isEqualTo: parentRole),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    return existingConnections.docs.isNotEmpty;
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

  // CRUD: Delete requests between users
  Future<void> deleteAllRequestsBetweenUsers({
    required String senderId,
    required String receiverId,
  }) async {
    final requests1 = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('senderId', isEqualTo: senderId)
                  .where('receiverId', isEqualTo: receiverId)
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    final requests2 = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('senderId', isEqualTo: receiverId)
                  .where('receiverId', isEqualTo: senderId)
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    final oldRequests1 = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('from', isEqualTo: senderId)
                  .where('to', isEqualTo: receiverId)
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    final oldRequests2 = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('from', isEqualTo: receiverId)
                  .where('to', isEqualTo: senderId)
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    for (var doc in [
      ...requests1.docs,
      ...requests2.docs,
      ...oldRequests1.docs,
      ...oldRequests2.docs,
    ]) {
      await _firestoreService.deleteDocument(
        collection: 'connection_requests',
        docId: doc.id,
      );
    }
  }

  Future<void> deleteSingleRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final querySnapshot = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('senderId', isEqualTo: senderId)
                  .where('receiverId', isEqualTo: receiverId)
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    final oldFormat = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('from', isEqualTo: senderId)
                  .where('to', isEqualTo: receiverId)
                  .where('status', isEqualTo: 'pending'),
        )
        .firstWhere((snapshot) => !snapshot.metadata.isFromCache);

    for (final doc in [...querySnapshot.docs, ...oldFormat.docs]) {
      await _firestoreService.deleteDocument(
        collection: 'connection_requests',
        docId: doc.id,
      );
    }
  }

  Future<void> updateRequestStatus({
    required String senderId,
    required String receiverId,
    required String status,
  }) async {
    final query = await _firestoreService
        .streamCollection(
          collection: 'connection_requests',
          queryBuilder:
              (query) => query
                  .where('senderId', isEqualTo: senderId)
                  .where('receiverId', isEqualTo: receiverId),
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
