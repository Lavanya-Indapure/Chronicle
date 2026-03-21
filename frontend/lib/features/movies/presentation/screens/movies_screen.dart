import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/movies/presentation/controllers/movie_controller.dart';
import 'package:chronicle/features/movies/presentation/widgets/add_movie_sheet.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(movieControllerProvider);
    final theme = Theme.of(context);
    final movies = state.filteredMovies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies Watched'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SearchBar(
              hintText: 'Search by movie name...',
              leading: const Icon(Icons.search),
              onChanged: (value) => ref.read(movieControllerProvider.notifier).setSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
            ),
          ),
          Expanded(
            child: state.isLoading && state.movies.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : movies.isEmpty
                    ? _EmptyMovies()
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: movies.length,
                        separatorBuilder: (_, __) => AppSpacing.gapMd,
                        itemBuilder: (context, index) {
                          final m = movies[index];
                          return _MovieTile(movie: m);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMovie(context),
        label: const Text('Log Movie'),
        icon: const Icon(Icons.movie_outlined),
      ),
    );
  }

  void _showAddMovie(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const AddMovieSheet(),
    );
  }
}

class _MovieTile extends StatelessWidget {
  final Movie movie;

  const _MovieTile({required this.movie});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTheatre = movie.platform == 'theatre';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: () => _showEditMovie(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isTheatre ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            isTheatre ? Icons.theaters_outlined : Icons.laptop_mac_outlined,
            color: isTheatre ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(movie.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM dd, yyyy').format(movie.watchDate)),
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                  Icons.star,
                  size: 14,
                  color: i < movie.rating ? Colors.amber : theme.disabledColor,
                )),
                if (isTheatre && movie.cost != null) ...[
                  const Text(' • '),
                  Text('₹${movie.cost!.toStringAsFixed(0)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  void _showEditMovie(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddMovieSheet(movie: movie),
    );
  }
}

class _EmptyMovies extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_outlined, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('No movies logged yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
          AppSpacing.gapSm,
          const Text('Track your cinema and streaming memories!'),
        ],
      ),
    );
  }
}
