import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Swap _Todo with real pages as you build them:
// import '../../pages/users_page.dart';
// import '../../pages/add_user_page.dart';
// import '../../pages/movies_page.dart';
// import '../../pages/movie_detail_page.dart';
// import '../../pages/saved_movies_page.dart';
// import '../../pages/matches_page.dart';

final appRouter = GoRouter(
  initialLocation: '/users',
  routes: [
    GoRoute(
      path: '/users',
      name: 'users',
      builder: (_, __) => const _Todo('Users Page'),
      routes: [
        GoRoute(
          path: 'add',
          name: 'add-user',
          builder: (_, __) => const _Todo('Add User'),
        ),
        GoRoute(
          path: ':userId/movies',
          name: 'movies',
          builder: (_, state) {
            final userId = int.parse(state.pathParameters['userId']!);
            return _Todo('Movies — user $userId');
          },
          routes: [
            GoRoute(
              path: ':movieId',
              name: 'movie-detail',
              builder: (_, state) {
                final movieId = int.parse(state.pathParameters['movieId']!);
                return _Todo('Detail — movie $movieId');
              },
            ),
          ],
        ),
        GoRoute(
          path: ':userId/saved',
          name: 'saved-movies',
          builder: (_, state) {
            final userId = int.parse(state.pathParameters['userId']!);
            return _Todo('Saved — user $userId');
          },
        ),
      ],
    ),
    GoRoute(
      path: '/matches',
      name: 'matches',
      builder: (_, __) => const _Todo('Matches'),
    ),
  ],
);

// Temporary placeholder page — replace each with real widget
class _Todo extends StatelessWidget {
  final String label;
  const _Todo(this.label);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(label)),
        body: Center(child: Text(label, style: Theme.of(context).textTheme.titleLarge)),
      );
}
