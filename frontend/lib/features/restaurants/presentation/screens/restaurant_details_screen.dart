import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/storage_image.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';
import 'package:chronicle/features/restaurants/presentation/widgets/revisit_sheet.dart';

class RestaurantDetailsScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends ConsumerState<RestaurantDetailsScreen> {
  late Future<List<RestaurantVisit>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<RestaurantVisit>> _loadHistory() =>
      ref.read(restaurantControllerProvider.notifier).getVisitHistory(widget.restaurant.id);

  void _refresh() => setState(() => _historyFuture = _loadHistory());

  @override
  Widget build(BuildContext context) {
    // Use the live copy from the controller so favourite / visit count /
    // rating update after changes; fall back to the one we were opened with.
    final r = ref.watch(restaurantControllerProvider.select(
      (s) => s.restaurants.where((x) => x.id == widget.restaurant.id).firstOrNull,
    )) ?? widget.restaurant;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          IconButton(
            tooltip: AppStrings.favorite,
            isSelected: r.isFavorite,
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.error),
            onPressed: () => ref.read(restaurantControllerProvider.notifier).toggleFavorite(r),
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: ListView(
        // Bottom padding keeps the last visit clear of the FAB.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.xxxl + AppSpacing.xl,
        ),
        children: [
          Row(
            children: [
              _StatPill(icon: Icons.star_rounded, color: AppColors.chartLemon, label: r.rating.toStringAsFixed(1)),
              AppSpacing.hGapSm,
              _StatPill(
                icon: Icons.repeat_rounded,
                color: AppColors.chartBlue,
                label: '${r.visitCount} ${r.visitCount == 1 ? AppStrings.visitSingular : AppStrings.visitPlural}',
              ),
            ],
          ),
          if (r.address.trim().isNotEmpty) ...[
            AppSpacing.gapMd,
            _AddressCard(address: r.address),
          ],
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.visitHistory),
          AppSpacing.gapMd,
          FutureBuilder<List<RestaurantVisit>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final history = snapshot.data ?? const [];
              if (history.isEmpty) {
                return SurfaceCard(
                  child: Center(
                    child: Text(AppStrings.noVisitsYet, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                );
              }
              return Column(
                children: [
                  for (final visit in history) ...[
                    _VisitCard(visit: visit),
                    if (visit != history.last) AppSpacing.gapMd,
                  ],
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRevisitSheet(context, r),
        label: const Text(AppStrings.visitedAgain),
        icon: const Icon(Icons.add_task_rounded),
      ),
    );
  }

  void _showRevisitSheet(BuildContext context, Restaurant r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => RevisitSheet(restaurant: r, onLogged: _refresh),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatPill({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 2, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: AppSpacing.borderRadiusPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.md + 2, color: color),
          AppSpacing.hGapXs,
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String address;

  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const IconBadge(icon: Icons.place_outlined, color: AppColors.chartTeal),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.address, style: theme.textTheme.bodySmall),
                Text(address, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final RestaurantVisit visit;

  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final food = visit.foodItems?.trim();
    final notes = visit.notes?.trim();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppFormatters.dayMonthYear(visit.visitDate), style: theme.textTheme.titleMedium),
              ),
              if (visit.rating != null) ...[
                const Icon(Icons.star_rounded, size: AppSpacing.md + 2, color: AppColors.chartLemon),
                AppSpacing.hGapXs,
                Text(visit.rating!.toStringAsFixed(1), style: theme.textTheme.labelLarge),
              ],
            ],
          ),
          if (visit.billAmount != null) ...[
            AppSpacing.gapXs,
            Text(AppFormatters.currency(visit.billAmount!), style: theme.textTheme.titleSmall?.copyWith(color: colors.primary)),
          ],
          if (food != null && food.isNotEmpty) ...[
            AppSpacing.gapSm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.restaurant_menu_rounded, size: AppSpacing.md, color: colors.onSurfaceVariant),
                AppSpacing.hGapSm,
                Expanded(child: Text(food, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            AppSpacing.gapSm,
            Text(notes, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (visit.photos.isNotEmpty) ...[
            AppSpacing.gapMd,
            SizedBox(
              height: AppSpacing.visitPhotoSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visit.photos.length,
                separatorBuilder: (_, _) => AppSpacing.hGapSm,
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: AppSpacing.borderRadiusMd,
                  child: StorageImage(
                    bucket: AppConstants.restaurantsBucket,
                    path: visit.photos[index].storagePath,
                    width: AppSpacing.visitPhotoSize,
                    height: AppSpacing.visitPhotoSize,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
