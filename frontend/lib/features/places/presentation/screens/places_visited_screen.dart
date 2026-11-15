import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/widgets/star_rating.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/places/domain/models/place_visited.dart';
import 'package:chronicle/features/places/presentation/controllers/place_controller.dart';

class PlacesVisitedScreen extends ConsumerWidget {
  const PlacesVisitedScreen({super.key});

  void _showAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddPlaceSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placeControllerProvider);
    final controller = ref.read(placeControllerProvider.notifier);
    final places = state.filteredPlaces;
    final hasAny = state.places.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.placesTitle)),
      body: state.isLoading && !hasAny
          ? const Center(child: CircularProgressIndicator())
          : !hasAny
              ? EmptyState(
                  icon: Icons.explore_outlined,
                  title: AppStrings.placesEmptyTitle,
                  message: AppStrings.placesEmptyMessage,
                  actionLabel: AppStrings.placesAddFirst,
                  onAction: () => _showAdd(context, ref),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
                      child: AppSearchField(hint: AppStrings.placesSearchHint, onChanged: controller.setSearchQuery),
                    ),
                    Expanded(
                      child: places.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: AppStrings.journalNoResultsTitle,
                              message: AppStrings.journalNoResultsMessage,
                              muted: true,
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxxl + AppSpacing.xl),
                              children: [
                                _PlacesSummary(places: state.places),
                                AppSpacing.gapLg,
                                ...groupByMonth<PlaceVisited>(
                                  items: places,
                                  dateOf: (p) => p.visitDate,
                                  header: (label) => SectionHeader(title: label, compact: true),
                                  item: (p) => Dismissible(
                                    key: ValueKey(p.id),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (_) => confirmJournalDelete(context),
                                    onDismissed: (_) => controller.deletePlace(p.id),
                                    background: const DeleteSwipeBackground(),
                                    child: _PlaceCard(place: p),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
      floatingActionButton: hasAny
          ? FloatingActionButton.extended(
              onPressed: () => _showAdd(context, ref),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text(AppStrings.placesAdd),
            )
          : null,
    );
  }
}

/// "12 places · 5 cities" banner.
class _PlacesSummary extends StatelessWidget {
  final List<PlaceVisited> places;

  const _PlacesSummary({required this.places});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimaryContainer;
    final cities = places
        .map((p) => p.city?.trim().toLowerCase())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .length;

    Widget stat(int count, String singular, String plural) => Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$count ',
                style: theme.textTheme.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
              ),
              TextSpan(text: count == 1 ? singular : plural, style: theme.textTheme.bodyMedium?.copyWith(color: ink)),
            ],
          ),
        );

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXl),
      child: Row(
        children: [
          Icon(Icons.public_rounded, color: ink, size: AppSpacing.xl),
          AppSpacing.hGapMd,
          Expanded(child: stat(places.length, AppStrings.placeCountSuffix, AppStrings.placesCountSuffix)),
          stat(cities, AppStrings.cityCountSuffix, AppStrings.citiesCountSuffix),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final PlaceVisited place;

  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = place.city?.trim();
    final description = place.description?.trim();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.place_rounded, color: AppColors.chartTeal),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.placeName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      [
                        if (city != null && city.isNotEmpty) city,
                        AppFormatters.dayMonthYear(place.visitDate),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (place.rating != null) StarRatingDisplay(rating: place.rating!.toDouble()),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            AppSpacing.gapMd,
            Text(description, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _AddPlaceSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddPlaceSheet({required this.ref});

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _descController = TextEditingController();
  int _rating = 4;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _descController.dispose();
    super.dispose();
  }

  static String? _orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.ref.read(placeControllerProvider.notifier).addPlace(PlaceVisited(
          id: '',
          userId: '',
          placeName: name,
          city: _orNull(_cityController),
          visitDate: _date,
          description: _orNull(_descController),
          rating: _rating,
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareSheet(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const JournalSheetHeader(title: AppStrings.placeNewTitle),
          AppSpacing.gapMd,
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: AppStrings.placeNameLabel, prefixIcon: Icon(Icons.place_outlined)),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _cityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: AppStrings.placeCityLabel, prefixIcon: Icon(Icons.location_city_outlined)),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: AppStrings.placeDetailsLabel),
            maxLines: 3,
            minLines: 2,
          ),
          AppSpacing.gapLg,
          StarRatingInput(
            label: AppStrings.journalRating,
            value: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          AppSpacing.gapSm,
          JournalDateField(value: _date, onChanged: (d) => setState(() => _date = d)),
          AppSpacing.gapLg,
          FilledButton(onPressed: _save, child: const Text(AppStrings.placeSave)),
        ],
      ),
    );
  }
}
