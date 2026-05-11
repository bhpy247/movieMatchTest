import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Full page shimmer — shown on first load
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 8,
      itemBuilder: (_, __) => const ShimmerTile(),
    );
  }
}

// Single shimmer tile — used both in ShimmerList
// and at bottom of real list during pagination
class ShimmerTile extends StatelessWidget {
  const ShimmerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar placeholder
              const CircleAvatar(radius: 26, backgroundColor: Colors.white),
              const SizedBox(width: 16),

              // Text placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 14,
                        width: 140,

                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                          color: Colors.white,)),
                    const SizedBox(height: 8),
                    Container(
                        height: 11,
                        width: 100,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        )),
                  ],
                ),
              ),

              // Badge placeholder
              Container(
                height: 26,
                width: 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Movie card shimmer — used on Movies page
class ShimmerMovieCard extends StatelessWidget {
  const ShimmerMovieCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Poster placeholder
            Container(
              width: 90,
              height: 130,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                        height: 11,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        )),
                    const SizedBox(height: 16),
                    Container(
                        height: 32,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
