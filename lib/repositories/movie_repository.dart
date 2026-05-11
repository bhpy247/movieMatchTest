import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../core/database/daos/movies_dao.dart';
import '../core/database/daos/users_dao.dart';
import '../core/netwok/service_locator.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';

class MovieRepository {
  final MoviesDao _moviesDao = sl<MoviesDao>();
  final UsersDao  _usersDao  = sl<UsersDao>();
  final Dio       _tmdbDio   = sl<Dio>(instanceName: 'tmdb');

  // ── Fetch trending movies (paginated) ─────────────────────────
  Future<List<MovieModel>> fetchTrending({
    int page = 1,
    required int activeUserId,
  }) async {
    try {
      final res = await _tmdbDio.get(
        '/trending/movie/day',
        queryParameters: {'language': 'en-US', 'page': page},
      );
      final List results = res.data['results'] as List;
      print("Movie List : ${results.length}");
      final movies = results.map((e) => MovieModel.fromJson(e)).toList();
      print("Movie List : ${movies.length}");

      for (final m in movies) {
        print("Movie : ${m.id}");

        await _moviesDao.upsertMovie(m.toCompanion());
      }
      return _attachLocalData(movies, activeUserId);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        return _cachedMovies(activeUserId);
      }
      rethrow;
    }
  }

  // ── Fetch movie detail ─────────────────────────────────────────
  Future<MovieModel> fetchMovieDetail({
    required int movieId,
    required int activeUserId,
  }) async {
    try {
      final res   = await _tmdbDio.get('/movie/$movieId');
      final movie = MovieModel.fromJson(res.data);
      await _moviesDao.upsertMovie(movie.toCompanion());

      final count      = await _moviesDao.watchSaveCount(movieId).first;
      final isSaved    = await _moviesDao.isMovieSaved(activeUserId, movieId);
      final savedUsers = await _getSavedByUsers(movieId);

      return movie.copyWith(
        saveCount: count,
        isSavedByActiveUser: isSaved,
        savedByUsers: savedUsers,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final cached = await _moviesDao.watchSavedMoviesForUser(activeUserId).first;
        final match  = cached.where((m) => m.tmdbId == movieId).firstOrNull;
        if (match != null) return MovieModel.fromDb(match);
        rethrow;
      }
      rethrow;
    }
  }

  // ── Toggle save / unsave ───────────────────────────────────────
  Future<void> toggleSave({required int userId, required int movieId}) async {
    final isSaved = await _moviesDao.isMovieSaved(userId, movieId);
    if (isSaved) {
      await _moviesDao.unsaveMovie(userId, movieId);
    } else {
      await _moviesDao.saveMovie(userId, movieId);
    }
  }

  // ── Stream: saved movies for a user (offline-first) ──────────
  Stream<List<MovieModel>> watchSavedMovies(int userId) {
    return _moviesDao.watchSavedMoviesForUser(userId).asyncMap((dbList) async {
      final result = <MovieModel>[];
      for (final db in dbList) {
        final count   = await _moviesDao.watchSaveCount(db.tmdbId).first;
        final isSaved = await _moviesDao.isMovieSaved(userId, db.tmdbId);
        result.add(MovieModel.fromDb(db).copyWith(
          saveCount: count,
          isSavedByActiveUser: isSaved,
        ));
      }
      return result;
    });
  }

  // ── Stream: matches ────────────────────────────────────────────
  Stream<List<MovieMatchResult>> watchMatches() =>
      _moviesDao.watchMatches();

  // ── Stream: live badge count ───────────────────────────────────
  Stream<int> watchSaveCount(int movieId) =>
      _moviesDao.watchSaveCount(movieId);

  // ── Helpers ───────────────────────────────────────────────────
  Future<List<MovieModel>> _attachLocalData(
      List<MovieModel> movies,
      int activeUserId,
      ) async {
    final result = <MovieModel>[];
    for (final m in movies) {
      final count   = await _moviesDao.watchSaveCount(m.id).first;
      final isSaved = await _moviesDao.isMovieSaved(activeUserId, m.id);
      result.add(m.copyWith(saveCount: count, isSavedByActiveUser: isSaved));
    }
    return result;
  }

  Future<List<MovieModel>> _cachedMovies(int activeUserId) async {
    final dbList = await _moviesDao.watchSavedMoviesForUser(activeUserId).first;
    final result = <MovieModel>[];
    for (final db in dbList) {
      final count   = await _moviesDao.watchSaveCount(db.tmdbId).first;
      final isSaved = await _moviesDao.isMovieSaved(activeUserId, db.tmdbId);
      result.add(MovieModel.fromDb(db).copyWith(
        saveCount: count, isSavedByActiveUser: isSaved,
      ));
    }
    return result;
  }

  Future<List<UserModel>> _getSavedByUsers(int movieId) async {
    final matches = await _moviesDao.watchMatches().first;
    final match   = matches.where((m) => m.movie.tmdbId == movieId).firstOrNull;
    if (match == null) return [];
    return match.users.map((db) => UserModel.fromDb(db)).toList();
  }
}