  import 'package:bridgetalk/presentation/screens/game/lobby_detail_screen.dart';
  import 'package:bridgetalk/application/controller/game/game_controller.dart';
  import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';

  class GameScreen extends StatefulWidget {
    final String lobbyId;
    final int playerIndex;

    const GameScreen({
      super.key,
      required this.lobbyId,
      required this.playerIndex,
    });

    @override
    State<GameScreen> createState() => _GameScreenState();
  }

  class _GameScreenState extends State<GameScreen> {
    late final GameController _gameController;
    bool _gameOverDialogShown = false;

    @override
    void initState() {
      super.initState();
      _gameController = GameController();
      _initializeGame();

      _gameController.gameEndedStream.listen((lobbyId) {
        if (mounted) {
          // return lobbydetails
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyDetailScreen(lobbyId: lobbyId),
            ),
          );
        }
      });
    }

    Future<void> _initializeGame() async {
      try {
        await _gameController.initializeGame(widget.lobbyId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to initialize the game: $e')),
          );
        }
      }
    }

    @override
    void dispose() {
      _gameController.dispose();
      super.dispose();
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
          child: SafeArea(
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
                // Game info header
                StreamBuilder<Map<String, dynamic>>(
                  stream: _gameController.getGameStateStream(widget.lobbyId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final gameState = snapshot.data!;
                    final isMyTurn = _gameController.isPlayerTurn(
                      gameState,
                      widget.playerIndex,
                    );

                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'You are Player ${widget.playerIndex}',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: widget.playerIndex == 1
                                  ? Colors.red
                                  : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMyTurn ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isMyTurn ? 'Your turn!' : 'Waiting...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Game board
                Expanded(
                  child: StreamBuilder<Map<String, dynamic>>(
                    stream: _gameController.getGameStateStream(widget.lobbyId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final gameState = snapshot.data!;
                      final cards = List<Map<String, dynamic>>.from(
                        gameState['cards'] ?? [],
                      );
                      final isMyTurn = _gameController.isPlayerTurn(
                        gameState,
                        widget.playerIndex,
                      );
                      final flippedCards = _gameController.getFlippedCards(
                        gameState,
                      );

                      if (_gameController.isGameOver(gameState) && !_gameOverDialogShown) {
                        _gameOverDialogShown = true;
                        Future.delayed(Duration.zero, () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: const Text('Game Complete! 🎉'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.celebration,
                                    size: 80,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 30),
                                  const Text(
                                    'Congratulations!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'Return lobby in 5sec...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      color: Colors.orange.shade300,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          Future.delayed(const Duration(seconds: 5), () {
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }
                          });
                        });
                      }
                      if (_gameController.isGameOver(gameState)) {
                        return const SizedBox.shrink();
                      }

                      return Center(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(24),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            final isFlipped = card['isFlipped'] ?? false;
                            final isMatched = card['isMatched'] ?? false;

                            Color? borderColor;
                            if (index == flippedCards[0]) {
                              borderColor = Colors.red;
                            } else if (index == flippedCards[1]) {
                              borderColor = Colors.blue;
                            }

                            return GestureDetector(
                              onTap:
                                  isMyTurn &&
                                          _gameController.canFlipCard(
                                            gameState,
                                            index,
                                          )
                                      ? () => _gameController.flipCard(
                                        widget.lobbyId,
                                        index,
                                      )
                                      : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: isMatched ? Colors.green : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      borderColor != null
                                          ? Border.all(
                                            color: borderColor,
                                            width: 3,
                                          )
                                          : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child:
                                      isFlipped || isMatched
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.asset(
                                              card['image'] ??
                                                  'assets/images/gameCards/default.png',
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.question_mark,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomNavBar(currentIndex: 1),
      );
    }
  }
