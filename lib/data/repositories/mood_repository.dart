import 'package:bridgetalk/data/models/mood_model.dart';
import 'package:bridgetalk/Insfrastructure/firebase_services/firestore_service.dart';

class MoodRepository {
  final FirestoreService firestoreService = FirestoreService();

  Future<void> saveMood(String userId, MoodModel mood) async {
    final today = _getTodayDate();
    await firestoreService.setModel(
      collection: 'users/$userId/moods',
      docId: today,
      model: mood,
      toMap: (mood) => mood.toMap(),
    );
  }

  Future<void> updateMood(String userId, MoodModel mood) async {
    final today = _getTodayDate();
    await firestoreService.setModel(
      collection: 'users/$userId/moods',
      docId: today,
      model: mood,
      toMap: (mood) => mood.toMap(),
    );
  }

  Future<MoodModel?> getCurrentMood(String userId) async {
    final today = _getTodayDate();
    return await firestoreService.getModel(
      collection: 'users/$userId/moods',
      docId: today,
      fromMap: (map) => MoodModel.fromMap(map),
    );
  }

  Future<void> deleteCurrentUserMood(String uid, String date) async {
    try {
      await firestoreService.deleteDataByPath(
        pathSegments: ['users', uid, 'moods', date],
      );
    } catch (e) {
      rethrow;
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
