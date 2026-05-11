import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

// ── State ─────────────────────────────────────────────────────
abstract class UsersState extends Equatable {
  const UsersState();
  @override List<Object?> get props => [];
}

class UsersInitial  extends UsersState {}
class UsersLoading  extends UsersState {}  // first load - show shimmer
class UsersLoadingMore extends UsersState { // pagination - keep list visible
  final List<UserModel> currentUsers;
  const UsersLoadingMore(this.currentUsers);
  @override List<Object?> get props => [currentUsers];
}
class UsersLoaded extends UsersState {
  final List<UserModel> users;
  final bool hasMore;        // false = no more pages
  final bool isOffline;      // true = show offline banner
  const UsersLoaded({
    required this.users,
    this.hasMore = true,
    this.isOffline = false,
  });
  @override List<Object?> get props => [users, hasMore, isOffline];
}
class UsersError extends UsersState {
  final String message;
  const UsersError(this.message);
  @override List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────
class UsersCubit extends Cubit<UsersState> {
  final UserRepository _repo;
  UsersCubit(this._repo) : super(UsersInitial());

  int _page = 1;
  final List<UserModel> _users = [];

  // Initial load
  Future<void> fetchUsers() async {
    _page = 1;
    _users.clear();
    emit(UsersLoading());
    await _loadPage();
  }

  // Called when user scrolls to bottom
  Future<void> fetchMore() async {
    if (state is UsersLoadingMore) return; // prevent double call
    final current = state;
    if (current is UsersLoaded && !current.hasMore) return;

    emit(UsersLoadingMore(_users));
    _page++;
    await _loadPage();
  }

  // Add user and instantly show in list (offline or online)
  Future<void> addUser({
    required String name,
    required String movieTaste,
  }) async {
    try {
      final newUser = await _repo.addUser(
        name: name,
        movieTaste: movieTaste,
      );
      _users.insert(0, newUser); // show at top immediately
      emit(UsersLoaded(users: List.from(_users)));
    } catch (e) {
      emit(UsersError('Failed to add user: $e'));
    }
  }

  Future<void> _loadPage() async {
    try {
      final fetched = await _repo.fetchUsers(page: _page);
      _users.addAll(fetched);
      emit(UsersLoaded(
        users: List.from(_users),
        hasMore: fetched.isNotEmpty,
        isOffline: fetched.isEmpty && _page == 1,
      ));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}