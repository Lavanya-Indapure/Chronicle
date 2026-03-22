import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
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
    _historyFuture = ref.read(restaurantControllerProvider.notifier).getVisitHistory(widget.restaurant.id);
  }

  void _refresh() {
    setState(() {
      _historyFuture = ref.read(restaurantControllerProvider.notifier).getVisitHistory(widget.restaurant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.restaurant;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          IconButton(
            icon: Icon(r.isFavorite ? Icons.favorite : Icons.favorite_border, color: r.isFavorite ? Colors.red : null),
            onPressed: () => ref.read(restaurantControllerProvider.notifier).toggleFavorite(r),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Aggregate Stats
            Row(
              children: [
                _StatBadge(icon: Icons.star, label: r.rating.toString(), color: Colors.amber),
                AppSpacing.gapMd,
                _StatBadge(icon: Icons.repeat, label: '${r.visitCount} visits', color: theme.colorScheme.primary),
              ],
            ),
            AppSpacing.gapMd,
            Text('Address', style: theme.textTheme.titleSmall),
            Text(r.address, style: theme.textTheme.bodyMedium),
            AppSpacing.gapLg,

            // History Timeline
            Text('Visit History', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.gapMd,
            FutureBuilder<List<RestaurantVisit>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Something went wrong or no history found.');
                }
                final history = snapshot.data!;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final visit = history[index];
                    return _VisitTile(visit: visit);
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRevisitSheet(context),
        label: const Text('Visited Cor Again'),
        icon: const Icon(Icons.add_task),
      ),
    );
  }

  void _showRevisitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => RevisitSheet(restaurant: widget.restaurant, onLogged: _refresh),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppSpacing.gapXs,
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final RestaurantVisit visit;

  const _VisitTile({required this.visit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(visit.visitDate.toString().split(' ').first, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (visit.rating != null)
                 Row(children: [const Icon(Icons.star, size: 14, color: Colors.amber), AppSpacing.gapXs, Text(visit.rating!.toStringAsFixed(1))]),
            ],
          ),
          if (visit.foodItems != null) ...[
            AppSpacing.gapSm,
            Row(
              children: [
                const Icon(Icons.flatware, size: 14),
                AppSpacing.gapXs,
                Expanded(child: Text(visit.foodItems!, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ],
          if (visit.billAmount != null) ...[
            AppSpacing.gapXs,
            Text('Bill: ₹${visit.billAmount!.toStringAsFixed(0)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
           if (visit.notes != null) ...[
            AppSpacing.gapSm,
            Text(visit.notes!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (visit.photos.isNotEmpty) ...[
            AppSpacing.gapSm,
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visit.photos.length,
                separatorBuilder: (_, index) => AppSpacing.gapSm,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(visit.photos[index].imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
