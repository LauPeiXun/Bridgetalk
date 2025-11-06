import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';
import 'package:bridgetalk/data/repositories/parent_link_repository.dart';
import 'package:bridgetalk/data/models/parent_link_model.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ParentLinkController {
  final ParentLinkRepository _repository = ParentLinkRepository();
  final FirebaseAuthService _auth = FirebaseAuthService();
  final UserRepository userRepository = UserRepository();

  // Business Logic Layer
  Future<Map<String, dynamic>?> loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userData = await _repository.getUserData(user.uid);
      if (userData == null) throw Exception('Failed to load user data');
      return {
        ...userData, // spreads all entries from userDat
        'id': user.uid,
      };
    } catch (e) {
      debugPrint('Error loading user data: $e');
      rethrow;
    }
  }

  Future<List<ParentLinkModel>> loadConnections() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      return await _repository.getConnections(user.uid);
    } catch (e) {
      debugPrint('Error loading connections: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loadReceivedRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final requests = await _repository.getReceivedRequests(user.uid);

      final enriched = await Future.wait(
        requests.map((request) async {
          final senderId = request['senderId'] ?? request['from'];
          final senderData = await _repository.getUserData(senderId);
          return {
            ...request,
            'senderUsername': senderData?['username'] ?? 'Unknown User',
          };
        }),
      );

      return _deduplicateRequests(enriched);
    } catch (e) {
      debugPrint('Error loading received requests: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loadSentRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final requests = await _repository.getSentRequests(user.uid);

      final enriched = await Future.wait(
        requests.map((request) async {
          final receiverId = request['receiverId'] ?? request['to'];
          final receiverData = await _repository.getUserData(receiverId);
          return {
            ...request,
            'receiverUsername': receiverData?['username'] ?? 'Unknown User',
          };
        }),
      );

      return _deduplicateRequests(enriched);
    } catch (e) {
      debugPrint('Error loading sent requests: $e');
      rethrow;
    }
  }

  // Business Logic: Deduplicate requests based on username
  List<Map<String, dynamic>> _deduplicateRequests(
    List<Map<String, dynamic>> requests,
  ) {
    final Map<String, Map<String, dynamic>> uniqueRequests = {};

    for (var request in requests) {
      final username = request['senderUsername'] ?? request['from'];
      final receiverUsername = request['receiverUsername'] ?? request['to'];

      // Create a unique key based on both usernames to ensure uniqueness
      final key = '$username-$receiverUsername';

      if (!uniqueRequests.containsKey(key)) {
        uniqueRequests[key] = request;
      }
    }

    return uniqueRequests.values.toList();
  }

  Future<List<Map<String, dynamic>>> searchUsers(
    String query,
    String? currentUsername,
    List<ParentLinkModel> connections,
    List<Map<String, dynamic>> sentRequests,
  ) async {
    try {
      if (query.isEmpty || currentUsername == null) return [];

      // 🔥 拉取所有 users
      final users = await _repository.getUsers();

      // Log 所有用户
      for (final user in users) {
        debugPrint(
          '👤 User: ${user['username']} | role: ${user['role']} | id: ${user['id']}',
        );
      }

      // 提取连接的 child ID 以及已发出的请求 username
      final connectedChildIds =
          connections.map((conn) => (conn.childId ?? '').toLowerCase()).toSet();
      final sentToUsernames =
          sentRequests
              .map(
                (r) => (r['receiverUsername'] ?? '').toString().toLowerCase(),
              )
              .toSet();

      final filtered =
          users.where((user) {
            final role = (user['role'] ?? '').toString().toLowerCase();
            final username = (user['username'] ?? '').toString().toLowerCase();
            final id = (user['id'] ?? '').toString().toLowerCase();

            final isChild = role == 'child';
            final notSelf = username != currentUsername.toLowerCase();
            final notAlreadyConnected = !connectedChildIds.contains(id);
            final notAlreadyRequested = !sentToUsernames.contains(username);
            final matchesQuery = username.contains(query.toLowerCase());

            final keep =
                isChild &&
                notSelf &&
                notAlreadyConnected &&
                notAlreadyRequested &&
                matchesQuery;
            return keep;
          }).toList();

      debugPrint('✅ Results after filtering: ${filtered.length}');
      return filtered
          .map(
            (user) => {
              'username': user['username'],
              'role': user['role'],
              'id': user['id'],
            },
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error in searchUsers: $e');
      rethrow;
    }
  }

  Future<void> handleRequest({
    required String fromUserId,
    required bool accept,
  }) async {
    try {
      // Validation
      String currentUserId = await _auth.getCurrentUserUid();
      if (fromUserId.isEmpty) throw Exception('Sender ID cannot be empty');
      if (currentUserId.isEmpty) {
        throw Exception('Current user ID cannot be empty');
      }

      final userData = await _repository.getUserData(currentUserId);
      if (userData == null) throw Exception('User data not found');

      final parentGender = userData['gender']?.toString().toLowerCase();
      if (parentGender == null) throw Exception('Parent gender not set');
      if (!['male', 'female'].contains(parentGender)) {
        throw Exception('Invalid parent gender');
      }

      if (accept) {
        final childData = await _repository.getUserData(fromUserId);
        if (childData == null) throw Exception('Child user not found');

        final parentRole = parentGender == 'male' ? 'father' : 'mother';

        await _repository.createConnection(
          childId: fromUserId,
          parentId: currentUserId,
          parentRole: parentRole,
        );
      }

      // Always delete the received request
      final receivedRequests = await _repository.getReceivedRequests(
        currentUserId,
      );
      for (var request in receivedRequests) {
        if (request['senderId'] == fromUserId) {
          await _repository.deleteRequest(request['id']);
        }
      }

      // Only delete the sent request if accepted
      if (accept) {
        final sentRequests = await _repository.getSentRequests(currentUserId);
        for (var request in sentRequests) {
          if (request['receiverId'] == fromUserId) {
            await _repository.deleteRequest(request['id']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling request: $e');
      rethrow;
    }
  }

  Future<void> cancelRequest(String receiverId) async {
    try {
      String currentUserId = await _auth.getCurrentUserUid();
      final allSent = await _repository.getSentRequests(currentUserId);

      for (final request in allSent) {
        if (request['id'] == receiverId) {
          await _repository.deleteRequest(request['id']);
        }
      }
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      rethrow;
    }
  }

  Future<void> sendRequest({required String childUsername}) async {
    try {
      // Business validation
      if (childUsername.isEmpty) {
        throw Exception('Child username cannot be empty');
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await _repository.getUserData(user.uid);
      if (userData == null) throw Exception('User data not found');

      final parentUsername = userData['username'];
      if (parentUsername == null) throw Exception('Username not set');

      final parentGender = userData['gender']?.toString().toLowerCase();
      if (parentGender == null) throw Exception('Parent gender not set');
      if (!['male', 'female'].contains(parentGender)) {
        throw Exception('Invalid parent gender');
      }

      final childData = await _repository.getUserByUsername(childUsername);
      if (childData == null) throw Exception('Child user not found');
      final childId = childData['id'];

      // Business Logic: Determine parent role based on gender
      final parentRole = parentGender == 'male' ? 'father' : 'mother';

      await _repository.createRequest(
        senderId: user.uid,
        receiverId: childId,
        senderUsername: parentUsername,
        receiverUsername: childUsername,
        parentRole: parentRole,
      );
    } catch (e) {
      debugPrint('Error sending request: $e');
      rethrow;
    }
  }

  Stream<List<ParentLinkModel>> streamConnections() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('connections')
        .where('parentId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ParentLinkModel> models = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final childId = data['childId'];

            // Get child's username
            final childDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(childId)
                    .get();

            final childUsername = childDoc.data()?['username'] ?? 'Unknown';

            models.add(
              ParentLinkModel.fromMap({
                ...data,
                'childUsername': childUsername,
              }, doc.id),
            );
          }

          return models;
        });
  }
}
