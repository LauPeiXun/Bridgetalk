import 'package:cloud_firestore/cloud_firestore.dart';

class LobbyData {
  final String? player1Id;
  final String? player2Id;
  final bool player1Ready;
  final bool player2Ready;
  final String gameStatus;
  final int playerCount;

  LobbyData({
    this.player1Id,
    this.player2Id,
    required this.player1Ready,
    required this.player2Ready,
    required this.gameStatus,
    required this.playerCount,
  });

  factory LobbyData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LobbyData(
      player1Id: data['player1'] as String?,
      player2Id: data['player2'] as String?,
      player1Ready: data['player1Ready'] as bool? ?? false,
      player2Ready: data['player2Ready'] as bool? ?? false,
      gameStatus: data['gameStatus'] as String? ?? 'waiting',
      playerCount: data['playerCount'] as int? ?? 0,
    );
  }
}

class GameCard {
  final String id;
  final String value;
  final String image;
  final bool isFlipped;
  final bool isMatched;

  GameCard({
    required this.id,
    required this.value,
    required this.image,
    this.isFlipped = false,
    this.isMatched = false,
  });

  factory GameCard.fromMap(Map<String, dynamic> map) {
    return GameCard(
      id: map['id'],
      value: map['value'],
      image: map['image'],
      isFlipped: map['isFlipped'] ?? false,
      isMatched: map['isMatched'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'value': value,
      'image': image,
      'isFlipped': isFlipped,
      'isMatched': isMatched,
    };
  }
}

class GameState {
  final List<GameCard> cards;
  final int currentTurn;
  final int? player1Card;
  final int? player2Card;
  final DateTime? lastUpdated;

  GameState({
    required this.cards,
    this.currentTurn = 1,
    this.player1Card,
    this.player2Card,
    this.lastUpdated,
  });

  factory GameState.fromMap(Map<String, dynamic> map) {
    final cards =
        List<Map<String, dynamic>>.from(
          map['cards'] ?? [],
        ).map((card) => GameCard.fromMap(card)).toList();

    return GameState(
      cards: cards,
      currentTurn: map['currentTurn'] ?? 1,
      player1Card: map['player1Card'],
      player2Card: map['player2Card'],
      lastUpdated: map['lastUpdated']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cards': cards.map((card) => card.toMap()).toList(),
      'currentTurn': currentTurn,
      'player1Card': player1Card,
      'player2Card': player2Card,
      'lastUpdated': lastUpdated,
    };
  }
}

class Lobby {
  final String id;
  final String name;

  Lobby({
    required this.id,
    required this.name,
  });

  factory Lobby.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lobby(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Lobby',
    );
  }

  Object? get creatorId => null;

  Object? get player1Id => null;

  Object? get player2Id => null;
}