import 'package:flutter/material.dart';
import 'dart:math';
import 'package:bridgetalk/presentation/screens/chat/chat_lobby_screen.dart';
import 'package:bridgetalk/application/controller/mood/set_mood_controller.dart';

class SetMoodPage extends StatefulWidget {
  const SetMoodPage({super.key});

  @override
  SetMoodPageState createState() => SetMoodPageState();
}

class SetMoodPageState extends State<SetMoodPage> {
  late final SetMoodController _controller;
  String selectedMood = 'Happy / Content';
  String selectedEmoji = '😊';

  final Map<String, String> moods = {
    '😘': 'Affectionate / Loving',
    '😴': 'Tired / Sleepy',
    '🤢': 'Sick',
    '😭': 'Sad / Heartbroken',
    '😡': 'Angry',
    '😌': 'Calm / Relaxed',
    '😕': 'Uncertain / Unsure',
    '🥺': 'Needy / Emotional',
    '☹️': 'Unhappy / Disappointed',
    '😊': 'Happy / Content',
    '🤔': 'Thoughtful / Curious',
    '😆': 'Excited / Laughing',
  };

  @override
  void initState() {
    super.initState();
    _controller = SetMoodController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectMood(String emoji) {
    setState(() {
      selectedEmoji = emoji;
      selectedMood = moods[emoji]!;
    });
  }

  Future<void> _saveTodayMood() async {
    if (_controller.isLoading) return;

    try {
      await _controller.saveMood(selectedMood, selectedEmoji);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChatLobbyScreen()),
      );
    } catch (e) {
      debugPrint("Error saving mood: $e");
    }
  }

  Widget _buildEmojiCircle() {
    return SizedBox(
      width: 380,
      height: 380,
      child: Stack(
        key: const ValueKey('emoji_circle'),
        alignment: Alignment.center,
        children: [
          Text(
            selectedEmoji,
            key: ValueKey('center_emoji_$selectedEmoji'),
            style: const TextStyle(fontSize: 100),
          ),
          ...List.generate(moods.length, (index) {
            final angle = (index / moods.length) * 2 * pi;
            final radius = 135.0;
            final x = radius * cos(angle);
            final y = radius * sin(angle);
            final emoji = moods.keys.elementAt(index);

            return Positioned(
              key: ValueKey('emoji_$emoji'),
              left: 190 + x - 25,
              top: 190 + y - 25,
              child: GestureDetector(
                onTap: () => _selectMood(emoji),
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              key: const ValueKey('mood_scroll_view'),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 30,
              ),
              child: Column(
                key: const ValueKey('mood_column'),
                children: [
                  const Text(
                    'Hi! How do you feel today?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$selectedMood $selectedEmoji',
                    key: ValueKey('mood_text_$selectedEmoji'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    key: const ValueKey('emoji_circle_boundary'),
                    child: _buildEmojiCircle(),
                  ),
                  const SizedBox(height: 24),
                  if (_controller.isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(300, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _saveTodayMood,
                      child: const Text(
                        'Set My Mood',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
