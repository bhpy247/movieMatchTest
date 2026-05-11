import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Stream<List<UsersTableData>> watchAllUsers() =>
      select(usersTable).watch();

  Future<List<UsersTableData>> getAllUsers() =>
      select(usersTable).get();

  Future<List<UsersTableData>> getPendingUsers() =>
      (select(usersTable)..where((u) => u.pendingSync.equals(true))).get();

  Future<int> insertUser(UsersTableCompanion user) =>
      into(usersTable).insert(user);

  Future<UsersTableData?> getUserById(int id) =>
      (select(usersTable)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<void> markSynced(int localId, int serverId) =>
      (update(usersTable)..where((u) => u.id.equals(localId))).write(
        UsersTableCompanion(
          serverId:    Value(serverId),
          pendingSync: const Value(false),
        ),
      );

  // ✅ NEW: Upsert Reqres user by serverId
  // Returns localId — used as FK in saved_movies
  Future<int> upsertReqresUser({
    required int    serverId,
    required String firstName,
    required String lastName,
    required String email,
    required String avatarUrl,
  }) async {
    // Check if already exists
    final existing = await (select(usersTable)
      ..where((u) => u.serverId.equals(serverId)))
        .getSingleOrNull();

    if (existing != null) return existing.id; // already in DB, return localId

    // Insert new
    return into(usersTable).insert(UsersTableCompanion.insert(
      serverId:    Value(serverId),
      firstName:   firstName,
      lastName:    Value(lastName),
      email:       Value(email),
      avatarUrl:   Value(avatarUrl),
      pendingSync: const Value(false),
    ));
  }
}