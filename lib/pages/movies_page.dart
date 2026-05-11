import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/movies_cubit.dart';
import '../models/user_model.dart';
import '../repositories/movie_repository.dart';
import '../widgets/movie_card.dart';
import '../widgets/shimmer_loader.dart';

class MoviesPage extends StatelessWidget {
  final UserModel activeUser;
  const MoviesPage({super.key, required this.activeUser});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MoviesCubit(
        MovieRepository(),
        activeUserId: activeUser.localId,
      )..fetchMovies(),
      child: _MoviesView(activeUser: activeUser),
    );
  }
}

class _MoviesView extends StatefulWidget {
  final UserModel activeUser;
  const _MoviesView({required this.activeUser});
  @override
  State<_MoviesView> createState() => _MoviesViewState();
}

class _MoviesViewState extends State<_MoviesView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<MoviesCubit>().fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("active user: ${widget.activeUser.id}");

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activeUser.firstName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            tooltip: 'Saved Movies',
            onPressed: () => context.push(
              '/users/${widget.activeUser.localId}/saved',
              extra: widget.activeUser,
            ),
          ),
        ],
      ),
      body: BlocConsumer<MoviesCubit, MoviesState>(
        listener: (context, state) {
          if (state is MoviesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is MoviesLoading) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: 6,
              itemBuilder: (_, __) => const ShimmerMovieCard(),
            );
          }

          if (state is MoviesError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load movies'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<MoviesCubit>().fetchMovies(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final movies = switch (state) {
            MoviesLoaded s => s.movies,
            MoviesLoadingMore s => s.currentMovies,
            _ => [],
          };
          final isOffline = state is MoviesLoaded && state.isOffline;
          final isLoadingMore = state is MoviesLoadingMore;

          return Column(
            children: [
              if (isOffline)
                MaterialBanner(
                  content: const Text('Showing cached movies — you are offline'),
                  leading: const Icon(Icons.wifi_off_rounded),
                  actions: [
                    TextButton(
                      onPressed: () => context.read<MoviesCubit>().fetchMovies(),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: movies.length + (isLoadingMore ? 3 : 0),
                  itemBuilder: (context, i) {
                    if (i >= movies.length) return const ShimmerMovieCard();
                    final movie = movies[i];
                    return MovieCard(
                      movie: movie,
                      // Fade in each card as it appears
                      index: i,
                      onTap: () => context.push(
                        '/users/${widget.activeUser.id}/movies/${movie.id}',
                        extra: {
                          'user': widget.activeUser,
                          'movie': movie,
                          'cubit': context.read<MoviesCubit>(),
                        },
                      ),
                      onSave: () => context.read<MoviesCubit>().toggleSave(movie),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
