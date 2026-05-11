import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/saved_movies_cubit.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';
import '../repositories/movie_repository.dart';

class SavedMoviesPage extends StatelessWidget {
  final UserModel activeUser;
  final UserModel profileUser;

  const SavedMoviesPage({
    super.key,
    required this.activeUser,
    required this.profileUser,
  });

  @override
  Widget build(BuildContext context) {
    print("========== SAVED MOVIES PAGE ==========");
    print("Active User Local ID: ${activeUser.localId}");
    print("Active User API ID: ${activeUser.id}");

    print("Profile User Local ID: ${profileUser.localId}");
    print("Profile User API ID: ${profileUser.id}");

    return BlocProvider(
      create: (_) => SavedMoviesCubit(
        MovieRepository(),

        /// IMPORTANT:
        /// Use LOCAL SQLITE USER ID
        userId: profileUser.localId,
      )..watchSavedMovies(),
      child: _SavedView(
        activeUser: activeUser,
        profileUser: profileUser,
      ),
    );
  }
}

class _SavedView extends StatelessWidget {
  final UserModel activeUser;
  final UserModel profileUser;

  const _SavedView({
    required this.activeUser,
    required this.profileUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${profileUser.firstName}\'s List'),
      ),
      body: Column(
        children: [
          // ───────────────── PROFILE HEADER ─────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: profileUser.avatar.isNotEmpty
                      ? CachedNetworkImageProvider(profileUser.avatar)
                      : null,
                  child: profileUser.avatar.isEmpty
                      ? Text(
                          profileUser.firstName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 22),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileUser.fullName,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (profileUser.movieTaste.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          profileUser.movieTaste,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ───────────────── SAVED MOVIES ─────────────────
          Expanded(
            child: BlocBuilder<SavedMoviesCubit, SavedState>(
              builder: (context, state) {
                print("========== SAVED MOVIES STATE ==========");
                print("STATE => $state");

                if (state is SavedLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is SavedEmpty) {
                  print("NO SAVED MOVIES FOUND");

                  return _EmptyState(
                    isOwnList: activeUser.localId == profileUser.localId,
                    userId: activeUser.localId,
                  );
                }

                if (state is SavedError) {
                  print("SAVED MOVIES ERROR => ${state.message}");

                  return Center(
                    child: Text(state.message),
                  );
                }

                final movies = (state as SavedLoaded).movies;

                print("TOTAL SAVED MOVIES => ${movies.length}");

                for (final movie in movies) {
                  print(
                    "Movie => ${movie.title} "
                    "TMDB => ${movie.id}",
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    80,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, i) {
                    final movie = movies[i];

                    return _SavedMovieTile(
                      movie: movie,

                      /// IMPORTANT:
                      /// use LOCAL USER ID
                      activeUserId: activeUser.localId,

                      onTap: () {
                        print(
                          "OPEN MOVIE => "
                          "${movie.title} "
                          "TMDB => ${movie.id}",
                        );

                        context.push(
                          '/users/${activeUser.localId}/movies/${movie.id}',
                          extra: {
                            'user': activeUser,
                            'movie': movie,
                          },
                        );
                      },

                      onSave: () {
                        print(
                          "TOGGLE SAVE => "
                          "${movie.title} "
                          "TMDB => ${movie.id}",
                        );

                        /// IMPORTANT:
                        /// USE TMDB ID
                        context.read<SavedMoviesCubit>().toggleSave(movie);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── MOVIE TILE ─────────────────
class _SavedMovieTile extends StatelessWidget {
  final MovieModel movie;
  final int activeUserId;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _SavedMovieTile({
    required this.movie,
    required this.activeUserId,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // ───────────── POSTER ─────────────
            Hero(
              tag: 'poster_${movie.id}',
              child: CachedNetworkImage(
                imageUrl: movie.posterSmall,
                width: 70,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 70,
                  height: 100,
                  color: theme.colorScheme.surfaceVariant,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 70,
                  height: 100,
                  color: theme.colorScheme.surfaceVariant,
                  child: const Icon(
                    Icons.broken_image_rounded,
                  ),
                ),
              ),
            ),

            // ───────────── INFO ─────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.releaseYear,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ───────────── SAVE BUTTON ─────────────
            IconButton(
              icon: Icon(
                movie.isSavedByActiveUser ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: movie.isSavedByActiveUser ? theme.colorScheme.primary : null,
              ),
              onPressed: onSave,
            ),

            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ───────────────── EMPTY STATE ─────────────────
class _EmptyState extends StatelessWidget {
  final bool isOwnList;
  final int userId;

  const _EmptyState({
    required this.isOwnList,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isOwnList ? 'No saved movies yet' : 'Nothing saved yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isOwnList ? 'Browse movies and save movies' : 'This user has not saved movies yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            if (isOwnList) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.explore_rounded,
                ),
                label: const Text(
                  'Browse Movies',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
