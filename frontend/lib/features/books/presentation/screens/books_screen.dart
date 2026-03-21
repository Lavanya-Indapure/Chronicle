import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/books/presentation/controllers/book_controller.dart';
import 'package:chronicle/features/books/presentation/widgets/add_book_sheet.dart';
import 'package:chronicle/features/books/domain/models/book.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookControllerProvider);
    final theme = Theme.of(context);
    final books = state.filteredBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          IconButton(
            icon: Icon(state.onlyFavorites ? Icons.favorite : Icons.favorite_border, color: state.onlyFavorites ? Colors.red : null),
            onPressed: () => ref.read(bookControllerProvider.notifier).toggleOnlyFavorites(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SearchBar(
              hintText: 'Search book or author...',
              leading: const Icon(Icons.search),
              onChanged: (value) => ref.read(bookControllerProvider.notifier).setSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _StatusChip(label: 'All', isSelected: state.statusFilter == null, onTap: () => ref.read(bookControllerProvider.notifier).setStatusFilter(null)),
                AppSpacing.gapSm,
                _StatusChip(label: 'Reading', isSelected: state.statusFilter == 'reading', onTap: () => ref.read(bookControllerProvider.notifier).setStatusFilter('reading')),
                AppSpacing.gapSm,
                _StatusChip(label: 'Completed', isSelected: state.statusFilter == 'completed', onTap: () => ref.read(bookControllerProvider.notifier).setStatusFilter('completed')),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading && state.books.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : books.isEmpty
                    ? _EmptyBooks()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final b = books[index];
                          return _BookCard(book: b);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBook(context),
        label: const Text('Add Book'),
        icon: const Icon(Icons.menu_book),
      ),
    );
  }

  void _showAddBook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const AddBookSheet(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _showEditBook(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.book, color: theme.colorScheme.primary),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        if (book.author != null) Text(book.author!, style: theme.textTheme.bodySmall),
                        AppSpacing.gapSm,
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: book.status == 'completed' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                book.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: book.status == 'completed' ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                            if (book.rating != null) ...[
                              AppSpacing.gapMd,
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              AppSpacing.gapXs,
                              Text(book.rating!.toString(), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(book.isFavorite ? Icons.favorite : Icons.favorite_border, color: book.isFavorite ? Colors.red : null),
                    onPressed: () => ref.read(bookControllerProvider.notifier).toggleFavorite(book),
                  ),
                ],
              ),
              if (book.takeaways != null && book.takeaways!.isNotEmpty) ...[
                AppSpacing.gapMd,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Takeaways', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      AppSpacing.gapXs,
                      Text(book.takeaways!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddBookSheet(book: book),
    );
  }
}

class _EmptyBooks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('Your library is empty', style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
          AppSpacing.gapSm,
          const Text('Track your reading progress and key takeaways!'),
        ],
      ),
    );
  }
}
