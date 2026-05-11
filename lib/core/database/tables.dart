import 'package:drift/drift.dart';

// ── users ──────────────────────────────────────────────────────
class UsersTable extends Table {
  @override
  String get tableName => 'users';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get avatarUrl => text().withDefault(const Constant(''))();
  TextColumn get movieTaste => text().withDefault(const Constant(''))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── movies ─────────────────────────────────────────────────────
class MoviesTable extends Table {
  @override
  String get tableName => 'movies';

  IntColumn get id => integer()();
  IntColumn get movieId => integer()();
  TextColumn get title => text()();
  TextColumn get overview => text().withDefault(const Constant(''))();
  TextColumn get posterPath => text().withDefault(const Constant(''))();
  TextColumn get releaseDate => text().withDefault(const Constant(''))();
  RealColumn get voteAverage => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── saved_movies (junction) ────────────────────────────────────
class SavedMoviesTable extends Table {
  @override
  String get tableName => 'saved_movies';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(UsersTable, #id)();
  IntColumn get movieId => integer().references(MoviesTable, #movieId)();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, movieId},
      ];
}
