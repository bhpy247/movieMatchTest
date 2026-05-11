// import 'dart:async';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:equatable/equatable.dart';
// import '../models/movie_model.dart';
// import '../repositories/movie_repository.dart';
//
// // ── State ─────────────────────────────────────────────────────
// abstract class SavedState extends Equatable {
//   const SavedState();
//   @override
//   List<Object?> get props => [];
// }
//
// class SavedInitial extends SavedState {}
//
// class SavedLoading extends SavedState {}
//
// class SavedLoaded extends SavedState {
//   final List<MovieModel> movies;
//   const SavedLoaded(this.movies);
//   @override
//   List<Object?> get props => [movies];
// }
//
// class SavedEmpty extends SavedState {} // show empty state UI
//
// class SavedError extends SavedState {
//   final String message;
//   const SavedError(this.message);
//   @override
//   List<Object?> get props => [message];
// }
//
// // ── Cubit ─────────────────────────────────────────────────────
// class SavedMoviesCubit extends Cubit<SavedState> {
//   final MovieRepository _repo;
//   final int userId;
//
//   StreamSubscription<List<MovieModel>>? _sub;
//
//   SavedMoviesCubit(this._repo, {required this.userId}) : super(SavedInitial());
//
//   // Subscribe to DB stream — auto-updates when save/unsave happens
//   void watchSavedMovies() {
//     emit(SavedLoading());
//     _sub = _repo.watchSavedMovies(userId).listen(
//       (movies) {
//         print("Movies : ${movies.length}");
//         if (movies.isEmpty) {
//           emit(SavedEmpty());
//         } else {
//           emit(SavedLoaded(movies));
//         }
//       },
//       onError: (e) => emit(SavedError(e.toString())),
//     );
//   }
//
//   Future<void> toggleSave(int movieId) async {
//     await _repo.toggleSave(userId: userId, movieId: movieId, movie: null);
//     // Stream auto-updates — no manual emit needed
//   }
//
//   @override
//   Future<void> close() {
//     _sub?.cancel();
//     return super.close();
//   }
// }

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/movie_model.dart';
import '../repositories/movie_repository.dart';

// ───────────────── STATE ─────────────────
abstract class SavedState extends Equatable {
  const SavedState();

  @override
  List<Object?> get props => [];
}

class SavedInitial extends SavedState {}

class SavedLoading extends SavedState {}

class SavedLoaded extends SavedState {
  final List<MovieModel> movies;

  const SavedLoaded(this.movies);

  @override
  List<Object?> get props => [movies];
}

class SavedEmpty extends SavedState {}

class SavedError extends SavedState {
  final String message;

  const SavedError(this.message);

  @override
  List<Object?> get props => [message];
}

// ───────────────── CUBIT ─────────────────
class SavedMoviesCubit extends Cubit<SavedState> {
  final MovieRepository _repo;

  final int userId;

  StreamSubscription<List<MovieModel>>? _sub;

  SavedMoviesCubit(
    this._repo, {
    required this.userId,
  }) : super(SavedInitial());

  // ───────────────── WATCH SAVED MOVIES ─────────────────
  void watchSavedMovies() {
    print("========== WATCH SAVED MOVIES ==========");
    print("User ID: $userId");

    emit(SavedLoading());

    _sub?.cancel();

    _sub = _repo.watchSavedMovies(userId).listen(
      (movies) {
        print(
          "Saved Movies Count => "
          "${movies.length}",
        );

        for (final movie in movies) {
          print(
            "Movie => "
            "${movie.title} "
            "TMDB => ${movie.id}",
          );
        }

        if (movies.isEmpty) {
          emit(SavedEmpty());
        } else {
          emit(SavedLoaded(movies));
        }

        print("========================================");
      },
      onError: (e) {
        print("Saved Movies Stream Error: $e");

        emit(
          SavedError(e.toString()),
        );
      },
    );
  }

  // ───────────────── TOGGLE SAVE ─────────────────
  Future<void> toggleSave(
    MovieModel movie,
  ) async {
    try {
      print("========== SAVED CUBIT TOGGLE ==========");
      print("Movie: ${movie.title}");
      print("Movie ID: ${movie.id}");

      await _repo.toggleSave(
        userId: userId,
        movie: movie,
      );

      print("Toggle Save Success");

      // NO MANUAL EMIT
      // STREAM AUTO UPDATES

      print("========================================");
    } catch (e) {
      print("Saved Cubit Toggle Error: $e");

      emit(
        SavedError(e.toString()),
      );
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();

    return super.close();
  }
}
