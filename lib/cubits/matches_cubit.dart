import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../core/database/daos/movies_dao.dart';
import '../repositories/movie_repository.dart';

// ── State ─────────────────────────────────────────────────────
abstract class MatchesState extends Equatable {
  const MatchesState();
  @override
  List<Object?> get props => [];
}

class MatchesInitial extends MatchesState {}

class MatchesLoading extends MatchesState {}

class MatchesLoaded extends MatchesState {
  final List<MovieMatchResult> matches;

  // True if all users saved the top movie (highlight it)
  final bool hasTopPick;

  const MatchesLoaded({required this.matches, this.hasTopPick = false});
  @override
  List<Object?> get props => [matches, hasTopPick];
}

class MatchesEmpty extends MatchesState {} // no matches yet

class MatchesError extends MatchesState {
  final String message;
  const MatchesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────
class MatchesCubit extends Cubit<MatchesState> {
  final MovieRepository _repo;
  final int totalUsers; // to detect "everyone saved this"

  StreamSubscription<List<MovieMatchResult>>? _sub;

  MatchesCubit(this._repo, {required this.totalUsers}) : super(MatchesInitial());

  // Subscribe to DB stream — live updates, no API call needed
  void watchMatches() {
    emit(MatchesLoading());

    print("WantchMatched");
    _sub = _repo.watchMatches().listen(
      (matches) {
        if (matches.isEmpty) {
          emit(MatchesEmpty());
          return;
        }
        // Top pick = first movie saved by ALL users
        final hasTopPick = matches.first.saveCount >= totalUsers;
        emit(MatchesLoaded(matches: matches, hasTopPick: hasTopPick));
      },
      onError: (e) => emit(MatchesError(e.toString())),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
