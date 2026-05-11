import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/movie_model.dart';
import '../repositories/movie_repository.dart';

// ── State ─────────────────────────────────────────────────────
abstract class MoviesState extends Equatable {
  const MoviesState();
  @override List<Object?> get props => [];
}

class MoviesInitial    extends MoviesState {}
class MoviesLoading    extends MoviesState {}
class MoviesLoadingMore extends MoviesState {
  final List<MovieModel> currentMovies;
  const MoviesLoadingMore(this.currentMovies);
  @override List<Object?> get props => [currentMovies];
}
class MoviesLoaded extends MoviesState {
  final List<MovieModel> movies;
  final bool hasMore;
  final bool isOffline;
  const MoviesLoaded({
    required this.movies,
    this.hasMore = true,
    this.isOffline = false,
  });
  @override List<Object?> get props => [movies, hasMore, isOffline];
}
class MoviesError extends MoviesState {
  final String message;
  const MoviesError(this.message);
  @override List<Object?> get props => [message];
}

// Detail states
class MovieDetailLoading extends MoviesState {}
class MovieDetailLoaded extends MoviesState {
  final MovieModel movie;
  const MovieDetailLoaded(this.movie);
  @override List<Object?> get props => [movie];
}

// ── Cubit ─────────────────────────────────────────────────────
class MoviesCubit extends Cubit<MoviesState> {
  final MovieRepository _repo;
  final int activeUserId;

  MoviesCubit(this._repo, {required this.activeUserId}) : super(MoviesInitial());

  int _page = 1;
  final List<MovieModel> _movies = [];

  Future<void> fetchMovies() async {
    _page = 1;
    _movies.clear();
    emit(MoviesLoading());
    await _loadPage();
  }

  Future<void> fetchMore() async {
    if (state is MoviesLoadingMore) return;
    final current = state;
    if (current is MoviesLoaded && !current.hasMore) return;

    emit(MoviesLoadingMore(_movies));
    _page++;
    await _loadPage();
  }

  Future<void> fetchDetail(int movieId) async {
    emit(MovieDetailLoading());
    try {
      final movie = await _repo.fetchMovieDetail(
        movieId: movieId,
        activeUserId: activeUserId,
      );
      emit(MovieDetailLoaded(movie));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  // Toggle save and update the list in place
  Future<void> toggleSave(int movieId) async {
    await _repo.toggleSave(userId: activeUserId, movieId: movieId);

    // Update the movie in our local list
    final idx = _movies.indexWhere((m) => m.id == movieId);
    if (idx == -1) return;

    final m       = _movies[idx];
    final isSaved = !m.isSavedByActiveUser;
    _movies[idx]  = m.copyWith(
      isSavedByActiveUser: isSaved,
      saveCount: isSaved ? m.saveCount + 1 : m.saveCount - 1,
    );
    emit(MoviesLoaded(movies: List.from(_movies)));
  }

  Future<void> _loadPage() async {
    try {
      final fetched = await _repo.fetchTrending(
        page: _page,
        activeUserId: activeUserId,
      );
      _movies.addAll(fetched);
      emit(MoviesLoaded(
        movies: List.from(_movies),
        hasMore: fetched.isNotEmpty,
        isOffline: fetched.isEmpty && _page == 1,
      ));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }
}