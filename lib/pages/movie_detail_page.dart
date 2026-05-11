import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/movies_cubit.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';
import '../repositories/movie_repository.dart';
import '../widgets/save_badge.dart';

class MovieDetailPage extends StatelessWidget {
  final UserModel activeUser;
  final MovieModel movie;      // passed for hero tag + instant render
  final MoviesCubit? listCubit; // to sync save state back to list

  const MovieDetailPage({
    super.key,
    required this.activeUser,
    required this.movie,
    this.listCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MoviesCubit(
        MovieRepository(),
        activeUserId: activeUser.id,
      )..fetchDetail(movie.id),
      child: _DetailView(
        activeUser: activeUser,
        initialMovie: movie,
        listCubit: listCubit,
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final UserModel  activeUser;
  final MovieModel initialMovie;
  final MoviesCubit? listCubit;

  const _DetailView({
    required this.activeUser,
    required this.initialMovie,
    this.listCubit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<MoviesCubit, MoviesState>(
        builder: (context, state) {
          final movie = state is MovieDetailLoaded ? state.movie : initialMovie;
          final isLoading = state is MovieDetailLoading;

          return CustomScrollView(
            slivers: [
              // ── Hero Poster AppBar ─────────────────────────
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'poster_${movie.id}',
                    child: CachedNetworkImage(
                      imageUrl: movie.posterLarge,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: theme.colorScheme.surfaceVariant,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.broken_image_rounded, size: 48),
                      ),
                    ),
                  ),
                ),
                // Save button in AppBar
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SaveButton(
                      movie: movie,
                      onSave: () async {
                        await context.read<MoviesCubit>().toggleSave(movie.id);
                        listCubit?.toggleSave(movie.id); // sync back to list
                      },
                    ),
                  ),
                ],
              ),

              // ── Movie Info ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        movie.title,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),

                      // Year + rating row
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            movie.releaseYear,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber[600]),
                          const SizedBox(width: 4),
                          Text(
                            movie.voteAverage.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save count + avatars
                      isLoading
                          ? const _SavedByShimmer()
                          : _SavedByRow(movie: movie),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Overview
                      Text('Overview', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview.isNotEmpty
                            ? movie.overview
                            : 'No description available.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Save button in AppBar ──────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onSave;
  const _SaveButton({required this.movie, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onSave,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          movie.isSavedByActiveUser
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          key: ValueKey(movie.isSavedByActiveUser),
        ),
      ),
    );
  }
}

// ── "X users want to watch this" row ──────────────────────────
class _SavedByRow extends StatelessWidget {
  final MovieModel movie;
  const _SavedByRow({required this.movie});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = movie.savedByUsers;

    if (users.isEmpty) {
      return Row(
        children: [
          Icon(Icons.bookmark_border_rounded,
              size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 6),
          Text(
            'Be the first to save this',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Stacked avatars
        SizedBox(
          height: 32,
          width: (users.length * 22 + 10).toDouble().clamp(0, 100),
          child: Stack(
            children: users.take(4).toList().asMap().entries.map((e) {
              return Positioned(
                left: e.key * 22.0,
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: e.value.avatar.isNotEmpty
                      ? CachedNetworkImageProvider(e.value.avatar)
                      : null,
                  child: e.value.avatar.isEmpty
                      ? Text(e.value.firstName[0])
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${movie.saveCount} ${movie.saveCount == 1 ? 'user wants' : 'users want'} to watch this',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _SavedByShimmer extends StatelessWidget {
  const _SavedByShimmer();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 32, height: 32,
            decoration: const BoxDecoration(
                color: Colors.grey, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Container(width: 160, height: 12,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4))),
      ],
    );
  }
}