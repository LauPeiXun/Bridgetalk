import 'package:bridgetalk/presentation/screens/game/game_lobby_screen.dart';
import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';

class GamesCatalogScreen extends StatefulWidget {
  const GamesCatalogScreen({super.key});

  @override
  State<GamesCatalogScreen> createState() => _GamesCatalogState();
}

class _GamesCatalogState extends State<GamesCatalogScreen> {
  // Sample game data
  final List<Map<String, dynamic>> _games = [
    {
      'title': 'Flip Cards',
      'description':
          'Test your memory skills with this classic card matching game.',
      'imageUrl': 'assets/images/gamesCatalogImage/games1.png',
      'link': GameLobbyScreen(),
    },
    {
      'title': 'Brain Teaser',
      'description':
          'Challenge your mind with puzzles that will test your logical thinking abilities.',
      'imageUrl': 'assets/images/gamesCatalogImage/games2.png',
    },
    {
      'title': 'Story Builder',
      'description':
          'Create funny and heartwarming stories together by taking turns adding sentences.',
      'imageUrl': 'assets/images/gamesCatalogImage/games3.jpg',
    },
    {
      'title': 'Drawing Duel',
      'description':
          'Take turns drawing while the other guesses! A great way to laugh and get creative together.',
      'imageUrl': 'assets/images/gamesCatalogImage/games4.png',
    },
  ];

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Catalog Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: Text(
                  'Games Catalog',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade800,
                  ),
                ),
              ),

              // Games List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _games.length,
                  itemBuilder: (context, index) {
                    final game = _games[index];
                    return GameListItem(game: game);
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

// Game list item widget
class GameListItem extends StatelessWidget {
  final Map<String, dynamic> game;

  const GameListItem({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Game image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: SizedBox(
                width: 120,
                child: Container(
                  color: Colors.orange.shade300,
                  child: Image.asset(
                    game['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.orange.shade100,
                        child: Center(
                          child: Icon(
                            Icons.gamepad,
                            size: 40,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Game info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          game['description'] ?? 'No description available',
                          style: TextStyle(color: Colors.black, fontSize: 11),
                          textAlign: TextAlign.justify,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // ignore: sized_box_for_whitespace
                    Container(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          game['link'] != null
                              ? ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GameLobbyScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade300,
                                  foregroundColor: Colors.black54,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 16,
                                  ),
                                ),
                                child: const Text(
                                  'Play Now',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              : Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                child: const Text(
                                  'Coming Soon',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
