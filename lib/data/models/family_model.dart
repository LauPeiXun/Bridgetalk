import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final List<String> memberIds;
  final Timestamp createdAt;

  FamilyModel({
    required this.id,
    required this.memberIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberIds': memberIds,
      'createdAt': createdAt,
    };
  }

  factory FamilyModel.fromMap(Map<String, dynamic> map, String docId) {
    return FamilyModel(
      id: docId,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}