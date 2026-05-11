
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../netwok/dio_client.dart';

const _kSyncTask = 'syncPendingUsers';

// Top-level — required by WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task == _kSyncTask) await _syncPendingUsers();
    return true;
  });
}

Future<void> _syncPendingUsers() async {
  final db = AppDatabase();
  final dio = DioClient.reqres;

  final pending = await db.usersDao.getPendingUsers();

  for (final user in pending) {
    try {
      final res = await dio.post('/users', data: {
        'name': '${user.firstName} ${user.lastName}'.trim(),
        'job': user.movieTaste,
      });
      final rawId = res.data['id'];
      if (rawId != null) {
        await db.usersDao.markSynced(
          user.id,
          int.tryParse('$rawId') ?? 0,
        );
      }
    } catch (_) {
      // Silently skip — WorkManager will retry next run
    }
  }

  await db.close();
}

// Call this whenever connectivity is restored
void scheduleSync() {
  Workmanager().registerOneOffTask(
    _kSyncTask,
    _kSyncTask,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}
