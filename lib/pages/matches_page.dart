import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_match/core/utils/constants.dart';
import 'package:movie_match/models/movie_model.dart';

import '../core/database/app_database.dart';
import '../core/database/daos/movies_dao.dart';
import '../cubits/matches_cubit.dart';
import '../models/user_model.dart';
import '../repositories/movie_repository.dart';

class MatchesPage extends StatelessWidget {
  final int totalUsers;
  const MatchesPage({super.key, required this.totalUsers});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MatchesCubit(
        MovieRepository(),
        totalUsers: totalUsers,
      )..watchMatches(),
      child: const _MatchesView(),
    );
  }
}

class _MatchesView extends StatelessWidget {
  const _MatchesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        centerTitle: false,
      ),
      body: BlocBuilder<MatchesCubit, MatchesState>(
        builder: (context, state) {
          if (state is MatchesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MatchesEmpty) {
            return const _EmptyState();
          }

          if (state is MatchesError) {
            return Center(child: Text(state.message));
          }

          final matches = (state as MatchesLoaded).matches;
          final hasTopPick = state.hasTopPick;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final result = matches[i];
              final isTopPick = hasTopPick && i == 0;

              return _MatchTile(
                result: result,
                isTopPick: isTopPick,
                rank: i + 1,
                onTap: () => context.push(
                  '/users/0/movies/${result.movie.id}',
                  extra: {
                    'user': const UserModel(
                      id: 0,
                      email: '',
                      firstName: 'You',
                      lastName: '',
                      avatar: '',
                      localId: 0,
                    ),
                    'movie': MovieModel(
                      title: result.movie.title,
                      id: result.movie.id,
                      overview: result.movie.overview,
                      posterPath: result.movie.posterPath,
                      releaseDate: result.movie.releaseDate,
                      voteAverage: result.movie.voteAverage,
                    )
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Single match tile ──────────────────────────────────────────
class _MatchTile extends StatelessWidget {
  final MovieMatchResult result;
  final bool isTopPick;
  final int rank;
  final VoidCallback onTap;

  const _MatchTile({
    required this.result,
    required this.isTopPick,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movie = result.movie;
    final users = result.users;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      // Top pick gets golden border
      shape: isTopPick
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.amber[600]!, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Top pick banner
            if (isTopPick)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.amber[600],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Everyone\'s Top Pick!',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                // Poster
                CachedNetworkImage(
                  imageUrl: AppConstants.posterSmall(movie.posterPath),
                  width: 80,
                  // height: 115,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 80,
                    height: 115,
                    color: theme.colorScheme.surfaceVariant,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 115,
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rank + title
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$rank',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                movie.title,
                                style: theme.textTheme.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          movie.releaseDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Save count chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_rounded,
                                  size: 13, color: theme.colorScheme.secondary),
                              const SizedBox(width: 4),
                              Text(
                                '${result.saveCount} want to watch',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Stacked user avatars
                        _StackedAvatars(users: users),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stacked avatars row ────────────────────────────────────────
class _StackedAvatars extends StatelessWidget {
  final List<UsersTableData> users;
  const _StackedAvatars({required this.users});

  @override
  Widget build(BuildContext context) {
    final show = users.take(5).toList();
    return SizedBox(
      height: 28,
      width: (show.length * 20 + 8).toDouble(),
      child: Stack(
        children: show.asMap().entries.map((e) {
          return Positioned(
            left: e.key * 20.0,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: CircleAvatar(
                radius: 12,
                backgroundImage: e.value.avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(e.value.avatarUrl)
                    : null,
                child: e.value.avatarUrl.isEmpty
                    ? Text(
                        e.value.firstName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 10),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'When 2 or more users save the same movie, it appears here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
