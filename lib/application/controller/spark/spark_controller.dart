// spark_controller.dart
import 'package:bridgetalk/data/repositories/spark_repository.dart';
import 'package:intl/intl.dart';

class SparkPointController {
  final SparkPointRepository _sparkRepo = SparkPointRepository();

  Future<void> onMessageSent(String parentId, String childId) async {
    final connectionId = await _sparkRepo.getConnectionId(parentId, childId);

    final lastChat = await _sparkRepo.getLastChatDate(connectionId);
    final now = DateTime.now();

    // Compare dates (only date, not time)
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final lastChatStr =
        lastChat != null ? DateFormat('yyyy-MM-dd').format(lastChat) : null;

    if (lastChatStr == todayStr) return; // Already added today

    final currentPoint = await _sparkRepo.getSparkPoint(connectionId);
    await _sparkRepo.updateSparkPoint(connectionId, currentPoint + 5);
    await _sparkRepo.updateLastChatDate(connectionId, now);
  }

  Future<List<Map<String, dynamic>>> getSparkDataForUser(
    String userId,
    String role,
  ) async {
    return await _sparkRepo.getConnectionsWithSpark(userId, role);
  }

}
