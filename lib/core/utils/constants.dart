class AppConstants {
  AppConstants._();

  // ⚠️ Replace with your actual keys
  static const String tmdbApiKey = 'YOUR_TMDB_KEY';
  static const String reqresApiKey = 'YOUR_REQRES_KEY';

  // TMDB image helpers
  static const String _imgSmall = 'https://image.tmdb.org/t/p/w185';
  static const String _imgLarge = 'https://image.tmdb.org/t/p/w500';

  static String posterSmall(String path) => '$_imgSmall$path';
  static String posterLarge(String path) => '$_imgLarge$path';
}
