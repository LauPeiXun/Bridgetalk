
import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';
import 'package:bridgetalk/presentation/widgets/others/chat_member_list_item.dart';
import 'package:bridgetalk/application/controller/chat/chat_lobby_controller.dart';
import 'package:bridgetalk/presentation/screens/chat/chat_room_screen.dart';

class ChatLobbyScreen extends StatefulWidget {
  const ChatLobbyScreen({super.key});

  @override
  State<ChatLobbyScreen> createState() => ChatLobbyScreenState();
}

class ChatLobbyScreenState extends State<ChatLobbyScreen> {
  final ChatLobbyController _chatLobbyController = ChatLobbyController();

  @override
  void initState() {
    super.initState();
    _chatLobbyController.requestNotificationPermission();
    _chatLobbyController.initializeFirebaseMessaging();
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Expanded(child: _buildUserList())],
        ),
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 0),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatLobbyController.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Text("Data is loading...", style: TextStyle(fontSize: 14)),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            (snapshot.data as List).isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshPage,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.10,
                ),
                child: Text(
                  "Your family is waiting! 🌟 Go to the Spark tab and connect with your loved ones!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }

        final shuffledList = List.from(snapshot.data!);

        return RefreshIndicator(
          onRefresh: _refreshPage,
          child: ListView(
            children:
                (shuffledList)
                    .map<Widget>(
                      (userData) => _buildUserListItem(userData, context),
                    )
                    .toList(),
          ),
        );
      },
    );
  }

  Future<void> _refreshPage() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    return ChatMemberListItem(
      uid: userData['uid'],
      username: userData['username'],
      mood: userData['mood'],
      emoji: userData['emoji'],
      gender: userData['gender'],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatRoom(
                  receiverId: userData['uid'],
                  emoji: userData['emoji'],
                  receiverMood: userData['mood'],
                  username: userData['username'],
                  userRole: userData['role'],
                ),
          ),
        );
      },
    );
  }
}
