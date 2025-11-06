import 'package:cloud_firestore/cloud_firestore.dart';

class MoodModel {
  final String mood;
  final String emoji;
  final DateTime? timestamp;

  MoodModel({
    required this.mood,
    required this.emoji,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'mood': mood,
      'emoji': emoji,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory MoodModel.fromMap(Map<String, dynamic> map) {
    return MoodModel(
      mood: map['mood'] as String,
      emoji: map['emoji'] as String,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }
} 