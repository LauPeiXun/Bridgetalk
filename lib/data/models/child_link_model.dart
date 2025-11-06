import 'package:cloud_firestore/cloud_firestore.dart';

class ChildLinkModel {
  final String? id;
  final String? username;
  final String? parentRole;
  final int sparkPoint;
  final String? childId;
  final String? parentId;
  final DateTime? createdAt;
  final DateTime? lastChat;

  ChildLinkModel({
    this.id,
    this.username,
    this.parentRole,
    this.sparkPoint = 0,
    this.childId,
    this.parentId,
    this.createdAt,
    this.lastChat,
  });

  factory ChildLinkModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return ChildLinkModel(
      id: docId,
      username: data['username'],
      parentRole: data['parentRole'],
      sparkPoint: data['sparkPoint'] ?? 0,
      childId: data['childId'],
      parentId: data['parentId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastChat: (data['lastChat'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'parentRole': parentRole,
      'sparkPoint': sparkPoint,
      'childId': childId,
      'parentId': parentId,
      'createdAt': createdAt,
      'lastChat': lastChat,
    };
  }

  ChildLinkModel copyWith({
    String? id,
    String? username,
    String? parentRole,
    int? sparkPoint,
    String? childId,
    String? parentId,
    DateTime? createdAt,
    DateTime? lastChat,
  }) {
    return ChildLinkModel(
      id: id ?? this.id,
      username: username ?? this.username,
      parentRole: parentRole ?? this.parentRole,
      sparkPoint: sparkPoint ?? this.sparkPoint,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      lastChat: lastChat ?? this.lastChat,
    );
  }
}
