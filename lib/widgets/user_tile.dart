import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const UserTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // Avatar
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: user.avatar.isNotEmpty
              ? CachedNetworkImageProvider(user.avatar)
              : null,
          child: user.avatar.isEmpty
              ? Text(
            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          )
              : null,
        ),

        // Name + movie taste
        title: Text(
          user.fullName,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: user.movieTaste.isNotEmpty
            ? Text(
          user.movieTaste,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        )
            : null,

        // Saved movies count badge
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user.savedMoviesCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}