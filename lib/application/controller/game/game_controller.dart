import 'dart:async';

import 'package:bridgetalk/data/repositories/game_repository.dart';
import 'package:bridgetalk/data/repositories/spark_repository.dart';
import 'package:flutter/material.dart';

class GameController {
  final GameRepository _gameRepository = GameRepository();
  final SparkPointRepository _sparkRepo = SparkPointRepository();

  Timer? _timer;
  bool _gameEndProcessed = false;

  // Add a StreamController to send a notification when the game ends
  final StreamController<String> _gameEndedController =
      StreamController<String>.broadcast();

  // Provide a Stream to the UI layer to listen for game end events
  Stream<String> get gameEndedStream => _gameEndedController.stream;

  void dispose() {
    _timer?.cancel();
    _gameEndedController.close();
  }

  // Initialize game
  Future<void> initializeGame(String lobbyId) async {
    try {
      final gameExists = await _gameRepository.gameExists(lobbyId);
      if (!gameExists) {
        await _gameRepository.initializeGame(lobbyId);
        _startTimer();
      }
      _gameEndProcessed = false;
    } catch (e) {
      rethrow;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 5), () {});
  }

  // Flip card
  Future<void> flipCard(String lobbyId, int cardIndex) async {
    try {
      final gameState = await _gameRepository.gameStateStream(lobbyId).first;
      if (!canFlipCard(gameState, cardIndex)) return;

      await _gameRepository.flipCard(lobbyId, cardIndex);
    } catch (e) {
      rethrow;
    }
  }

  // Get game state stream
  Stream<Map<String, dynamic>> getGameStateStream(String lobbyId) {
    return _gameRepository.gameStateStream(lobbyId).map((gameState) {
      if (isGameOver(gameState)) {
        _handleGameOverOnce(lobbyId);
      }
      return gameState;
    });
  }

  Future<void> _handleGameOver(String lobbyId) async {
    try {
      await Future.delayed(const Duration(seconds: 5));

      final lobbyData = await _gameRepository.getLobbyData(lobbyId);
      final player1Id = lobbyData.player1Id;
      final player2Id = lobbyData.player2Id;

      if (player1Id == null || player2Id == null) return;

      await _sparkRepo.increaseSparkPointByConnection(player1Id, player2Id);
      await _gameRepository.deleteGame(lobbyId);
      await _gameRepository.resetLobbyStatus(lobbyId);
      _timer?.cancel();

      _gameEndedController.add(lobbyId);
    } catch (e) {
      debugPrint('❌ Error handling game over: $e');
    }
  }

  void _handleGameOverOnce(String lobbyId) {
    if (_gameEndProcessed) return;
    _gameEndProcessed = true;
    _handleGameOver(lobbyId);
  }

  // Check if it's player's turn
  bool isPlayerTurn(Map<String, dynamic> gameState, int playerIndex) {
    final currentTurn = gameState['currentTurn'] ?? 1;
    return currentTurn == playerIndex;
  }

  // Check if card can be flipped
  bool canFlipCard(Map<String, dynamic> gameState, int cardIndex) {
    final cards = List<Map<String, dynamic>>.from(gameState['cards'] ?? []);
    if (cardIndex >= cards.length) return false;

    final card = cards[cardIndex];
    final flippedCount =
        cards
            .where((c) => c['isFlipped'] == true && c['isMatched'] == false)
            .length;

    return !(card['isFlipped'] ?? false) &&
        !(card['isMatched'] ?? false) &&
        flippedCount < 2;
  }

  // Get flipped cards
  List<int?> getFlippedCards(Map<String, dynamic> gameState) {
    return [gameState['player1Card'], gameState['player2Card']];
  }

  // Check if game is over
  bool isGameOver(Map<String, dynamic> gameState) {
    final cards = List<Map<String, dynamic>>.from(gameState['cards'] ?? []);

    if (cards.isEmpty) {
      return false;
    }
    return cards.every((card) => card['isMatched'] == true);
  }
}
