import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/core/widgets/tag_filter_row.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/core/widgets/star_rating.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';
import 'package:chronicle/features/movies/presentation/controllers/movie_controller.dart';
import 'package:chronicle/features/movies/presentation/widgets/add_movie_sheet.dart';
import 'package:chronicle/features/movies/presentation/widgets/movie_platform.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  static const List<String?> _platforms = [null, MoviePlatform.theatre, MoviePlatform.digital];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(movieControllerProvider);
    final controller = ref.read(movieControllerProvider.notifier);
    final movies = state.filteredMovies;

    ref.listen(movieControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moviesWatched)),
      body: state.isLoading && state.movies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.movies.isEmpty
              ? EmptyState(
                  icon: Icons.movie_rounded,
                  title: AppStrings.moviesEmptyTitle,
                  message: AppStrings.moviesEmptyMessage,
                  actionLabel: AppStrings.logMovie,
                  onAction: () => _showMovieSheet(context),
                )
              : RefreshIndicator(
                  onRefresh: controller.loadMovies,
                  child: ListView(
                    // Bottom padding keeps the last card clear of the FAB.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.sm,
                      AppSpacing.gutter,
                      AppSpacing.xxxl + AppSpacing.xl,
                    ),
                    children: [
                      _YearSummary(count: state.watchedThisYear, theatreSpend: state.theatreSpendThisYear),
                      AppSpacing.gapMd,
                      AppSearchField(hint: AppStrings.searchMoviesHint, onChanged: controller.setSearchQuery),
                      AppSpacing.gapMd,
                      PillTabs<String?>(
                        values: _platforms,
                        labelOf: (p) => '${p == null ? AppStrings.statusAll : MoviePlatform.label(p)} ${state.countFor(p)}',
                        selected: state.platformFilter,
                        onChanged: controller.setPlatformFilter,
                      ),
                      if (state.allTags.isNotEmpty) ...[
                        AppSpacing.gapMd,
                        TagFilterRow(
                          tags: state.allTags,
                          selected: state.selectedTag,
                          onSelected: controller.setSelectedTag,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                      AppSpacing.gapLg,
                      // (EmptyState scrolls itself, so it can't sit inside this ListView.)
                      if (movies.isEmpty)
                        SurfaceCard(
                          child: Column(
                            children: [
                              Text(AppStrings.libraryNoMatchesTitle, style: Theme.of(context).textTheme.titleMedium),
                              AppSpacing.gapXs,
                              Text(AppStrings.libraryNoMatchesMessage, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        )
                      else
                        for (final m in movies) ...[
                          _MovieCard(movie: m, onTap: () => _showMovieSheet(context, movie: m)),
                          if (m != movies.last) AppSpacing.gapSm,
                        ],
                    ],
                  ),
                ),
      floatingActionButton: state.movies.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showMovieSheet(context),
              label: const Text(AppStrings.logMovie),
              icon: const Icon(Icons.add_rounded),
            ),
    );
  }

  void _showMovieSheet(BuildContext context, {Movie? movie}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddMovieSheet(movie: movie),
    );
  }
}

/// "12 movies this year · ₹1,450 spent at theatres"
class _YearSummary extends StatelessWidget {
  final int count;
  final double theatreSpend;

  const _YearSummary({required this.count, required this.theatreSpend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimaryContainer;

    Widget stat(String value, String label) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w700)),
              ),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: ink), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXl),
      child: Row(
        children: [
          stat(
            '$count ${count == 1 ? AppStrings.movieCountSuffix : AppStrings.moviesCountSuffix}',
            AppStrings.moviesThisYear,
          ),
          AppSpacing.hGapMd,
          stat(AppFormatters.currency(theatreSpend), AppStrings.theatreSpend),
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTheatre = movie.platform == MoviePlatform.theatre;
    final comment = movie.comments?.trim();

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: MoviePlatform.icon(movie.platform), color: MoviePlatform.color(movie.platform)),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${AppFormatters.dayMonthYear(movie.watchDate)} · ${MoviePlatform.label(movie.platform)}',
                  style: theme.textTheme.bodySmall,
                ),
                AppSpacing.gapSm,
                StarRatingDisplay(rating: movie.rating.toDouble()),
                if (movie.tags.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [for (final tag in movie.tags) TagPill(text: '#$tag', color: AppColors.chartCoral)],
                  ),
                ],
                if (comment != null && comment.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Text(
                    comment,
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (isTheatre && movie.cost != null) ...[
            AppSpacing.hGapSm,
            Text(AppFormatters.currency(movie.cost!), style: theme.textTheme.titleSmall),
          ],
        ],
      ),
    );
  }
}
