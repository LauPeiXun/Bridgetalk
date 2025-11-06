import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';
import 'package:bridgetalk/data/models/game_model.dart';
import 'package:bridgetalk/presentation/screens/game/game_lobby_screen.dart';
import 'package:bridgetalk/application/controller/game/game_lobby_controller.dart';
import 'package:bridgetalk/presentation/screens/game/game_screen.dart';

class LobbyDetailScreen extends StatefulWidget {
  final String lobbyId;

  const LobbyDetailScreen({super.key, required this.lobbyId});

  @override
  State<LobbyDetailScreen> createState() => _LobbyDetailScreenState();
}

class _LobbyDetailScreenState extends State<LobbyDetailScreen> {
  final GameLobbyController _controller = GameLobbyController();

  @override
  void initState() {
    super.initState();
    _controller.setSelectedLobby(widget.lobbyId);
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.loadLobbyData();
      final userModel = await _controller.getCurrentUserId();
      setState(() {
        _controller.currentUserId = userModel;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Initialization Error: $e')));
      }
    }
  }

  Future<void> _joinGame(int playerIndex) async {
    try {
      await _controller.joinLobby(playerIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Join Failed: $e')));
      }
    }
  }

  Future<void> _toggleReady(int playerIndex) async {
    try {
      await _controller.toggleReady(playerIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ready Status Toggle Failed: $e')),
        );
      }
    }
  }

  Future<void> _leavePosition(int playerIndex) async {
    try {
      await _controller.leavePosition(playerIndex);
      if (mounted) {
        // Show message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Left Position')));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GameLobbyScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Leave Position Failed: $e')));
      }
    }
  }

  Future<void> _startGame() async {
    try {
      await _controller.startGame();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Start Game Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopNav(),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade100, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.black),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Game Tutorial'),
                          content: const Text(
                            'This is a cooperative memory card game for two players.\n\n'
                            'Game Rules:\n'
                            '1. Two players take turns to flip one card at a time.\n'
                            '2. If the two flipped cards match, it\'s a successful pair.\n'
                            '3. If the cards do not match, they are turned face down again.\n'
                            '4. Work together and try to remember the card positions to match all pairs!\n\n'
                            'Have fun and good luck!',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ),
            StreamBuilder<LobbyData>(
              stream: _controller.lobbyDataStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lobbyData = snapshot.data!;
                final currentUserId = _controller.currentUserId;

                if (lobbyData.gameStatus == 'started' && mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => GameScreen(
                              lobbyId: widget.lobbyId,
                              playerIndex:
                                  lobbyData.player1Id == currentUserId ? 1 : 2,
                            ),
                      ),
                    );
                  });
                }

                return Stack(
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.orange.shade100, Colors.white],
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Lobby ID: ${widget.lobbyId.substring(0, 5)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPlayerSlot(
                                    playerId: lobbyData.player1Id,
                                    isReady: lobbyData.player1Ready,
                                    playerIndex: 1,
                                    currentUserId: currentUserId,
                                    lobbyData: lobbyData,
                                  ),
                                ),
                                Expanded(
                                  child: _buildPlayerSlot(
                                    playerId: lobbyData.player2Id,
                                    isReady: lobbyData.player2Ready,
                                    playerIndex: 2,
                                    currentUserId: currentUserId,
                                    lobbyData: lobbyData,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            if (lobbyData.player1Ready &&
                                lobbyData.player2Ready)
                              if (lobbyData.player1Id == currentUserId ||
                                  lobbyData.player2Id == currentUserId)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _startGame,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 48,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: const Text(
                                      'Start Game',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 48,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Waiting for host...',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                            else if (lobbyData.player1Id == currentUserId ||
                                lobbyData.player2Id == currentUserId)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Start Game',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            if (lobbyData.player1Id == currentUserId ||
                                lobbyData.player2Id == currentUserId)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    final currentPosition =
                                        lobbyData.player1Id == currentUserId
                                            ? 1
                                            : lobbyData.player2Id ==
                                                currentUserId
                                            ? 2
                                            : 0;
                                    if (currentPosition > 0) {
                                      _leavePosition(currentPosition);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'Leave Room',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 1),
    );
  }

  Widget _buildPlayerSlot({
    required String? playerId,
    required bool isReady,
    required int playerIndex,
    required String? currentUserId,
    required LobbyData lobbyData,
  }) {
    final bool isCurrentUser = playerId == currentUserId;
    final bool isOccupied = playerId != null;
    final bool isUserInOtherSlot =
        (lobbyData.player1Id == currentUserId ||
            lobbyData.player2Id == currentUserId) &&
        !isCurrentUser;

    return SizedBox(
      width: 180,
      height: 280,
      child: Container(
        margin: const EdgeInsets.all(12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color:
              isOccupied
                  ? (isReady ? Colors.green.shade100 : Colors.orange.shade100)
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentUser ? Colors.blue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: isOccupied ? Colors.grey.shade500 : Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            if (isOccupied)
              FutureBuilder<String?>(
                future: _controller.getDetailsUserName(playerId),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Loading...',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
            Text(
              'Player $playerIndex',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isOccupied ? (isReady ? 'Ready' : 'Not Ready') : 'Waiting...',
                style: TextStyle(
                  color:
                      isOccupied
                          ? (isReady ? Colors.green : Colors.orange)
                          : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!isOccupied && !isUserInOtherSlot)
              ElevatedButton(
                onPressed: () => _joinGame(playerIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 171, 217, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else if (isCurrentUser)
              ElevatedButton(
                onPressed: () => _toggleReady(playerIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isReady ? 'Unready' : 'Ready',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
