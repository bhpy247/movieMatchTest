import '../core/utils/constants.dart';

// TMDB Trending API response (one item):
// {
//   "id": 1022789,
//   "title": "Inside Out 2",
//   "overview": "...",
//   "poster_path": "/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg",
//   "release_date": "2024-06-11",
//   "vote_average": 7.6
// }

class MovieModel {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String releaseDate;
  final double voteAverage;

  // Computed locally from saved_movies table
  final int saveCount;
  final bool isSavedByActiveUser;

  // Users who saved this movie (used on Detail + Matches page)
  final List<UserModel> savedByUsers;

  const MovieModel({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
    this.saveCount = 0,
    this.isSavedByActiveUser = false,
    this.savedByUsers = const [],
  });

  // Poster URL helpers
  String get posterSmall => AppConstants.posterSmall(posterPath);

  String get posterLarge => AppConstants.posterLarge(posterPath);

  // Release year only (e.g. "2024-06-11" → "2024")
  String get releaseYear => releaseDate.isNotEmpty ? releaseDate.substring(0, 4) : '—';

  // From TMDB API JSON
  factory MovieModel.fromJson(Map<String, dynamic> json) => MovieModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        overview: json['overview'] as String? ?? '',
        posterPath: json['poster_path'] as String? ?? '',
        releaseDate: json['release_date'] as String? ?? '',
        voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      );

  // From local Drift DB row (MovieData)
  factory MovieModel.fromDb(MovieData db) => MovieModel(
        id: db.tmdbId,
        title: db.title,
        overview: db.overview,
        posterPath: db.posterPath,
        releaseDate: db.releaseDate,
        voteAverage: db.voteAverage,
      );

  // Convert to Drift companion for upsert
  // MoviesTableCompanion toCompanion() => MoviesTableCompanion.insert(
  //       tmdbId: id,
  //       title: title,
  //       overview: Value(overview),
  //       posterPath: Value(posterPath),
  //       releaseDate: Value(releaseDate),
  //       voteAverage: Value(voteAverage),
  //     );

  MovieModel copyWith({
    int? saveCount,
    bool? isSavedByActiveUser,
    List<UserModel>? savedByUsers,
  }) =>
      MovieModel(
        id: id,
        title: title,
        overview: overview,
        posterPath: posterPath,
        releaseDate: releaseDate,
        voteAverage: voteAverage,
        saveCount: saveCount ?? this.saveCount,
        isSavedByActiveUser: isSavedByActiveUser ?? this.isSavedByActiveUser,
        savedByUsers: savedByUsers ?? this.savedByUsers,
      );
}

// Remove after build_runner runs (just for IDE to not complain)
typedef MovieData = dynamic;
typedef MoviesTableCompanion = dynamic;
typedef UserModel = dynamic;

class Value<T> {
  const Value(T v);
}
