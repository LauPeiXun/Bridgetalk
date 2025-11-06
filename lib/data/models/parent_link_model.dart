import 'package:cloud_firestore/cloud_firestore.dart';

class ParentLinkModel {
  final String? id;
  final String? childId;
  final String? parentId;
  final String? parentRole;
  final int sparkPoint;
  final DateTime? createdAt;
  final String? childUsername;
  final DateTime? lastChat;

  ParentLinkModel({
    this.id,
    this.childId,
    this.parentId,
    this.parentRole,
    this.sparkPoint = 0,
    this.createdAt,
    this.childUsername,
    this.lastChat,
  });

  factory ParentLinkModel.fromMap(Map<String, dynamic> map, String docId) {
    return ParentLinkModel(
      id: docId,
      childId: map['childId']?.toString(),
      parentId: map['parentId']?.toString(),
      parentRole: map['parentRole']?.toString(),
      sparkPoint: map['sparkPoint'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      childUsername: map['childUsername']?.toString(),
      lastChat: (map['lastChat'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'parentId': parentId,
      'parentRole': parentRole,
      'sparkPoint': sparkPoint,
      'createdAt': createdAt,
      'childUsername': childUsername,
      'lastChat': lastChat,
    };
  }

  ParentLinkModel copyWith({
    String? id,
    String? childId,
    String? parentId,
    String? parentRole,
    int? sparkPoint,
    DateTime? createdAt,
    String? childUsername,
    DateTime? lastChat,
  }) {
    return ParentLinkModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      parentRole: parentRole ?? this.parentRole,
      sparkPoint: sparkPoint ?? this.sparkPoint,
      createdAt: createdAt ?? this.createdAt,
      childUsername: childUsername ?? this.childUsername,
      lastChat: lastChat ?? this.lastChat,
    );
  }
}
