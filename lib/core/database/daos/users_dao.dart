import 'package:drift/drift.dart';
import '../../../models/user_model.dart';
import '../app_database.dart';
import '../tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Stream<List<UserData>> watchAllUsers() => select(usersTable).watch();

  Future<List<UserData>> getAllUsers() => select(usersTable).get();

  Future<List<UserData>> getPendingUsers() =>
      (select(usersTable)..where((u) => u.pendingSync.equals(true))).get();

  Future<int> insertUser(UsersTableCompanion user) => into(usersTable).insert(user);

  Future<UserData?> getUserById(int id) =>
      (select(usersTable)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<void> markSynced(int localId, int serverId) =>
      (update(usersTable)..where((u) => u.id.equals(localId))).write(
        UsersTableCompanion(
          serverId: Value(serverId),
          pendingSync: const Value(false),
        ),
      );
}
