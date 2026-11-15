import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/widgets/storage_image.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';
import 'package:chronicle/features/restaurants/presentation/widgets/add_restaurant_sheet.dart';

/// Quick filters shown as pills; map onto [RestaurantFilters].
enum _QuickFilter { all, favourites, topRated }

/// Minimum rating for the "Top rated" pill.
const double _topRatedMin = 4;

class RestaurantsScreen extends ConsumerWidget {
  const RestaurantsScreen({super.key});

  static _QuickFilter _quickFilterOf(RestaurantFilters f) => f.onlyFavorites
      ? _QuickFilter.favourites
      : (f.minRating != null ? _QuickFilter.topRated : _QuickFilter.all);

  static String _quickFilterLabel(_QuickFilter f) => switch (f) {
        _QuickFilter.all => AppStrings.filterAllRestaurants,
        _QuickFilter.favourites => AppStrings.filterFavourites,
        _QuickFilter.topRated => AppStrings.filterTopRated,
      };

  static String _sortLabel(RestaurantSorting s) => switch (s) {
        RestaurantSorting.latestVisited => AppStrings.sortLatestVisited,
        RestaurantSorting.highestRated => AppStrings.sortHighestRated,
        RestaurantSorting.mostVisited => AppStrings.sortMostVisited,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantControllerProvider);
    final controller = ref.read(restaurantControllerProvider.notifier);
    final restaurants = state.filteredRestaurants;
    final hasAny = state.restaurants.isNotEmpty;

    ref.listen(restaurantControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    void setQuickFilter(_QuickFilter f) => controller.setFilters(switch (f) {
          _QuickFilter.all => state.filters.copyWith(onlyFavorites: false, clearRating: true),
          _QuickFilter.favourites => state.filters.copyWith(onlyFavorites: true, clearRating: true),
          _QuickFilter.topRated => state.filters.copyWith(onlyFavorites: false, minRating: _topRatedMin),
        });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.restaurantsLabel),
        actions: [
          PopupMenuButton<RestaurantSorting>(
            tooltip: AppStrings.sortBy,
            icon: const Icon(Icons.sort_rounded),
            onSelected: (s) => controller.setFilters(state.filters.copyWith(sorting: s)),
            itemBuilder: (context) => [
              for (final s in RestaurantSorting.values)
                CheckedPopupMenuItem(value: s, checked: state.filters.sorting == s, child: Text(_sortLabel(s))),
            ],
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasAny) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
              child: AppSearchField(hint: AppStrings.searchRestaurantsHint, onChanged: controller.setSearchQuery),
            ),
            Padding(
              padding: AppSpacing.paddingGutter,
              child: PillTabs<_QuickFilter>(
                values: _QuickFilter.values,
                labelOf: _quickFilterLabel,
                selected: _quickFilterOf(state.filters),
                onChanged: setQuickFilter,
              ),
            ),
          ],
          Expanded(
            child: state.isLoading && !hasAny
                ? const Center(child: CircularProgressIndicator())
                : !hasAny
                    ? EmptyState(
                        icon: Icons.restaurant_rounded,
                        title: AppStrings.noRestaurantsTitle,
                        message: AppStrings.noRestaurantsMessage,
                        actionLabel: AppStrings.addFirstRestaurant,
                        onAction: () => _showAddRestaurant(context),
                      )
                    : restaurants.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: AppStrings.noMatchesTitle,
                            message: AppStrings.noMatchesMessage,
                            muted: true,
                          )
                        : RefreshIndicator(
                            onRefresh: controller.loadRestaurants,
                            child: ListView.separated(
                              // Bottom padding keeps the last card clear of the FAB.
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.gutter,
                                AppSpacing.lg,
                                AppSpacing.gutter,
                                AppSpacing.xxxl + AppSpacing.xl,
                              ),
                              itemCount: restaurants.length,
                              separatorBuilder: (_, _) => AppSpacing.gapSm,
                              itemBuilder: (context, index) => _RestaurantCard(
                                restaurant: restaurants[index],
                                onToggleFavourite: () => controller.toggleFavorite(restaurants[index]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: hasAny
          ? FloatingActionButton.extended(
              onPressed: () => _showAddRestaurant(context),
              label: const Text(AppStrings.addRestaurant),
              icon: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _showAddRestaurant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const AddRestaurantSheet(),
    );
  }
}

/// Thumbnail + name/address + "★ 4.5 · 3 visits ....... ₹1,200".
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onToggleFavourite;

  const _RestaurantCard({required this.restaurant, required this.onToggleFavourite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final r = restaurant;
    final photo = r.photos.isNotEmpty ? r.photos.first.storagePath : null;
    final visits = '${r.visitCount} ${r.visitCount == 1 ? AppStrings.visitSingular : AppStrings.visitPlural}';
    final food = r.latestFoodItems?.trim();

    return SurfaceCard(
      onTap: () => context.push('/more/restaurants/details', extra: r),
      padding: const EdgeInsets.all(AppSpacing.md - 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusLg,
            child: photo != null
                ? StorageImage(
                    bucket: AppConstants.restaurantsBucket,
                    path: photo,
                    width: AppSpacing.visitPhotoSize,
                    height: AppSpacing.visitPhotoSize,
                  )
                : SizedBox.square(
                    dimension: AppSpacing.visitPhotoSize,
                    child: ColoredBox(
                      color: colors.surfaceContainerHigh,
                      child: const Icon(Icons.restaurant_rounded, color: AppColors.chartOrange, size: AppSpacing.xl),
                    ),
                  ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _FavouriteButton(isFavourite: r.isFavorite, onTap: onToggleFavourite),
                  ],
                ),
                if (r.address.trim().isNotEmpty)
                  Text(r.address, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (food != null && food.isNotEmpty)
                  Text(
                    food,
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                AppSpacing.gapSm,
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: AppSpacing.md + 2, color: AppColors.chartLemon),
                    AppSpacing.hGapXs,
                    Text(r.rating.toStringAsFixed(1), style: theme.textTheme.labelLarge),
                    // Shrinks (ellipsis) first so the row never overflows on
                    // narrow cards or large text sizes.
                    Expanded(
                      child: Text(
                        '  ·  $visits',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (r.latestBillAmount != null)
                      Text(
                        AppFormatters.currency(r.latestBillAmount!),
                        style: theme.textTheme.titleSmall?.copyWith(color: colors.primary),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact heart that doesn't reserve a full 48dp row height.
class _FavouriteButton extends StatelessWidget {
  final bool isFavourite;
  final VoidCallback onTap;

  const _FavouriteButton({required this.isFavourite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.favorite,
      child: InkResponse(
        onTap: onTap,
        radius: AppSpacing.lg,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Icon(
            isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: AppSpacing.lg - 2,
            color: isFavourite ? AppColors.error : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
