import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/tags.dart';
import 'package:chronicle/features/moods/domain/models/mood_entry.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_module.dart';

/// Turns a database row from [SearchModule.spec] into a [SearchResult].
abstract final class SearchResultMapper {
  static SearchResult map(SearchModule module, Map<String, dynamic> row) {
    String? s(String key) {
      final v = row[key];
      if (v == null) return null;
      final text = '$v'.trim();
      return text.isEmpty ? null : text;
    }

    DateTime? d(String key) => DateTime.tryParse(s(key) ?? '');

    /// First non-empty of [keys] joined by " · ".
    String? join(List<String?> parts) {
      final present = parts.whereType<String>().toList();
      return present.isEmpty ? null : present.join(' · ');
    }

    final date = d(module.spec.dateColumn);
    final tags = module.taggable ? TagUtils.fromJson(row['tags']) : const <String>[];
    final id = '${row['id']}';

    SearchResult result(String title, {String? subtitle, double? amount}) => SearchResult(
          module: module,
          id: id,
          title: title,
          subtitle: subtitle == title ? null : subtitle,
          date: date,
          tags: tags,
          amount: amount,
          row: row,
        );

    switch (module) {
      case SearchModule.todos:
        return result(s('title') ?? AppStrings.searchUntitled, subtitle: s('description'));
      case SearchModule.expenses:
        final category = (row['categories'] as Map<String, dynamic>?)?['name'] as String?;
        return result(
          s('description') ?? category ?? AppStrings.searchModuleExpenses,
          subtitle: category,
          amount: (row['amount'] as num?)?.toDouble(),
        );
      case SearchModule.thoughts:
        return result(s('content') ?? AppStrings.searchUntitled);
      case SearchModule.learnings:
        return result(s('title') ?? AppStrings.searchUntitled, subtitle: s('description') ?? s('source'));
      case SearchModule.books:
        return result(s('name') ?? AppStrings.searchUntitled, subtitle: s('author'));
      case SearchModule.movies:
        return result(s('name') ?? AppStrings.searchUntitled, subtitle: s('comments') ?? s('takeaways'));
      case SearchModule.lifeLessons:
        final title = s('title');
        return result(title ?? s('content') ?? AppStrings.searchUntitled, subtitle: title == null ? null : s('content'));
      case SearchModule.restaurants:
        return result(s('name') ?? AppStrings.searchUntitled, subtitle: join([s('address'), s('latest_food_items')]));
      case SearchModule.places:
        return result(s('place_name') ?? AppStrings.searchUntitled, subtitle: join([s('city'), s('description')]));
      case SearchModule.firstTimes:
        return result(s('title') ?? AppStrings.searchUntitled, subtitle: s('location') ?? s('description'));
      case SearchModule.visionBoard:
        return result(s('title') ?? AppStrings.searchUntitled, subtitle: s('description') ?? s('category'));
      case SearchModule.misc:
        final title = s('title');
        return result(
          title ?? s('content') ?? AppStrings.searchPhotoOnly,
          subtitle: title == null ? null : s('content'),
        );
      case SearchModule.moods:
        final mood = s('mood') ?? 'neutral';
        final label = '${mood[0].toUpperCase()}${mood.substring(1)}';
        return result('${MoodEntry.getEmoji(mood)} $label', subtitle: s('note'));
    }
  }
}
