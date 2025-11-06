import 'package:bridgetalk/data/models/user_model.dart';
import 'package:bridgetalk/data/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bridgetalk/data/models/mood_model.dart';
import 'package:bridgetalk/data/repositories/mood_repository.dart';

class ChangeMoodController extends ChangeNotifier {
  final MoodRepository _repository = MoodRepository();
  final UserRepository userRepository = UserRepository();
  bool _isLoading = false;
  MoodModel? _currentMood;

  bool get isLoading => _isLoading;
  MoodModel? get currentMood => _currentMood;

  Future<void> updateMood(String mood, String emoji) async {
    final UserModel? user = await userRepository.getCurrentUserModel();

    if (user == null) return;
    final uid = user.uid;

    _isLoading = true;
    notifyListeners();

    try {
      final moodModel = MoodModel(mood: mood, emoji: emoji);
      await _repository.updateMood(uid!, moodModel);
      _currentMood = moodModel;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentMood() async {
    final UserModel? user = await userRepository.getCurrentUserModel();

    if (user == null) return;
    final uid = user.uid;

    _isLoading = true;
    notifyListeners();

    try {
      _currentMood = await _repository.getCurrentMood(uid!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
