import 'package:bridgetalk/data/repositories/mood_repository.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';
import 'package:bridgetalk/presentation/screens/mood_select/set_mood.dart';
import 'package:flutter/foundation.dart';
import 'package:bridgetalk/data/models/user_model.dart';
import 'package:flutter/material.dart';

import 'package:bridgetalk/presentation/screens/user_profile/user_profile_screen.dart';
import 'package:bridgetalk/presentation/screens/chat/chat_lobby_screen.dart';
import 'package:bridgetalk/presentation/screens/mood_select/change_mood_screen.dart';
import 'package:bridgetalk/presentation/screens/game/game_catalog_screen.dart';
import 'package:bridgetalk/presentation/screens/connection/parent_link_screen.dart';
import 'package:bridgetalk/presentation/screens/connection/child_link_screen.dart';

class NavBarController {
  final UserRepository userRepository = UserRepository();
  final MoodRepository moodRepository = MoodRepository();
  String? todayMood, todayEmoji;

  Future<Widget?> getNavigationTarget(int index) async {
    final UserModel? user = await userRepository.getCurrentUserModel();
    List<Widget> pages = [];

    if (user!.role == 'Child' || user.role == 'child') {
      pages = [
        const ChatLobbyScreen(),
        const GamesCatalogScreen(),
        const ChangeMoodScreen(),
        const ChildLinkScreen(),
        const ProfilePage(),
      ];
    } else if (user.role == 'Parent' || user.role == 'parent') {
      pages = [
        const ChatLobbyScreen(),
        const GamesCatalogScreen(),
        const ChangeMoodScreen(),
        const ParentLinkScreen(),
        const ProfilePage(),
      ];
    }

    return pages[index];
  }

  Future<String> getUserRole() async {
    final UserModel? user = await userRepository.getCurrentUserModel();
    return user!.role!;
  }

  Future<void> loadTodayMood(BuildContext context) async {
    final UserModel? user = await userRepository.getCurrentUserModel();

    if (user == null) return;
    final uid = user.uid;

    try {
      final doc = await moodRepository.getCurrentMood(uid!);

      if (doc != null) {
        todayMood = doc.mood;
        todayEmoji = doc.emoji;
      } else {
        if (todayMood == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SetMoodPage()),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading mood: $e");
      }
    }
  }
}