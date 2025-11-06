import 'package:flutter/material.dart';
import 'package:bridgetalk/presentation/screens/chat/chat_lobby_screen.dart';
import 'package:bridgetalk/presentation/screens/mood_select/set_mood.dart';
import 'package:bridgetalk/application/controller/mood/set_mood_controller.dart';

class MoodGatePage extends StatefulWidget {
  const MoodGatePage({super.key});

  @override
  State<MoodGatePage> createState() => _MoodGatePageState();
}

class _MoodGatePageState extends State<MoodGatePage> {
  late final SetMoodController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SetMoodController();
    _checkMood();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkMood() async {
    try {
      final hasMood = await _controller.checkTodayMood();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  hasMood ? const ChatLobbyScreen() : const SetMoodPage(),
        ),
      );
    } catch (e) {
      debugPrint("Error checking mood: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
