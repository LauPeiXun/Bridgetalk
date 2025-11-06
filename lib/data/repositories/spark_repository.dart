import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import '../models/parent_link_model.dart';
import '../models/child_link_model.dart';

class SparkPointRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 可选：生成连接 ID，用于手动拼接 document ID（例如 abc123_xyz456）
  String generateConnectionId(String parentId, String childId) {
    final ids = [parentId, childId]..sort();
    return ids.join('_');
  }

  /// 判断两个时间是否是同一天
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 🔥 父母端调用
  Future<void> tryIncreaseSparkPointFromParentModel(
    ParentLinkModel model,
  ) async {
    final connectionId = model.id;
    final parentId = model.parentId;
    final childId = model.childId;

    if (connectionId == null || parentId == null || childId == null) return;

    final lastChat = model.lastChat;
    final now = DateTime.now();

    if (lastChat != null && _isSameDay(lastChat, now)) return;

    final newValue = (model.sparkPoint + 5).clamp(0, double.infinity).toInt();
    await _firestore.collection('connections').doc(connectionId).update({
      'sparkPoint': newValue,
      'lastChat': Timestamp.fromDate(now),
    });
  }

  /// 🔥 孩子端调用
  Future<void> tryIncreaseSparkPointFromChildModel(ChildLinkModel model) async {
    final connectionId = model.id;
    final parentId = model.parentId;
    final childId = model.childId;

    if (connectionId == null || parentId == null || childId == null) return;

    final lastChat = model.lastChat;
    final now = DateTime.now();

    if (lastChat != null && _isSameDay(lastChat, now)) return;

    final newValue = (model.sparkPoint + 5).clamp(0, double.infinity).toInt();
    await _firestore.collection('connections').doc(connectionId).update({
      'sparkPoint': newValue,
      'lastChat': Timestamp.fromDate(now),
    });
  }

  /// 获取 connectionId（与 chatRoomId 规则一致）
  Future<String> getConnectionId(String parentId, String childId) async {
    final ids = [parentId, childId]..sort();
    return ids.join('_');
  }

  /// 获取最后聊天时间
  Future<DateTime?> getLastChatDate(String connectionId) async {
    final doc =
        await _firestore.collection('connections').doc(connectionId).get();
    final timestamp = doc.data()?['lastChat'] as Timestamp?;
    return timestamp?.toDate();
  }

  /// 获取当前 sparkPoint 值
  Future<int> getSparkPoint(String connectionId) async {
    final doc =
        await _firestore.collection('connections').doc(connectionId).get();
    return (doc.data()?['sparkPoint'] ?? 0) as int;
  }

  /// 更新 sparkPoint 值（自动 clamp 至 >= 0）
  Future<void> updateSparkPoint(String connectionId, int newValue) async {
    final safeValue = newValue < 0 ? 0 : newValue;
    await _firestore.collection('connections').doc(connectionId).update({
      'sparkPoint': safeValue,
    });
  }

  /// 更新最后聊天时间
  Future<void> updateLastChatDate(String connectionId, DateTime now) async {
    await _firestore.collection('connections').doc(connectionId).update({
      'lastChat': Timestamp.fromDate(now),
    });
  }

  Future<List<Map<String, dynamic>>> getConnectionsWithSpark(
    String userId,
    String role,
  ) async {
    final query = _firestore.collection('connections');
    QuerySnapshot snapshot;

    if (role.toLowerCase() == 'parent') {
      snapshot = await query.where('parentId', isEqualTo: userId).get();
    } else if (role.toLowerCase() == 'child') {
      snapshot = await query.where('childId', isEqualTo: userId).get();
    } else {
      return [];
    }

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'connectionId': doc.id,
        'parentId': data['parentId'],
        'childId': data['childId'],
        'sparkPoint': data['sparkPoint'],
        'lastChat': data['lastChat'],
        'parentRole': data['parentRole'],
      };
    }).toList();
  }

  /// ✅ 游戏结束时调用：不限制每日，只要结束就加1
  Future<void> increaseSparkPointAfterGame(
    String parentId,
    String childId,
  ) async {
    final connectionId = generateConnectionId(parentId, childId);

    final docRef = _firestore.collection('connections').doc(connectionId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final currentPoint = (doc.data()?['sparkPoint'] ?? 0) as int;
    final newValue = (currentPoint + 1).clamp(0, double.infinity).toInt();

    await docRef.update({'sparkPoint': newValue});
  }

  Future<void> increaseSparkPointByConnection(String id1, String id2) async {
    final query1 = _firestore
        .collection('connections')
        .where('parentId', isEqualTo: id1)
        .where('childId', isEqualTo: id2)
        .limit(1);

    final query2 = _firestore
        .collection('connections')
        .where('parentId', isEqualTo: id2)
        .where('childId', isEqualTo: id1)
        .limit(1);

    final result1 = await query1.get();
    final result2 = result1.docs.isNotEmpty ? null : await query2.get();

    final doc =
        result1.docs.isNotEmpty ? result1.docs.first : result2?.docs.first;

    if (doc == null) {
      debugPrint('⚠️ No connection document found between $id1 and $id2');
      return;
    }

    final currentPoint = (doc.data()['sparkPoint'] ?? 0) as int;
    final updated = currentPoint + 1;

    await doc.reference.update({'sparkPoint': updated});
    debugPrint('✅ SparkPoint increased to $updated for connection: ${doc.id}');
  }
}
