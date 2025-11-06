import 'package:bridgetalk/data/models/child_link_model.dart';
import 'package:bridgetalk/data/repositories/child_link_repository.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildLinkController {
  final ChildLinkRepository _repository;
  final FirebaseAuthService _authService;

  ChildLinkController({
    ChildLinkRepository? repository,
    FirebaseAuthService? authService,
  }) : _repository = repository ?? ChildLinkRepository(),
       _authService = authService ?? FirebaseAuthService();

  Future<Map<String, dynamic>?> loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) return null;
    return _repository.getUserData(user.uid);
  }

  Future<List<ChildLinkModel>> loadConnections() async {
    final user = _authService.currentUser;
    if (user == null) return [];
    return await _repository.getConnections(user.uid);
  }

  Future<List<Map<String, dynamic>>> loadSentRequests() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    final requests = await _repository.getSentRequests(user.uid);

    final enrichedRequests = await Future.wait(
      requests.map((request) async {
        final receiverId = request['receiverId'] ?? request['to'];
        final userData = await _repository.getUserData(receiverId);
        return {
          ...request,
          'receiverUsername': userData?['username'] ?? 'Unknown User',
        };
      }),
    );

    return _deduplicateRequests(enrichedRequests); // ✅ Fixed
  }

  Future<List<Map<String, dynamic>>> loadReceivedRequests() async {
    // Business Logic: Check user authentication
    final user = _authService.currentUser;
    if (user == null) return [];

    // Get both new and old format requests
    final requests = await _repository.getReceivedRequests(user.uid);
    final enrichedRequests = await Future.wait(
      requests.map((request) async {
        final senderId = request['senderId'] ?? request['from'];
        final userData = await _repository.getUserData(senderId);
        return {
          ...request,
          'senderUsername': userData?['username'] ?? 'Unknown User',
        };
      }),
    );
    return _deduplicateRequests(enrichedRequests);
  }

  // Business Logic: Deduplicate requests based on username
  List<Map<String, dynamic>> _deduplicateRequests(
    List<Map<String, dynamic>> requests,
  ) {
    final Map<String, Map<String, dynamic>> uniqueRequests = {};

    for (var request in requests) {
      final senderId = request['senderId'] ?? request['from'];
      final receiverId = request['receiverId'] ?? request['to'];
      final key = '$senderId->$receiverId'; // 🔑 Unique per direction

      if (!uniqueRequests.containsKey(key)) {
        uniqueRequests[key] = request;
      }
    }

    return uniqueRequests.values.toList();
  }

  Future<List<Map<String, dynamic>>> searchParentUsers(
    String query,
    String targetRole,
  ) async {
    if (query.isEmpty) return [];

    final currentUser = _authService.currentUser;
    if (currentUser == null) return [];

    // Load user data
    final currentUserData = await _repository.getUserData(currentUser.uid);
    final currentUsername = currentUserData?['username'];
    if (currentUsername == null) return [];

    // Load connections
    final connections = await _repository.getConnections(currentUser.uid);
    final connectedParentIds = connections.map((c) => c.parentId).toSet();
    final existingRoles =
        connections.map((c) => c.parentRole?.toLowerCase()).toSet();

    // Load sent requests
    final sentRequests = await _repository.getSentRequests(currentUsername);
    final sentTo =
        sentRequests
            .map((r) => (r['receiverUsername'] ?? '').toString().toLowerCase())
            .toSet();

    // Fetch parents
    final allParents = await _repository.searchParents(query.toLowerCase());

    // Filter
    return allParents
        .where((user) {
          final username = (user['username'] ?? '').toString().toLowerCase();
          final id = (user['uid'] ?? '').toString();
          final gender = (user['gender'] ?? '').toString().toLowerCase();

          // Role logic
          final role =
              gender == 'male'
                  ? 'father'
                  : gender == 'female'
                  ? 'mother'
                  : 'unknown';

          final isMatch = username.contains(query.toLowerCase());
          final isCorrectRole = role == targetRole.toLowerCase();
          final notAlreadyConnected = !connectedParentIds.contains(id);
          final notAlreadyRequested = !sentTo.contains(username);
          final notAlreadyHasThisRole = !existingRoles.contains(role);

          return isMatch &&
              isCorrectRole &&
              notAlreadyConnected &&
              notAlreadyRequested &&
              notAlreadyHasThisRole;
        })
        .map(
          (user) => {
            'id': user['uid'] ?? '',
            'username': user['username'] ?? '',
            'gender': user['gender'] ?? 'unknown',
          },
        )
        .toList();
  }

  Future<void> sendConnectionRequest(
    String toUsername,
    String parentRole,
  ) async {
    // Business Logic: Validate user authentication
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get current user's data
    final currentUserData = await _repository.getUserData(user.uid);
    if (currentUserData == null) {
      throw Exception('Current user document not found');
    }

    final currentUsername = currentUserData['username'] as String?;
    if (currentUsername == null) throw Exception('Current username not found');

    // Get parent user data
    final parentData = await _repository.getParentByUsername(toUsername);
    if (parentData == null) throw Exception('Parent user not found');

    // Business Logic: Determine parent role based on gender
    final parentGender =
        parentData['gender']?.toString().toLowerCase() ?? 'unknown';
    final determinedRole = _determineParentRole(parentGender);
    final parentId = parentData['uid'];
    // Create request with determined role
    await _repository.createConnectionRequest(
      senderId: user.uid,
      receiverId: parentId,
      senderUsername: currentUsername,
      receiverUsername: toUsername,
      parentRole: determinedRole,
    );
  }

  // Business Logic: Determine parent role based on gender
  String _determineParentRole(String gender) {
    return gender == 'male'
        ? 'father'
        : gender == 'female'
        ? 'mother'
        : 'unknown';
  }

  Future<void> handleRequest(Map<String, dynamic> request, bool accept) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final parentRole =
        (request['parentRole'] as String?)?.toLowerCase() ?? 'unknown';
    final parentUsername = request['senderUsername'] ?? request['from'];

    final parentData = await _repository.getParentByUsername(parentUsername);
    if (parentData == null) throw Exception('Could not find parent user');

    final senderId = request['senderId'] ?? request['from'];
    final receiverId = request['receiverId'] ?? request['to'];

    if (accept) {
      // Check for existing parent role
      final hasExisting = await _repository.checkExistingParentRole(
        childId: user.uid,
        parentRole: parentRole,
      );
      if (hasExisting) throw Exception('You already have a $parentRole');

      // Create connection
      await _repository.createConnection(
        childId: user.uid,
        parentId: parentData['uid'],
        parentRole: parentRole,
      );

      // ✅ Accept: Delete both directions (cleanup)
      await _repository.deleteAllRequestsBetweenUsers(
        senderId: senderId,
        receiverId: receiverId,
      );
    } else {
      // ❌ Reject: Only delete request sent to me
      await _repository.deleteSingleRequest(
        senderId: senderId,
        receiverId: receiverId,
      );
    }
  }

  Future<void> cancelRequest(String requestId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final requestData = await _repository.getRequestById(requestId);
    if (requestData == null) throw Exception('Request not found');

    final senderId = requestData['senderId'] ?? requestData['from'];
    final receiverId = requestData['receiverId'] ?? requestData['to'];

    /*
    // ✅ Only delete if I’m the sender
    if (senderId != user.uid) {
      throw Exception('You can only cancel requests you sent');
    }
    */

    await _repository.deleteSingleRequest(
      senderId: senderId,
      receiverId: receiverId,
    );
  }

  Stream<List<ChildLinkModel>> streamConnections() {
    final user = _authService.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('connections')
        .where('childId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ChildLinkModel> models = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final parentId = data['parentId'];

            final parentDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(parentId)
                    .get();

            final username = parentDoc.data()?['username'] ?? 'Unknown';

            models.add(
              ChildLinkModel.fromFirestore({
                ...data,
                'username': username,
              }, doc.id),
            );
          }
          return models;
        });
  }
}
