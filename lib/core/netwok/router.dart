import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Swap _Todo with real pages as you build them:
import '../../cubits/movies_cubit.dart';
import '../../cubits/users_cubit.dart';
import '../../models/movie_model.dart';
import '../../models/user_model.dart';
import '../../pages/users_page.dart';
import '../../pages/add_user_page.dart';
import '../../pages/movies_page.dart';
import '../../pages/movie_detail_page.dart';
import '../../pages/saved_movies_page.dart';
import '../../pages/matches_page.dart';

final appRouter = GoRouter(
  initialLocation: '/users',
  routes: [
    GoRoute(
      path: '/users',
      name: 'users',
      builder: (_, __) => const UsersPage(),
      routes: [
        GoRoute(
          path: 'add',
          name: 'add-user',
          builder: (_, state) => AddUserPage(cubit: state.extra as UsersCubit),
        ),
        GoRoute(
          path: ':userId/movies',
          name: 'movies',
          builder: (_, state) => MoviesPage(
            activeUser: state.extra as UserModel,
          ),
          routes: [
            GoRoute(
              path: ':movieId',
              name: 'movie-detail',
              builder: (_, state) {
                final extra = state.extra as Map;
                return MovieDetailPage(
                  activeUser: extra['user'] as UserModel,
                  movie:      extra['movie'] as MovieModel,
                  listCubit:  extra['cubit'] as MoviesCubit?,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: ':userId/saved',
          name: 'saved-movies',
          builder: (_, state) {
            print("state: ${state.name}");
            final extra = state.extra as UserModel;
            print("extra: ${extra.firstName}");

            return SavedMoviesPage(
              // activeUser: UserModel.fromJson( extra?['activeUser']) ,
              // profileUser: extra['profileUser'],
              activeUser: extra,
              profileUser: extra,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/matches',
      name: 'matches',
      builder: (_, state) => MatchesPage(
        totalUsers: state.extra as int,
      ),
    ),
  ],
);

