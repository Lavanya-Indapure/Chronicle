import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/features/miscellaneous/domain/models/misc_item.dart';
import 'package:chronicle/features/miscellaneous/presentation/controllers/misc_controller.dart';
import 'package:chronicle/features/miscellaneous/presentation/widgets/misc_item_card.dart';
import 'package:chronicle/features/miscellaneous/presentation/widgets/misc_item_sheet.dart';

/// Catch-all notes and pictures, newest first. Tap a card to edit.
class MiscellaneousScreen extends ConsumerWidget {
  const MiscellaneousScreen({super.key});

  static void _openSheet(BuildContext context, {MiscItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MiscItemSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(miscControllerProvider);
    final controller = ref.read(miscControllerProvider.notifier);
    final items = state.filteredItems;
    final hasAny = state.items.isNotEmpty;

    ref.listen(miscControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.miscellaneousLabel)),
      body: state.isLoading && !hasAny
          ? const Center(child: CircularProgressIndicator())
          : !hasAny
              ? EmptyState(
                  icon: Icons.widgets_rounded,
                  title: AppStrings.miscEmptyTitle,
                  message: AppStrings.miscEmptyMessage,
                  actionLabel: AppStrings.miscAddFirst,
                  onAction: () => _openSheet(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
                      child: AppSearchField(hint: AppStrings.miscSearchHint, onChanged: controller.setSearchQuery),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: AppStrings.journalNoResultsTitle,
                              message: AppStrings.journalNoResultsMessage,
                              muted: true,
                            )
                          : RefreshIndicator(
                              onRefresh: controller.loadItems,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxxl + AppSpacing.xl),
                                itemCount: items.length,
                                separatorBuilder: (_, _) => AppSpacing.gapSm,
                                itemBuilder: (context, index) => MiscItemCard(
                                  item: items[index],
                                  onTap: () => _openSheet(context, item: items[index]),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: hasAny
          ? FloatingActionButton.extended(
              onPressed: () => _openSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.miscAdd),
            )
          : null,
    );
  }
}
