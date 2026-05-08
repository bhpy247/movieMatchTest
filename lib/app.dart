// ── lib/app.dart ───────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:movie_match/core/netwok/router.dart';
import 'theme/app_theme.dart';

class MovieMatchApp extends StatelessWidget {
  const MovieMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MovieMatch',
      debugShowCheckedModeBanner: false,
      // theme: AppTheme.light,
      // darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
