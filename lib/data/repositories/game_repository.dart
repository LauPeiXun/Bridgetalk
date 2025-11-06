import 'package:async/async.dart';
import 'package:bridgetalk/data/models/game_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _gameLobbyCollection = 'game_lobbies';
  final String _gameCollection = 'games';
  final String _connectionsCollection = 'connections';

  //////////////////////////////////   GAME LOBBIES   //////////////////////////////////////////////////
  User? get currentUser => _auth.currentUser;

  // get connectionsID
  Future<String?> getUserConnectionId() async {
    final user = currentUser;
    if (user == null) return null;
        return user.uid;
  }

  // getConnected User
  Future<List<String>> getConnectedUserIds() async {
    final user = currentUser;
    if (user == null) return [];

    List<String> connectedUserIds = [user.uid]; // 始终包含自己

    final childConnectionsQuery = await _firestore
        .collection(_connectionsCollection)
        .where('childId', isEqualTo: user.uid)
        .get();

    for (var doc in childConnectionsQuery.docs) {
      final data = doc.data();
      final parentId = data['parentId'] as String?;
      if (parentId != null && !connectedUserIds.contains(parentId)) {
        connectedUserIds.add(parentId);
      }
    }

    final parentConnectionsQuery = await _firestore
        .collection(_connectionsCollection)
        .where('parentId', isEqualTo: user.uid)
        .get();

    for (var doc in parentConnectionsQuery.docs) {
      final data = doc.data();
      final childId = data['childId'] as String?;
      if (childId != null && !connectedUserIds.contains(childId)) {
        connectedUserIds.add(childId);
      }
    }

    return connectedUserIds;
  }

  //////////////////////////////////   GAME LOBBY   //////////////////////////////////////////////////
  
  //unjoin
  Future<void> unjoin(String lobbyId, int playerIndex) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final lobbyRef = _firestore
        .collection(_gameLobbyCollection)
        .doc(lobbyId);
    final lobbyDoc = await lobbyRef.get();

    final lobbyData = LobbyData.fromFirestore(lobbyDoc);
    int newPlayerCount = lobbyData.playerCount;
    
    Map<String, dynamic> updateData = {};
    
    if (playerIndex == 1) {
      if (lobbyData.player1Id != null) {
        newPlayerCount -= 1;
      }
      updateData['player1'] = null;
      updateData['player1Ready'] = false;
    } else if (playerIndex == 2) {
      if (lobbyData.player2Id != null) {
        newPlayerCount -= 1;
      }
      updateData['player2'] = null;
      updateData['player2Ready'] = false;
    }
    
    updateData['playerCount'] = newPlayerCount;
    
    await _firestore.collection(_gameLobbyCollection).doc(lobbyId).update(updateData);
    
    if (newPlayerCount <= 0) {
      await deleteLobby(lobbyId);
    }
  }

  //////////////////////////////////   GAME    //////////////////////////////////////////////////

  Future<void> deleteGame(String lobbyId) async {
    await _firestore.collection(_gameCollection).doc(lobbyId).delete();
  }


  Future<void> resetLobbyStatus(String lobbyId) async {
    await _firestore.collection(_gameLobbyCollection).doc(lobbyId).update({
      'gameStatus': 'waiting',
      'player1Ready': false,
      'player2Ready': false,
    });
  }

  // Game Operations
  Future<bool> gameExists(String lobbyId) async {
    final doc = await _firestore.collection(_gameCollection).doc(lobbyId).get();
    return doc.exists;
  }

  Future<void> initializeGame(String lobbyId) async {
    try {
      final gameDoc = _firestore.collection(_gameCollection).doc(lobbyId);
    
      final doc = await gameDoc.get();
      if (doc.exists) return;
    
      final List<Map<String, dynamic>> cards = [];
      final cardTypes = [
        {'value': 'fire', 'image': 'assets/images/gameCards/fire.png'},
        {'value': 'hat', 'image': 'assets/images/gameCards/hat.png'},
        {'value': 'lion', 'image': 'assets/images/gameCards/lion.png'},
        {'value': 'piano', 'image': 'assets/images/gameCards/piano.png'},
        {'value': 'present', 'image': 'assets/images/gameCards/present.png'},
        {'value': 'sunflower', 'image': 'assets/images/gameCards/sunflower.png'},
        {'value': 'dolphine', 'image': 'assets/images/gameCards/dolphine.png'},
        {'value': 'earth', 'image': 'assets/images/gameCards/earth.png'},
        {'value': 'lock', 'image': 'assets/images/gameCards/lock.png'},
        {'value': 'umbrella', 'image': 'assets/images/gameCards/umbrella.png'},
      ];
    
      for (var i = 0; i < cardTypes.length; i++) {
        for (var j = 0; j < 2; j++) {
          cards.add({
            'id': '${i}_$j',
            'value': cardTypes[i]['value'],
            'image': cardTypes[i]['image'],
            'isFlipped': false,
            'isMatched': false,
          });
        }
      }
    
      cards.shuffle();
    
      await gameDoc.set({
        'cards': cards,
        'currentTurn': 1,
        'player1Card': null,
        'player2Card': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('Storage object not found: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error initializing game: $e');
      rethrow;
    }
  }

  Future<void> flipCard(String lobbyId, int cardIndex) async {
    final gameDoc = _firestore.collection(_gameCollection).doc(lobbyId);

    try {
      final gameSnapshot = await gameDoc.get();
      if (!gameSnapshot.exists) return;

      final gameData = gameSnapshot.data() as Map<String, dynamic>;
      final cards = List<Map<String, dynamic>>.from(gameData['cards']);
      final currentTurn = gameData['currentTurn'] as int;
      final player1Card = gameData['player1Card'];

      if (cards[cardIndex]['isFlipped'] || cards[cardIndex]['isMatched']) {
        return;
      }

      cards[cardIndex] = {...cards[cardIndex], 'isFlipped': true};

      if (currentTurn == 1) {
        await gameDoc.update({
          'cards': cards,
          'player1Card': cardIndex,
          'currentTurn': 2,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await gameDoc.update({
          'cards': cards,
          'player2Card': cardIndex,
          'currentTurn': 1,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (player1Card != null) {
          final card1 = cards[player1Card];
          final card2 = cards[cardIndex];

          if (card1['value'] == card2['value']) {
            cards[player1Card]['isMatched'] = true;
            cards[cardIndex]['isMatched'] = true;

            await gameDoc.update({
              'cards': cards,             
              'player1Card': null,
              'player2Card': null,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } else {
            await Future.delayed(const Duration(seconds: 1));
            cards[player1Card]['isFlipped'] = false;
            cards[cardIndex]['isFlipped'] = false;

            await gameDoc.update({
              'cards': cards,
              'player1Card': null,
              'player2Card': null,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error flipping card: $e');
      }
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> gameStateStream(String lobbyId) {
    return _firestore
        .collection(_gameCollection)
        .doc(lobbyId)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  // Delete game lobby
  Future<void> deleteLobby(String lobbyId) async {
    await FirebaseFirestore.instance
        .collection('game_lobbies')
        .doc(lobbyId)
        .delete();
  }

  Stream<QuerySnapshot> getUserLobbies() {
    final user = currentUser;
    if (user == null) return Stream.empty();
    
    return _firestore
        .collection(_gameLobbyCollection)
        .where('creatorId', isEqualTo: user.uid)
        .snapshots();
  }
  
  Stream<QuerySnapshot> getFullLobbies() async* {
    final connectedUserIds = await getConnectedUserIds();
    if (connectedUserIds.isEmpty) {
      yield* Stream.empty();
      return;
    }
    
    final userLobbies = getUserLobbies();
    
    final connectedLobbies = _firestore
        .collection(_gameLobbyCollection)
        .where('player1', whereIn: connectedUserIds)
        .where('player2', whereIn: connectedUserIds)
        .snapshots();

    yield* StreamGroup.merge([userLobbies, connectedLobbies]);
  }

  Stream<QuerySnapshot> getAnotherLobbyStream() async* {
    final connectedUserIds = await getConnectedUserIds();
    if (connectedUserIds.isEmpty) {
      yield* Stream.empty();
      return;
    }
    
    final userLobbies = getUserLobbies();
    
    final connectedLobbies = _firestore
        .collection(_gameLobbyCollection)
        .where('player1', whereIn: connectedUserIds)
        .snapshots();

    yield* StreamGroup.merge([userLobbies, connectedLobbies]);
  }

  Future<String> createNewLobby(String creatorId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final lobbyDoc = await _firestore.collection(_gameLobbyCollection).add({
      'creatorId': creatorId,
      'player1': null,
      'player2': null,
      'player1Ready': false,
      'player2Ready': false,
      'gameStatus': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'playerCount': 0,
    });
    
    return lobbyDoc.id;
  }

  Future<void> joinLobby(String lobbyId, int playerIndex) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final lobbyRef = _firestore
        .collection(_gameLobbyCollection)
        .doc(lobbyId);
    final lobbyDoc = await lobbyRef.get();

    if (!lobbyDoc.exists) {
      throw Exception('Lobby does not exist');
    }

    final lobbyData = LobbyData.fromFirestore(lobbyDoc);
    int newPlayerCount = lobbyData.playerCount;

    Map<String, dynamic> updateData = {};
    
    if (playerIndex == 1) {
      if (lobbyData.player1Id == null) {
        newPlayerCount += 1;
      }
      updateData['player1'] = user.uid;
    } else if (playerIndex == 2) {
      if (lobbyData.player2Id == null) {
        newPlayerCount += 1;
      }
      updateData['player2'] = user.uid;
    }
    
    updateData['playerCount'] = newPlayerCount;
    
    await _firestore.collection(_gameLobbyCollection).doc(lobbyId).update(updateData);
  }

  Future<void> toggleReady(String lobbyId, int playerIndex) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final lobbyRef = _firestore
        .collection(_gameLobbyCollection)
        .doc(lobbyId);
    final lobbyDoc = await lobbyRef.get();

    if (lobbyDoc.exists) {
      final data = lobbyDoc.data() as Map<String, dynamic>;
      if (playerIndex == 1 && data['player1'] == user.uid) {
        await lobbyRef.update({
          'player1Ready': !(data['player1Ready'] ?? false),
        });
      } else if (playerIndex == 2 && data['player2'] == user.uid) {
        await lobbyRef.update({
          'player2Ready': !(data['player2Ready'] ?? false),
        });
      }
    }
  }

  Future<void> startGame(String lobbyId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final lobbyRef = _firestore
        .collection(_gameLobbyCollection)
        .doc(lobbyId);
    final lobbyDoc = await lobbyRef.get();

    if (lobbyDoc.exists) {
      final data = lobbyDoc.data() as Map<String, dynamic>;
      if (data['player1'] != null &&
          data['player2'] != null &&
          data['player1Ready'] == true &&
          data['player2Ready'] == true) {
        await lobbyRef.update({
          'gameStatus': 'started',
        });
      } else {
        throw Exception('Both players must be ready to start the game');
      }
    }
  }

  Future<LobbyData> getLobbyData(String lobbyId) async {
    final doc = await FirebaseFirestore.instance
        .collection('game_lobbies')
        .doc(lobbyId)
        .get();
    return LobbyData.fromFirestore(doc);
  }  
  
  Stream<DocumentSnapshot?> getLobbyStream(String lobbyId) {
    return _firestore
        .collection(_gameLobbyCollection)
        .doc(lobbyId)
        .snapshots();
  }
}
