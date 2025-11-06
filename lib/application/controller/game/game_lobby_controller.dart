import 'package:bridgetalk/data/models/game_model.dart';
import 'package:bridgetalk/data/repositories/game_repository.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class GameLobbyController extends ChangeNotifier {
  final GameRepository _gameRepository = GameRepository();
  final UserRepository _userRepository = UserRepository();
  
  String? _connectionId;
  String? _selectedLobbyId;

  String? _player1Id;
  String? _player2Id;
  final bool _player1Ready = false;
  final bool _player2Ready = false;
  final String _gameStatus = 'waiting';
  String? _currentUserId;
  int _playerCount = 0;

  String? get player1Id => _player1Id;
  String? get player2Id => _player2Id;
  bool get player1Ready => _player1Ready;
  bool get player2Ready => _player2Ready;
  String get gameStatus => _gameStatus;
  String? get currentUserId => _currentUserId;
  int get playerCount => _playerCount;

  Future<String?> initializeConnectionId() async {
    _connectionId = await _gameRepository.getUserConnectionId();
    return _connectionId;
  }

  Future<void> loadLobbyData() async {
    if (_selectedLobbyId == null) return;
    await _gameRepository.getLobbyData(_selectedLobbyId!);
  }

  Future<void> joinLobby(int playerIndex) async {
    if (_connectionId == null) {
      await initializeConnectionId();
      if (_connectionId == null) {
        throw Exception('Connection ID not initialized');
      }
    }

    final userModel = await _userRepository.getCurrentUserModel();
    if (userModel == null) throw Exception('User not logged in');
    
    if (_selectedLobbyId == null) throw Exception('No lobby selected');
    
    final currentLobby = await _gameRepository.getLobbyData(_selectedLobbyId!);
    if (playerIndex == 1 && currentLobby.player1Id != null) {
      throw Exception('Position already taken');
    }
    if (playerIndex == 2 && currentLobby.player2Id != null) {
      throw Exception('Position already taken');
    }
    
    _currentUserId = userModel.uid;
    notifyListeners();
    
    await _gameRepository.joinLobby(_selectedLobbyId!, playerIndex);
    final lobbyData = await _gameRepository.getLobbyData(_selectedLobbyId!);
    _playerCount = lobbyData.playerCount;
    notifyListeners();

  }

  Future<String?> getDetailsUserName(String? userId) async {
    if (userId == null) return null;
    try {
      return await _userRepository.getCurrentUsername(userId);
    } catch (e) {
      debugPrint('Error getting username: $e');
      return null;
    }
  }

  Stream<LobbyData> get lobbyDataStream {
    if (_selectedLobbyId == null) {
      return Stream.error('No lobby selected');
    }
    return _gameRepository.getLobbyStream(_selectedLobbyId!)
        .map((snapshot) => LobbyData.fromFirestore(snapshot!));
  }

  Future<String> createNewLobby() async {
    if (_connectionId == null) {
      await initializeConnectionId();
      if (_connectionId == null) {
        throw Exception('Connection ID not initialized');
      }
    }
        
    final lobbyId = await _gameRepository.createNewLobby(_connectionId!);
    _selectedLobbyId = lobbyId;
    
    try {
      final userModel = await _userRepository.getCurrentUserModel();
      if (userModel != null) {
        _currentUserId = userModel.uid;
        await _gameRepository.joinLobby(lobbyId, 1);
    
        final lobbyData = await _gameRepository.getLobbyData(lobbyId);
        _playerCount = lobbyData.playerCount;
        notifyListeners();

        Future.delayed(const Duration(minutes: 10), () async {
          try {
            if (_selectedLobbyId != null) {
              final updatedLobbyData = await _gameRepository.getLobbyData(_selectedLobbyId!);
              if (updatedLobbyData.gameStatus == 'waiting') {
                await _gameRepository.unjoin(_selectedLobbyId!, 1);
                await _gameRepository.deleteLobby(_selectedLobbyId!);
             }
            }
          } catch (e) {
            debugPrint('Auto Leave lobby failed: $e');
          }
        });
            
      }
    } catch (e) {
      debugPrint('Automatic player assignment failed: $e');
    }
    return lobbyId;
  }

  void setSelectedLobby(String lobbyId) {
    _selectedLobbyId = lobbyId;
    notifyListeners();
  }
  
  set currentUserId(String? value) {
    _currentUserId = value;
    notifyListeners();
  }

  Future<String?> getCurrentUserId() async {
    final userModel = await _userRepository.getCurrentUserModel();
    return userModel?.uid;
  }

  Future<void> leavePosition(int playerIndex) async {
    if (_selectedLobbyId == null) return;
    
    final lobbyData = await _gameRepository.getLobbyData(_selectedLobbyId!);
    
    // 如果是创建者(player1)退出
    if (playerIndex == 1 && lobbyData.player1Id == _currentUserId) {
      // 强制退出player2（如果存在）
      if (lobbyData.player2Id != null) {
        await _gameRepository.unjoin(_selectedLobbyId!, 2);
      }
      await _gameRepository.deleteLobby(_selectedLobbyId!);
    } 
    else {
      await _gameRepository.unjoin(_selectedLobbyId!, playerIndex);
      // 检查是否需要删除大厅（playerCount为0时）
      final updatedLobbyData = await _gameRepository.getLobbyData(_selectedLobbyId!);
      if (updatedLobbyData.playerCount <= 0) {
        await _gameRepository.deleteLobby(_selectedLobbyId!);
      }
    }
  }

  Future<void> toggleReady(int playerIndex) async {
    try {
      if (_connectionId == null) {
        await initializeConnectionId();
        if (_connectionId == null) {
          throw Exception('Unable to obtain connection ID');
        }
      }
      
      final currentUser = currentUserId;
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }
      
      final lobbyData = await _gameRepository.getLobbyData(_selectedLobbyId!);
      
      if (playerIndex == 1) {
        if (lobbyData.player1Id != currentUser) {
          throw Exception('You are not a player 1');
        }
        await _gameRepository.toggleReady(_selectedLobbyId!, playerIndex);
      } else if (playerIndex == 2) {
        if (lobbyData.player2Id != currentUser) {
          throw Exception('You are not a player 2');
        }
        await _gameRepository.toggleReady(_selectedLobbyId!, playerIndex);
      } else {
        throw Exception('Invalid player index');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startGame() async {
    if (_selectedLobbyId == null) throw Exception('No lobby chosen');
    await _gameRepository.startGame(_selectedLobbyId!);
    await _gameRepository.initializeGame(_selectedLobbyId!);
  }

  Stream<List<Lobby>> get lobbiesStream {
    return Stream.fromFuture(_userRepository.getCurrentUserModel())
      .switchMap((userModel) {
        if (userModel == null) {
          return Stream.value(<Lobby>[]);
        }
        final currentUserId = userModel.uid;

        // assume _gameRepository.getUserLobbies()
        final userLobbiesStream = _gameRepository.getUserLobbies()
            .map((querySnapshot) => querySnapshot.docs
                .map((doc) => Lobby.fromFirestore(doc)) 
                .toList());
          
        // assume  _gameRepository.getFullLobbies()
        final fullLobbiesStream = _gameRepository.getFullLobbies()
            .map((querySnapshot) => querySnapshot.docs
                .map((doc) => Lobby.fromFirestore(doc))
                .toList());
        
        // assume _gameRepository.getAnotherLobbyStream()
        final anotherLobbyStream = _gameRepository.getAnotherLobbyStream()
            .map((querySnapshot) => querySnapshot.docs
                .map((doc) => Lobby.fromFirestore(doc))
                .toList());

        return Rx.combineLatest3<List<Lobby>, List<Lobby>, List<Lobby>, List<Lobby>>(
          userLobbiesStream,
          fullLobbiesStream,
          anotherLobbyStream,
          (lobbiesFromUser, lobbiesFromFull, lobbiesFromAnother) {
            final potentialLobbies = <Lobby>[];

            // 1. user self created room
            potentialLobbies.addAll(lobbiesFromUser);

            // 2. handle fullLobbiesStream， anotherLobbyStream
            final List<Lobby> connectedLobbies = [];
            connectedLobbies.addAll(lobbiesFromFull);
            connectedLobbies.addAll(lobbiesFromAnother);

            for (final lobby in connectedLobbies) {
              // got player 1 & 2
              bool isLobbyFull = (lobby.player1Id != null && lobby.player2Id != null);
              bool isCurrentUserInLobby = (lobby.player1Id == currentUserId || lobby.player2Id == currentUserId);

              if (isLobbyFull) {
                if (isCurrentUserInLobby) {
                  potentialLobbies.add(lobby);
                }
              } else {
                potentialLobbies.add(lobby);
              }
            }

            // 3. remove duplicate
            final uniqueLobbyIds = <String>{};
            final List<Lobby> filteredAndUniqueLobbies = [];
            for (final lobby in potentialLobbies) {
              if (uniqueLobbyIds.add(lobby.id)) {
                filteredAndUniqueLobbies.add(lobby);
              }
            }
            return filteredAndUniqueLobbies;
          },
        );
      });
  }
  }