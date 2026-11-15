import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/places/presentation/controllers/place_controller.dart';
import 'package:chronicle/features/places/domain/models/place_visited.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';

class PlacesVisitedScreen extends ConsumerWidget {
  const PlacesVisitedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placeControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Log'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search places or cities...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (val) => ref.read(placeControllerProvider.notifier).setSearchQuery(val),
            ),
          ),
        ),
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : state.places.isEmpty 
          ? _EmptyPlaces()
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.filteredPlaces.length,
              itemBuilder: (context, index) {
                final place = state.filteredPlaces[index];
                return _PlaceCard(place: place);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlace(context, ref),
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  void _showAddPlace(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddPlaceSheet(ref: ref),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final PlaceVisited place;
  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(place.placeName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(place.city ?? 'Unknown City'),
            trailing: Text(DateFormat('MMM yyyy').format(place.visitDate)),
          ),
          if (place.description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Text(place.description!, style: theme.textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (place.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(' ${place.rating}', style: theme.textTheme.labelLarge),
                    ],
                  ),
                const Spacer(),
                const Icon(Icons.rebase_edit, size: 14),
                const Text(' Visited Once', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPlaceSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddPlaceSheet({required this.ref});
  @override State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _descController = TextEditingController();
  int _rating = 4;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KeyboardAwareSheet(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Log Visit', style: theme.textTheme.headlineSmall),
          AppSpacing.gapMd,
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Place Name')),
          AppSpacing.gapMd,
          TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City/Region')),
          AppSpacing.gapMd,
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Experience Details'), maxLines: 2),
          AppSpacing.gapMd,
          ListTile(
            title: const Text('Visit Date'),
            trailing: Text(DateFormat('yyyy-MM-dd').format(_date)),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
          ),
          AppSpacing.gapMd,
          const Text('Rating'),
          Slider(value: _rating.toDouble(), min: 1, max: 5, divisions: 4, label: _rating.toString(), onChanged: (v) => setState(() => _rating = v.toInt())),
          AppSpacing.gapLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  widget.ref.read(placeControllerProvider.notifier).addPlace(PlaceVisited(
                    id: '',
                    userId: '',
                    placeName: _nameController.text,
                    city: _cityController.text,
                    visitDate: _date,
                    description: _descController.text,
                    rating: _rating,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('ADD PLACE'),
            ),
          ),
          AppSpacing.gapXl,
        ],
      ),
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('Exploring the world?', style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
          Text('Start logging your travel memories here.', style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }
}
