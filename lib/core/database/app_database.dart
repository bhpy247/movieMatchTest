import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/movies_dao.dart';
import 'daos/users_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [UsersTable, MoviesTable, SavedMoviesTable],
  daos: [UsersDao, MoviesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  static QueryExecutor _openConnection() => driftDatabase(name: 'movie_match_db');
}
