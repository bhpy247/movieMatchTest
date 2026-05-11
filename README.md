# 🎬 MovieMatch

A Flutter movie discovery app where multiple users can save movies they want to watch — and instantly see which movies everyone agrees on.

Built as a take-home assignment for **Platform Commons**.

---

## What the App Does

- Browse trending movies from TMDB
- Multiple users can each save movies they want to watch
- A **Matches** page shows movies saved by 2+ users — sorted by popularity
- Everything works **fully offline** — users can be added, movies can be saved, and data syncs automatically when internet returns

---

## Pages

| Page | Description |
|------|-------------|
| **Users** | Scrollable list of users from Reqres API with infinite scroll and shimmer loading |
| **Add User** | Form to create a new user — works online and offline |
| **Movies** | Paginated trending movies from TMDB — save/unsave with live badge count |
| **Movie Detail** | Full detail view with hero animation, poster, overview, and who saved it |
| **Saved Movies** | All movies a specific user has saved — works fully offline |
| **Matches** | Movies saved by 2+ users, sorted by save count — live stream from DB |

---

## Tech Stack

| Concern | Library |
|---------|---------|
| State management | `flutter_bloc` (Cubit) |
| Dependency injection | `get_it` |
| Network | `dio` + `dio_smart_retry` |
| Local database | `drift` (SQLite) |
| Background sync | `workmanager` |
| Image loading | `cached_network_image` |
| Navigation | `go_router` |
| Shimmer loading | `shimmer` |
| Connectivity | `connectivity_plus` |

---

## Project Structure

```
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart       # Drift DB setup
│   │   ├── tables.dart             # Table definitions
│   │   └── daos/
│   │       ├── users_dao.dart      # User DB queries
│   │       └── movies_dao.dart     # Movie DB queries + Matches stream
│   ├── network/
│   │   ├── dio_client.dart         # Dio setup with retry + connectivity
│   │   ├── router.dart             # GoRouter — all app routes
│   │   └── service_locator.dart    # get_it DI setup
│   ├── sync/
│   │   └── sync_task.dart          # WorkManager background sync
│   └── constants.dart              # API keys + image URL helpers
│
├── models/
│   ├── user_model.dart             # UserModel (fromJson + fromDb)
│   └── movie_model.dart            # MovieModel (fromJson + fromDb + toCompanion)
│
├── repositories/
│   ├── user_repository.dart        # Reqres API + user DB logic
│   └── movie_repository.dart       # TMDB API + movie DB logic
│
├── cubits/
│   ├── users_cubit.dart            # Users list + pagination + add user
│   ├── movies_cubit.dart           # Movies list + pagination + toggle save
│   ├── saved_movies_cubit.dart     # Saved movies stream (offline-first)
│   └── matches_cubit.dart          # Matches stream from DB
│
├── pages/
│   ├── users_page.dart
│   ├── add_user_page.dart
│   ├── movies_page.dart
│   ├── movie_detail_page.dart
│   ├── saved_movies_page.dart
│   └── matches_page.dart
│
├── widgets/
│   ├── user_tile.dart
│   ├── movie_card.dart             # Staggered fade-in + hero poster
│   ├── save_badge.dart             # Animated scale badge
│   └── shimmer_loader.dart         # ShimmerList + ShimmerTile + ShimmerMovieCard
│
├── theme/
│   └── app_theme.dart              # Material 3 light + dark theme
│
├── app.dart
└── main.dart
```

---

## Database Schema

Three tables — users, movies, and a junction table:

```
┌─────────────────────────────────┐
│           users                 │
├─────────────────────────────────┤
│ id           INTEGER  PK AUTO   │ ← local DB id (used for all DB ops)
│ server_id    INTEGER  NULLABLE  │ ← Reqres server id (null until synced)
│ first_name   TEXT               │
│ last_name    TEXT               │
│ email        TEXT               │
│ avatar_url   TEXT               │
│ movie_taste  TEXT               │ ← maps to "job" in Reqres API
│ pending_sync BOOLEAN            │ ← true = waiting to POST to server
│ created_at   DATETIME           │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│           movies                │
├─────────────────────────────────┤
│ tmdb_id      INTEGER  PK        │ ← TMDB movie id
│ title        TEXT               │
│ overview     TEXT               │
│ poster_path  TEXT               │
│ release_date TEXT               │
│ vote_average REAL               │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│        saved_movies             │
├─────────────────────────────────┤
│ id           INTEGER  PK AUTO   │
│ user_id      INTEGER  FK→users  │ ← references users.id (local id)
│ movie_id     INTEGER  FK→movies │ ← references movies.tmdb_id
│ saved_at     DATETIME           │
│ UNIQUE(user_id, movie_id)       │ ← no duplicates
└─────────────────────────────────┘
```

