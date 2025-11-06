import 'package:bridgetalk/data/models/user_model.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:bridgetalk/data/models/mood_model.dart';
import 'package:bridgetalk/data/repositories/mood_repository.dart';

class SetMoodController extends ChangeNotifier {
  final MoodRepository _repository = MoodRepository();
  final UserRepository userRepository = UserRepository();
  bool _isLoading = false;
  MoodModel? _currentMood;

  bool get isLoading => _isLoading;
  MoodModel? get currentMood => _currentMood;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> saveMood(String mood, String emoji) async {
    _setLoading(true);

    UserModel? user = await userRepository.getCurrentUserModel();
    if (user == null) return;

    try {
      final moodModel = MoodModel(mood: mood, emoji: emoji);
      await _repository.saveMood(user.uid!, moodModel);
      _currentMood = moodModel;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkTodayMood() async {
    _setLoading(true);

    UserModel? user = await userRepository.getCurrentUserModel();
    if (user == null) return false;

    try {
      _currentMood = await _repository.getCurrentMood(user.uid!);
      return _currentMood != null;
    } finally {
      _setLoading(false);
    }
  }
}
