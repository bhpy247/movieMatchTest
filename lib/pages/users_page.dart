import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/users_cubit.dart';
import '../models/user_model.dart';
import 'package:movie_match/repositories/user_repository.dart' show UserRepository;
import '../widgets/shimmer_loader.dart';
import '../widgets/user_tile.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit(UserRepository())..fetchUsers(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();
  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<UsersCubit>().fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── BlocConsumer wraps everything including Scaffold
    // so that users.length is accessible in AppBar
    return BlocConsumer<UsersCubit, UsersState>(
      listener: (context, state) {
        if (state is UsersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        // Resolve users list from any state
        final users = switch (state) {
          UsersLoaded s => s.users,
          UsersLoadingMore s => s.currentUsers,
          _ => <UserModel>[],
        };

        final isOffline = state is UsersLoaded && state.isOffline;
        final isLoadingMore = state is UsersLoadingMore;

        return Scaffold(
          appBar: AppBar(
            title: const Text('MovieMatch'),
            actions: [
              TextButton.icon(
                onPressed: () => context.push(
                  '/matches',
                  extra: users.length, // ✅ now accessible
                ),
                icon: const Icon(Icons.movie_filter_rounded),
                label: const Text('Matches'),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final cubit = context.read<UsersCubit>();
              await context.push('/users/add', extra: cubit);
            },
            child: const Icon(Icons.person_add_rounded),
          ),
          body: Column(
            children: [
              // ── Offline banner ─────────────────────────
              if (isOffline)
                MaterialBanner(
                  content: const Text('Showing cached data — you are offline'),
                  leading: const Icon(Icons.wifi_off_rounded),
                  actions: [
                    TextButton(
                      onPressed: () => context.read<UsersCubit>().fetchUsers(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),

              // ── First load shimmer ──────────────────────
              if (state is UsersLoading) const Expanded(child: ShimmerList()),

              // ── Error state ─────────────────────────────
              if (state is UsersError)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 48),
                        const SizedBox(height: 12),
                        Text(state.message),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<UsersCubit>().fetchUsers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Users list ──────────────────────────────
              if (state is! UsersLoading && state is! UsersError)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: users.length + (isLoadingMore ? 3 : 0),
                    itemBuilder: (context, i) {
                      // Shimmer tiles at bottom during pagination
                      if (i >= users.length) return const ShimmerTile();

                      final user = users[i];
                      return UserTile(
                        user: user,
                        onTap: () => context.push(
                          '/users/${user.localId}/movies',
                          extra: user,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
