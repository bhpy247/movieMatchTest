import 'package:drift/drift.dart';
import '../../../models/movie_model.dart';
import '../../../models/user_model.dart';
import '../app_database.dart';
import '../tables.dart';

part 'movies_dao.g.dart';

class MovieMatchResult {
  final MovieData movie;
  final int saveCount;
  final List<UserData> users;
  const MovieMatchResult({
    required this.movie,
    required this.saveCount,
    required this.users,
  });
}

@DriftAccessor(tables: [MoviesTable, SavedMoviesTable, UsersTable])
class MoviesDao extends DatabaseAccessor<AppDatabase> with _$MoviesDaoMixin {
  MoviesDao(super.db);

  // Future<void> upsertMovie(MoviesTableCompanion movie) =>
  //     into(moviesTable).insertOnConflictUpdate(movie);

  Future<void> saveMovie(int userId, int movieId) => into(savedMoviesTable).insertOnConflictUpdate(
        SavedMoviesTableCompanion.insert(userId: userId, movieId: movieId),
      );

  Future<void> unsaveMovie(int userId, int movieId) =>
      (delete(savedMoviesTable)..where((s) => s.userId.equals(userId) & s.movieId.equals(movieId)))
          .go();

  Future<bool> isMovieSaved(int userId, int movieId) async {
    final row = await (select(savedMoviesTable)
          ..where((s) => s.userId.equals(userId) & s.movieId.equals(movieId)))
        .getSingleOrNull();
    return row != null;
  }

  // Live badge count for a movie
  Stream<int> watchSaveCount(int movieId) {
    final count = savedMoviesTable.id.count();
    final q = selectOnly(savedMoviesTable)
      ..addColumns([count])
      ..where(savedMoviesTable.movieId.equals(movieId));
    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }

  // All saved movies for a user — works offline
  Stream<List<MovieData>> watchSavedMoviesForUser(int userId) {
    final q = select(moviesTable).join([
      innerJoin(
        savedMoviesTable,
        savedMoviesTable.movieId.equalsExp(moviesTable.tmdbId),
      ),
    ])
      ..where(savedMoviesTable.userId.equals(userId));
    return q.map((r) => r.readTable(moviesTable)).watch();
  }

  Future<int> getSaveCountForUser(int userId) async {
    final count = savedMoviesTable.id.count();
    final q = selectOnly(savedMoviesTable)
      ..addColumns([count])
      ..where(savedMoviesTable.userId.equals(userId));
    final row = await q.getSingle();
    return row.read(count) ?? 0;
  }

  // Matches page — movies saved by 2+ users
  Stream<List<MovieMatchResult>> watchMatches() {
    final saveCount = savedMoviesTable.id.count();
    final q = select(moviesTable).join([
      innerJoin(
        savedMoviesTable,
        savedMoviesTable.movieId.equalsExp(moviesTable.tmdbId),
      ),
    ])
      ..addColumns([saveCount])
      ..groupBy([moviesTable.tmdbId])
      // ..having(saveCount.isBiggerOrEqualValue(2))
      ..orderBy([OrderingTerm.desc(saveCount)]);

    return q.watch().asyncMap((rows) async {
      final results = <MovieMatchResult>[];
      for (final row in rows) {
        final movie = row.readTable(moviesTable);
        final count = row.read(saveCount) ?? 0;
        final userRows = await (select(savedMoviesTable).join([
          innerJoin(usersTable, usersTable.id.equalsExp(savedMoviesTable.userId)),
        ])
              ..where(savedMoviesTable.movieId.equals(movie.tmdbId)))
            .map((r) => r.readTable(usersTable))
            .get();
        results.add(MovieMatchResult(movie: movie, saveCount: count, users: userRows));
      }
      return results;
    });
  }
}
