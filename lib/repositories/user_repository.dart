import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../core/database/app_database.dart';
import '../core/database/daos/movies_dao.dart';
import '../core/database/daos/users_dao.dart';
import '../core/netwok/service_locator.dart';
import '../core/sync/sync_task.dart';
import '../models/user_model.dart';

class UserRepository {
  final UsersDao  _usersDao  = sl<UsersDao>();
  final MoviesDao _moviesDao = sl<MoviesDao>();
  final Dio       _dio       = sl<Dio>(instanceName: 'reqres');

  Future<List<UserModel>> fetchUsers({int page = 1}) async {
    try {
      final res      = await _dio.get('/users', queryParameters: {'page': page});
      final List data = res.data['data'] as List;

      final result = <UserModel>[];
      for (final e in data) {
        final apiUser = UserModel.fromJson(e);

        // ✅ KEY FIX: Upsert every Reqres user into local DB
        // So we always have a valid localId for movie saves
        final localId = await _usersDao.upsertReqresUser(
          serverId:  apiUser.id,
          firstName: apiUser.firstName,
          lastName:  apiUser.lastName,
          email:     apiUser.email,
          avatarUrl: apiUser.avatar,
        );

        final count = await _moviesDao.getSaveCountForUser(localId);
        result.add(UserModel(
          localId:          localId,
          id:               apiUser.id,
          email:            apiUser.email,
          firstName:        apiUser.firstName,
          lastName:         apiUser.lastName,
          avatar:           apiUser.avatar,
          movieTaste:       apiUser.movieTaste,
          savedMoviesCount: count,
        ));
      }
      return result;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (page == 1) return _localUsers();
        return [];
      }
      rethrow;
    }
  }

  Future<UserModel> addUser({
    required String name,
    required String movieTaste,
  }) async {
    final parts     = name.trim().split(' ');
    final firstName = parts.first;
    final lastName  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final isOnline  = await _isOnline();

    if (isOnline) {
      final res      = await _dio.post('/users', data: {
        'name': name.trim(), 'job': movieTaste,
      });
      final serverId = int.tryParse('${res.data['id']}') ?? 0;
      final localId  = await _usersDao.insertUser(UsersTableCompanion.insert(
        serverId:    Value(serverId),
        firstName:   firstName,
        lastName:    Value(lastName),
        movieTaste:  Value(movieTaste),
        pendingSync: const Value(false),
      ));
      final db = await _usersDao.getUserById(localId);
      return UserModel.fromDb(db!);
    } else {
      final localId = await _usersDao.insertUser(UsersTableCompanion.insert(
        firstName:   firstName,
        lastName:    Value(lastName),
        movieTaste:  Value(movieTaste),
        pendingSync: const Value(true),
      ));
      scheduleSync();
      final db = await _usersDao.getUserById(localId);
      return UserModel.fromDb(db!);
    }
  }

  Stream<List<UserModel>> watchLocalUsers() {
    return _usersDao.watchAllUsers().asyncMap((dbList) async {
      final result = <UserModel>[];
      for (final db in dbList) {
        final count = await _moviesDao.getSaveCountForUser(db.id);
        result.add(UserModel.fromDb(db, savedMoviesCount: count));
      }
      return result;
    });
  }

  Future<List<UserModel>> _localUsers() async {
    final dbList = await _usersDao.getAllUsers();
    final result = <UserModel>[];
    for (final db in dbList) {
      final count = await _moviesDao.getSaveCountForUser(db.id);
      result.add(UserModel.fromDb(db, savedMoviesCount: count));
    }
    return result;
  }

  Future<bool> _isOnline() async {
    final r = await Connectivity().checkConnectivity();
    return !r.contains(ConnectivityResult.none);
  }
}