import 'package:bridgetalk/presentation/widgets/general_widgets/widgets.dart';
import 'dart:math';
import 'package:bridgetalk/application/controller/mood/change_mood_contoller.dart';

class ChangeMoodScreen extends StatefulWidget {
  const ChangeMoodScreen({super.key});

  @override
  State<ChangeMoodScreen> createState() => _ChangeMoodScreenState();
}

class _ChangeMoodScreenState extends State<ChangeMoodScreen> {
  final ChangeMoodController changeMoodController = ChangeMoodController();
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
    _loadTodayMood();
  }

  Future<void> _loadTodayMood() async {
    try {
      await changeMoodController.loadCurrentMood();

      if (!mounted) return;

      final currentMood = changeMoodController.currentMood;
      if (currentMood != null) {
        setState(() {
          selectedMood = currentMood.mood;
          selectedEmoji = currentMood.emoji;
        });
      }
    } catch (e) {
      debugPrint("Error loading mood: $e");
    }
  }

  void _selectMood(String emoji) {
    setState(() {
      selectedEmoji = emoji;
      selectedMood = moods[emoji]!;
    });
  }

  Future<void> _updateMood() async {
    try {
      await changeMoodController.updateMood(selectedMood, selectedEmoji);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Your mood is now set to $selectedMood $selectedEmoji.",
            style: TextStyle(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          duration: Duration(milliseconds: 1100),
          backgroundColor: MoodColorUtil.getMoodColor(selectedEmoji)[0],
        ),
      );
    } catch (e) {
      debugPrint("Error updating mood: $e");
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
                    'Ready for a Mood Refresh?',
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 380,
                    width: 380,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          selectedEmoji,
                          style: const TextStyle(fontSize: 100),
                        ),
                        ...List.generate(moods.length, (index) {
                          final angle = (index / moods.length) * 2 * pi;
                          final radius = 135.0;
                          final x = radius * cos(angle);
                          final y = radius * sin(angle);
                          final emoji = moods.keys.elementAt(index);

                          return Positioned(
                            left: 185 + x - 25,
                            top: 185 + y - 25,
                            child: GestureDetector(
                              onTap: () => _selectMood(emoji),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (changeMoodController.isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(300, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.all(0),
                      ),
                      onPressed: _updateMood,
                      child: const Text(
                        'Refresh My Mood',
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
      bottomNavigationBar: CustomNavBar(currentIndex: 2),
    );
  }
}
