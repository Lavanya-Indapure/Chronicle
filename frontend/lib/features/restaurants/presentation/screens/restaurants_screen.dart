import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';
import 'package:chronicle/features/restaurants/presentation/widgets/add_restaurant_sheet.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';

class RestaurantsScreen extends ConsumerWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantControllerProvider);
    final theme = Theme.of(context);
    final restaurants = state.filteredRestaurants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explored Restaurants'),
        actions: [
          IconButton(
            icon: Icon(
              state.filters.onlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: state.filters.onlyFavorites ? Colors.red : null,
            ),
            onPressed: () => ref.read(restaurantControllerProvider.notifier).setFilters(
              state.filters.copyWith(onlyFavorites: !state.filters.onlyFavorites),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortingOptions(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SearchBar(
              hintText: 'Search restaurant or food...',
              leading: const Icon(Icons.search),
              onChanged: (value) => ref.read(restaurantControllerProvider.notifier).setSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
            ),
          ),
          Expanded(
            child: state.isLoading && state.restaurants.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : restaurants.isEmpty
                    ? _EmptyRestaurants()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final r = restaurants[index];
                          return _RestaurantCard(restaurant: r);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRestaurant(context),
        label: const Text('Add Restaurant'),
        icon: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }

  void _showAddRestaurant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const AddRestaurantSheet(),
    );
  }

  void _showSortingOptions(BuildContext context, WidgetRef ref) {
    final filters = ref.read(restaurantControllerProvider).filters;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: RestaurantSorting.values.map((s) {
          final label = s == RestaurantSorting.latestVisited ? 'Latest Visited' :
                        s == RestaurantSorting.highestRated ? 'Highest Rated' : 'Most Visited';
          return ListTile(
            title: Text(label),
            trailing: filters.sorting == s ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              ref.read(restaurantControllerProvider.notifier).setFilters(filters.copyWith(sorting: s));
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _RestaurantCard extends ConsumerWidget {
  final Restaurant restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final firstPhoto = restaurant.photos.isNotEmpty ? restaurant.photos.first.imageUrl : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push('/more/restaurants/details', extra: restaurant),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (firstPhoto != null)
              Image.network(firstPhoto, height: 160, fit: BoxFit.cover)
            else
              Container(
                height: 100,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Icon(Icons.restaurant, size: 40, color: theme.disabledColor),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(restaurant.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(restaurant.isFavorite ? Icons.favorite : Icons.favorite_border),
                        color: restaurant.isFavorite ? Colors.red : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => ref.read(restaurantControllerProvider.notifier).toggleFavorite(restaurant),
                      ),
                    ],
                  ),
                  Text(restaurant.address, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  AppSpacing.gapSm,
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      AppSpacing.gapXs,
                      Text(restaurant.rating.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      AppSpacing.gapMd,
                      Icon(Icons.repeat, size: 18, color: theme.colorScheme.primary),
                      AppSpacing.gapXs,
                      Text('Visited ${restaurant.visitCount} times', style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      if (restaurant.latestBillAmount != null)
                        Text('₹${restaurant.latestBillAmount!.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (restaurant.latestFoodItems != null) ...[
                    AppSpacing.gapSm,
                    Text('Recommended: ${restaurant.latestFoodItems}', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRestaurants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('No restaurants logged', style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
          AppSpacing.gapSm,
          const Text('Start tracking your dining adventures!'),
        ],
      ),
    );
  }
}
