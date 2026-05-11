import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import 'save_badge.dart';

class MovieCard extends StatefulWidget {
  final MovieModel  movie;
  final int         index;    // for staggered fade-in
  final VoidCallback onTap;
  final VoidCallback onSave;

  const MovieCard({
    super.key,
    required this.movie,
    required this.index,
    required this.onTap,
    required this.onSave,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    // Stagger — each card fades in 60ms after the previous
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movie = widget.movie;

    return FadeTransition(
      opacity: _fade,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Poster with Hero tag ─────────────────────
              Hero(
                tag: 'poster_${movie.id}',
                child: CachedNetworkImage(
                  imageUrl: movie.posterSmall,
                  width: 90,
                  height: 130,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 90, height: 130,
                    color: theme.colorScheme.surfaceVariant,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 90, height: 130,
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                  // Fade image in as it loads
                  fadeInDuration: const Duration(milliseconds: 300),
                ),
              ),

              // ── Movie Info ───────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.releaseYear,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Save count badge + Save button ───
                      Row(
                        children: [
                          // Animated save count badge
                          SaveCountBadge(count: movie.saveCount),
                          const Spacer(),

                          // Save button
                          FilledButton.tonal(
                            onPressed: widget.onSave,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Row(
                                key: ValueKey(movie.isSavedByActiveUser),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    movie.isSavedByActiveUser
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.isSavedByActiveUser ? 'Saved' : 'Save',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}