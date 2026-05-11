class AppConstants {
  AppConstants._();

  // ⚠️ Replace with your actual keys
  static const String tmdbApiKey = '695f2e1a4b51253ae3201df0efd927d7';
  static const String reqresApiKey = 'free_user_33NJkDE48XReYwjP0s7E5q9Bkju';

  // TMDB image helpers
  static const String _imgSmall = 'https://image.tmdb.org/t/p/w185';
  static const String _imgLarge = 'https://image.tmdb.org/t/p/w500';

  static String posterSmall(String path) => '$_imgSmall$path';
  static String posterLarge(String path) => '$_imgLarge$path';
}
