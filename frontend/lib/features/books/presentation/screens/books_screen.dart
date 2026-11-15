import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/books/domain/models/book.dart';
import 'package:chronicle/features/books/presentation/controllers/book_controller.dart';
import 'package:chronicle/features/books/presentation/widgets/add_book_sheet.dart';
import 'package:chronicle/core/widgets/star_rating.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  /// Status filter values; null = all.
  static const List<String?> _statuses = [null, 'reading', 'completed'];

  static String _statusName(String? s) => switch (s) {
        'reading' => AppStrings.bookStatusReading,
        'completed' => AppStrings.bookStatusCompleted,
        _ => AppStrings.statusAll,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookControllerProvider);
    final controller = ref.read(bookControllerProvider.notifier);
    final books = state.filteredBooks;

    ref.listen(bookControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myLibrary),
        actions: [
          IconButton(
            tooltip: AppStrings.favoritesOnly,
            isSelected: state.onlyFavorites,
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.error),
            onPressed: controller.toggleOnlyFavorites,
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
            child: AppSearchField(hint: AppStrings.searchBooksHint, onChanged: controller.setSearchQuery),
          ),
          Padding(
            padding: AppSpacing.paddingGutter,
            child: PillTabs<String?>(
              values: _statuses,
              labelOf: (s) => '${_statusName(s)} ${state.countFor(s)}',
              selected: state.statusFilter,
              onChanged: controller.setStatusFilter,
            ),
          ),
          Expanded(
            child: state.isLoading && state.books.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : books.isEmpty
                    ? state.books.isEmpty
                        ? EmptyState(
                            icon: Icons.menu_book_rounded,
                            title: AppStrings.libraryEmptyTitle,
                            message: AppStrings.libraryEmptyMessage,
                            actionLabel: AppStrings.addBook,
                            onAction: () => _showBookSheet(context),
                          )
                        : const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: AppStrings.libraryNoMatchesTitle,
                            message: AppStrings.libraryNoMatchesMessage,
                            muted: true,
                          )
                    : RefreshIndicator(
                        onRefresh: controller.loadBooks,
                        child: ListView.separated(
                          // Bottom padding keeps the last card clear of the FAB.
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.gutter,
                            AppSpacing.lg,
                            AppSpacing.gutter,
                            AppSpacing.xxxl + AppSpacing.xl,
                          ),
                          itemCount: books.length,
                          separatorBuilder: (_, _) => AppSpacing.gapMd,
                          itemBuilder: (context, index) => _BookCard(
                            book: books[index],
                            onTap: () => _showBookSheet(context, book: books[index]),
                            onToggleFavorite: () => controller.toggleFavorite(books[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: state.books.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showBookSheet(context),
              label: const Text(AppStrings.addBook),
              icon: const Icon(Icons.add_rounded),
            ),
    );
  }

  void _showBookSheet(BuildContext context, {Book? book}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddBookSheet(book: book),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _BookCard({required this.book, required this.onTap, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = book.status == 'completed';
    final takeaways = book.takeaways?.trim();

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookCover(title: book.name),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author?.trim().isNotEmpty ?? false)
                      Text(book.author!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    AppSpacing.gapSm,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Tag(
                          text: completed ? AppStrings.bookStatusCompleted : AppStrings.bookStatusReading,
                          color: completed ? AppColors.success : AppColors.info,
                        ),
                        if (book.rating != null) StarRatingDisplay(rating: book.rating!),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.favorite,
                isSelected: book.isFavorite,
                onPressed: onToggleFavorite,
                icon: Icon(Icons.favorite_border_rounded, color: theme.colorScheme.onSurfaceVariant),
                selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.error),
              ),
            ],
          ),
          if (takeaways != null && takeaways.isNotEmpty) ...[
            AppSpacing.gapMd,
            _Quote(text: takeaways),
          ],
        ],
      ),
    );
  }
}

/// Coloured "cover" with the title's first letter (no cover images stored).
class _BookCover extends StatelessWidget {
  final String title;

  const _BookCover({required this.title});

  static const double _width = AppSpacing.xxl + AppSpacing.sm; // 56
  static const double _height = AppSpacing.xxxl + AppSpacing.md; // 80

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.chartPalette;
    final color = palette[title.hashCode.abs() % palette.length];
    final initial = title.trim().isEmpty ? '?' : title.trim().characters.first.toUpperCase();
    return Container(
      width: _width,
      height: _height,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: AppSpacing.borderRadiusMd),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppSpacing.borderRadiusPill),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// Takeaways shown as a quote with an accent bar.
class _Quote extends StatelessWidget {
  final String text;

  const _Quote({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Accent bar drawn as a separate strip: Flutter can't round a box whose
    // border is only on one side.
    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusMd,
      child: ColoredBox(
        color: colors.surfaceContainerLowest,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: AppSpacing.xs - 1, child: ColoredBox(color: colors.primary)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 4, vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.keyTakeaways, style: theme.textTheme.labelSmall?.copyWith(color: colors.primary)),
                      AppSpacing.gapXs,
                      Text(
                        text,
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