### Why Two IDs on Users?

Reqres API assigns its own server ID (e.g. `7`). Our local SQLite uses autoincrement (e.g. `1`). All DB foreign key relationships use the **local `id`** — not the server ID. The `server_id` is stored separately so we can match API users to local records on subsequent fetches.

When a user is created offline, `pending_sync = true` and `server_id = null`. WorkManager syncs them in the background when internet returns and fills in the `server_id`.

---

## Offline & Sync Behaviour

### Add User Offline
1. User is saved locally with `pending_sync = true`
2. `WorkManager` registers a one-off task constrained to `NetworkType.connected`
3. When internet returns, WorkManager fires in the background, POSTs to Reqres, saves the returned server ID back to the local record
4. No duplicates — `ExistingWorkPolicy.keep` ensures only one sync task runs

### Browse Movies Offline
Every movie fetched from TMDB is immediately upserted into the local `movies` table. If the device goes offline, the Movies page falls back to the local cache automatically.

### Save Movies Offline
Save/unsave writes directly to the local `saved_movies` table — no network call needed. The Matches page and Saved Movies page both read entirely from DB streams, so they always reflect the latest state instantly.

---

## Bad Connection Handling

- **Dio retry interceptor** — 3 retries with exponential backoff (1s → 3s → 6s)
- **Connectivity interceptor** — rejects requests immediately if offline, no timeout wait
- **No full-screen errors** on already-loaded lists — snackbar only
- **Offline banner** shown at top of Users and Movies pages when serving cached data

---

## Design System

**Material Design 3** with a custom dark/light theme.

- **Primary seed color:** `#E50914` (deep red)
- **Dark background:** `#0F0F0F` with surface `#1C1C1C`
- Consistent `BorderRadius` values: `8 / 12 / 16 / 20`
- All components use `ColorScheme` tokens — no hardcoded colors in widgets

### Animations
- **Hero animation** — movie poster transitions from list card into detail page
- **Staggered fade-in** — each movie card fades in 60ms after the previous
- **Save badge bounce** — scale animation on the save count when it changes
- **AnimatedSwitcher** — save button icon swaps smoothly on toggle
- **CachedNetworkImage fade** — images fade in gently as they load
- **Shimmer skeletons** — shown on first load and during pagination

---

## API Keys Setup

1. **TMDB** — sign up at [themoviedb.org](https://themoviedb.org) → Settings → API
2. **Reqres** — get key at [reqres.in](https://reqres.in)

Add both to `lib/core/constants.dart`:

```dart
static const String tmdbApiKey   = 'YOUR_TMDB_KEY';
static const String reqresApiKey = 'YOUR_REQRES_KEY';
```

---

## Running the App

```bash
# Install dependencies
flutter pub get

# Generate Drift DB code
dart run build_runner build --delete-conflicting-outputs

# Run
flutter run
```

---

## AI Usage

This project was built with assistance from **Claude (Anthropic)** via Claude.ai.

A full conversation link covering architecture decisions, code generation, bug fixes, and iteration is included with this submission:

> 🔗  https://claude.ai/share/7734671f-3017-488c-810b-22def069ab8d

Prompts covered:
- Initial architecture planning (folder structure, DB schema, state management choice)
- Scaffold generation (pubspec, tables, DAOs, Dio client, WorkManager)
- Feature-by-feature code generation (models, repositories, cubits, pages, widgets)
- Bug fixes (Drift generated class naming, localId vs serverId, DB upsert flow)
- UI polish (shimmer fix, hero animation, save badge animation)

---

## APK

> 📦 https://drive.google.com/file/d/1XHtky6_-CX8QEUdmaCvQJtfFsLcQ7yXk/view?usp=sharing