import 'package:bridgetalk/data/models/game_model.dart';
import 'package:bridgetalk/presentation/screens/game/lobby_detail_screen.dart';
import 'package:bridgetalk/application/controller/game/game_lobby_controller.dart';
import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';


class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  final GameLobbyController _controller = GameLobbyController();
  String? _familyId;

  @override
  void initState() {
    super.initState();
    _initializeFamilyId();
  }

  Future<void> _initializeFamilyId() async {
    _familyId = await _controller.initializeConnectionId();
    setState(() {});
  }

  Future<void> _createNewLobby() async {
    try {

      final String lobbyId = await _controller.createNewLobby();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyDetailScreen(lobbyId: lobbyId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create lobby: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade300,
          ),
        );
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
        child: SafeArea(
          child: Column(
            children: [
              // Header with create button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Game Lobbies',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD84315),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _createNewLobby,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade300,
                      ),
                      child: const Text(
                        'Create New Lobby',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Lobby list
              Expanded(
                child: _familyId == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildLobbyList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 1),
    );
  }

  Widget _buildLobbyList() {
    return StreamBuilder<List<Lobby>>(
      stream: _controller.lobbiesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No lobbies available. Create one!'));
        }

        final lobbies = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: lobbies.length,
          itemBuilder: (context, index) {
            final lobby = lobbies[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.orange.shade50,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lobby ID: ${lobby.id.length >= 5 ? lobby.id.substring(0, 5) : lobby.id}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Click to join',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.orange,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LobbyDetailScreen(lobbyId: lobby.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}