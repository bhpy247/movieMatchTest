import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/movie_model.dart';
import '../repositories/movie_repository.dart';

// ── State ─────────────────────────────────────────────────────
abstract class SavedState extends Equatable {
  const SavedState();
  @override List<Object?> get props => [];
}

class SavedInitial extends SavedState {}
class SavedLoading extends SavedState {}
class SavedLoaded  extends SavedState {
  final List<MovieModel> movies;
  const SavedLoaded(this.movies);
  @override List<Object?> get props => [movies];
}
class SavedEmpty extends SavedState {}  // show empty state UI
class SavedError  extends SavedState {
  final String message;
  const SavedError(this.message);
  @override List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────
class SavedMoviesCubit extends Cubit<SavedState> {
  final MovieRepository _repo;
  final int userId;

  StreamSubscription<List<MovieModel>>? _sub;

  SavedMoviesCubit(this._repo, {required this.userId}) : super(SavedInitial());

  // Subscribe to DB stream — auto-updates when save/unsave happens
  void watchSavedMovies() {
    emit(SavedLoading());
    _sub = _repo.watchSavedMovies(userId).listen(
          (movies) {
            print("Movies : ${movies.length}");
        if (movies.isEmpty) {
          emit(SavedEmpty());
        } else {
          emit(SavedLoaded(movies));
        }
      },
      onError: (e) => emit(SavedError(e.toString())),
    );
  }

  Future<void> toggleSave(int movieId) async {
    await _repo.toggleSave(userId: userId, movieId: movieId);
    // Stream auto-updates — no manual emit needed
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}