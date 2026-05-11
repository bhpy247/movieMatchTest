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
    return BlocProvider(
      create: (_) => SavedMoviesCubit(
        MovieRepository(),
        userId: profileUser.localId,
      )..watchSavedMovies(),
      child: _SavedView(
        activeUser:  activeUser,
        profileUser: profileUser,
      ),
    );
  }
}

class _SavedView extends StatelessWidget {
  final UserModel activeUser;
  final UserModel profileUser;
  const _SavedView({required this.activeUser, required this.profileUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${profileUser.firstName}\'s List'),
      ),
      body: Column(
        children: [
          // ── User Profile Header ──────────────────────────
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

          // ── Saved Movies List ────────────────────────────
          Expanded(
            child: BlocBuilder<SavedMoviesCubit, SavedState>(
              builder: (context, state) {

                if (state is SavedLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SavedEmpty) {
                  return _EmptyState(
                    isOwnList: activeUser.id == profileUser.id,
                    userId: activeUser.id,
                  );
                }

                if (state is SavedError) {
                  return Center(child: Text(state.message));
                }

                final movies = (state as SavedLoaded).movies;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: movies.length,
                  itemBuilder: (context, i) {
                    final movie = movies[i];
                    return _SavedMovieTile(
                      movie:        movie,
                      activeUserId: activeUser.id,
                      onTap: () => context.push(
                        '/users/${activeUser.id}/movies/${movie.id}',
                        extra: {'user': activeUser, 'movie': movie},
                      ),
                      onSave: () =>
                          context.read<SavedMoviesCubit>().toggleSave(movie.id),
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

// ── Single saved movie tile ────────────────────────────────────
class _SavedMovieTile extends StatelessWidget {
  final MovieModel movie;
  final int        activeUserId;
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
            // Poster
            Hero(
              tag: 'poster_${movie.id}',
              child: CachedNetworkImage(
                imageUrl: movie.posterSmall,
                width: 70,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 70, height: 100,
                  color: theme.colorScheme.surfaceVariant,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 70, height: 100,
                  color: theme.colorScheme.surfaceVariant,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),

            // Info
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

            // Save/unsave button (only shown for active user)
            if (activeUserId == movie.savedByUsers.firstOrNull?.id ||
                movie.isSavedByActiveUser)
              IconButton(
                icon: Icon(
                  movie.isSavedByActiveUser
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: movie.isSavedByActiveUser
                      ? theme.colorScheme.primary
                      : null,
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

// ── Empty state ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isOwnList;
  final int  userId;
  const _EmptyState({required this.isOwnList, required this.userId});

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
              isOwnList
                  ? 'Browse movies and save the ones you want to watch'
                  : 'This user hasn\'t saved any movies yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (isOwnList) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Browse Movies'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}