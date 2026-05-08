import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../database/daos/movies_dao.dart';
import '../database/daos/users_dao.dart';
import 'dio_client.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  final db = AppDatabase();
  sl.registerSingleton<AppDatabase>(db);
  sl.registerSingleton<UsersDao>(db.usersDao);
  sl.registerSingleton<MoviesDao>(db.moviesDao);

  sl.registerSingleton<Dio>(DioClient.tmdb, instanceName: 'tmdb');
  sl.registerSingleton<Dio>(DioClient.reqres, instanceName: 'reqres');
}
