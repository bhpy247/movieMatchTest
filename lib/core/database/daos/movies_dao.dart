import 'package:drift/drift.dart';

import '../../../models/movie_model.dart';
import '../app_database.dart';
import '../tables.dart';

part 'movies_dao.g.dart';

class MovieMatchResult {
  final MovieData movie;
  final int saveCount;
  final List<UsersTableData> users;

  const MovieMatchResult({
    required this.movie,
    required this.saveCount,
    required this.users,
  });
}

@DriftAccessor(
  tables: [
    MoviesTable,
    SavedMoviesTable,
    UsersTable,
  ],
)
class MoviesDao extends DatabaseAccessor<AppDatabase> with _$MoviesDaoMixin {
  MoviesDao(super.db);

  /// Insert or update movie
  Future<void> upsertMovie(MoviesTableCompanion movie) async {
    try {
      print("========== UPSERT MOVIE ==========");
      print("Movie Title: ${movie.title}");
      print("==================================");

      await into(moviesTable).insertOnConflictUpdate(movie);

      print("Movie upserted successfully");
    } catch (e) {
      print("Upsert movie error: $e");
    }
  }

  /// Save movie for user
  ///
  /// IMPORTANT:
  /// movieId should be TMDB ID because
  /// joins are done with moviesTable.tmdbId
  Future<void> saveMovie(int userId, int movieId) async {
    try {
      print("========== SAVE MOVIE ==========");
      print("User ID: $userId");
      print("Movie ID: $movieId");

      final result = await into(savedMoviesTable).insertOnConflictUpdate(
        SavedMoviesTableCompanion.insert(
          userId: userId,
          movieId: movieId,
        ),
      );

      print("Save Result: $result");

      // Debug database after save
      await debugSavedMovies();

      final isSaved = await isMovieSaved(userId, movieId);

      print("Is Movie Saved After Insert: $isSaved");
      print("================================");
    } catch (e) {
      print("Save movie error: $e");
    }
  }

  /// Remove saved movie
  Future<void> unsaveMovie(int userId, int movieId) async {
    try {
      print("========== UNSAVE MOVIE ==========");
      print("User ID: $userId");
      print("Movie ID: $movieId");

      final result = await (delete(savedMoviesTable)
            ..where(
              (s) => s.userId.equals(userId) & s.movieId.equals(movieId),
            ))
          .go();

      print("Rows Deleted: $result");

      await debugSavedMovies();

      print("==================================");
    } catch (e) {
      print("Unsave movie error: $e");
    }
  }

  /// Check if movie is saved
  Future<bool> isMovieSaved(
    int userId,
    int movieId,
  ) async {
    try {
      final row = await (select(savedMoviesTable)
            ..where(
              (s) => s.userId.equals(userId) & s.movieId.equals(movieId),
            ))
          .getSingleOrNull();

      print("========== IS MOVIE SAVED ==========");
      print("User ID: $userId");
      print("Movie ID: $movieId");
      print("Result: ${row != null}");
      print("====================================");

      return row != null;
    } catch (e) {
      print("Is movie saved error: $e");
      return false;
    }
  }

  /// Watch save count for movie
  Stream<int> watchSaveCount(int movieId) {
    final count = savedMoviesTable.id.count();

    final q = selectOnly(savedMoviesTable)
      ..addColumns([count])
      ..where(savedMoviesTable.movieId.equals(movieId));

    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }

  /// Watch saved movies for user
  ///
  /// IMPORTANT:
  /// savedMoviesTable.movieId MUST match moviesTable.tmdbId
  Stream<List<MovieData>> watchSavedMoviesForUser(
    int userId,
  ) {
    final q = select(moviesTable).join([
      innerJoin(
        savedMoviesTable,
        savedMoviesTable.movieId.equalsExp(
          moviesTable.id,
        ),
      ),
    ])
      ..where(savedMoviesTable.userId.equals(userId));

    return q.map((r) {
      final movie = r.readTable(moviesTable);

      print(
        "Saved Movie Found => "
        "${movie.title} "
        "TMDB: ${movie.id}",
      );

      return movie;
    }).watch();
  }

  Future<void> printSavedMovies() async {
    final rows = await select(savedMoviesTable).get();
    final movieTablerows = await select(moviesTable).get();

    for (final row in rows) {
      print("id: ${row.id}");
      print("movieId: ${row.movieId}");
      print("userId: ${row.userId}");
      // print("MovieId: ${row.movieId}");
      print("-------------------");
    }
    print("-------------------Movie Table -----");
    for (final row in movieTablerows) {
      print("id: ${row.id}");
      print("title: ${row.title}");
      // print("MovieId: ${row.movieId}");
      print("-------------------");
    }
  }

  /// Get total saved movie count for user
  Future<int> getSaveCountForUser(int userId) async {
    try {
      final count = savedMoviesTable.id.count();

      final q = selectOnly(savedMoviesTable)
        ..addColumns([count])
        ..where(savedMoviesTable.userId.equals(userId));

      final row = await q.getSingle();

      final result = row.read(count) ?? 0;

      print("Save Count For User $userId => $result");

      return result;
    } catch (e) {
      print("Get save count error: $e");
      return 0;
    }
  }

  /// Movies saved by multiple users
  Stream<List<MovieMatchResult>> watchMatches() {
    print("Save Count: ");
    final saveCount = savedMoviesTable.id.count();

    final q = select(moviesTable).join([
      innerJoin(
        savedMoviesTable,
        savedMoviesTable.movieId.equalsExp(
          moviesTable.id,
        ),
      ),
    ])
      ..addColumns([saveCount])
      ..groupBy([moviesTable.id])
      ..orderBy([
        OrderingTerm.desc(saveCount),
      ]);

    return q.watch().asyncMap((rows) async {
      final results = <MovieMatchResult>[];

      for (final row in rows) {
        final movie = row.readTable(moviesTable);

        final count = row.read(saveCount) ?? 0;

        final userRows = await (select(savedMoviesTable).join([
          innerJoin(
            usersTable,
            usersTable.id.equalsExp(
              savedMoviesTable.userId,
            ),
          ),
        ])
              ..where(
                savedMoviesTable.movieId.equals(
                  movie.id,
                ),
              ))
            .map((r) => r.readTable(usersTable))
            .get();

        results.add(
          MovieMatchResult(
            movie: movie,
            saveCount: count,
            users: userRows,
          ),
        );
      }

      return results;
    });
  }

  /// DEBUG METHOD
  ///
  /// Prints all saved movie rows
  Future<void> debugSavedMovies() async {
    try {
      final data = await select(savedMoviesTable).get();

      print("========== SAVED MOVIES DEBUG ==========");

      if (data.isEmpty) {
        print("NO SAVED MOVIES FOUND");
      }

      for (final item in data) {
        print(
          "UserId: ${item.userId} | "
          "MovieId: ${item.movieId}",
        );
      }

      print("========================================");
    } catch (e) {
      print("Debug saved movies error: $e");
    }
  }

  /// DEBUG METHOD
  ///
  /// Prints all movies table data
  Future<void> debugMoviesTable() async {
    try {
      final data = await select(moviesTable).get();

      print("========== MOVIES TABLE DEBUG ==========");

      if (data.isEmpty) {
        print("NO MOVIES FOUND");
      }

      for (final item in data) {
        print(
          "ID: ${item.id} | "
          "TMDB ID: ${item.id} | "
          "Title: ${item.title}",
        );
      }

      print("========================================");
    } catch (e) {
      print("Debug movies table error: $e");
    }
  }
}
