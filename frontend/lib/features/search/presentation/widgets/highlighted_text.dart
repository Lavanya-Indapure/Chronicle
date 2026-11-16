import 'package:flutter/material.dart';

/// [text] with the first case-insensitive occurrence of [query] emphasised.
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;

  const HighlightedText({super.key, required this.text, required this.query, this.style, this.maxLines = 1});

  /// Start index of [query] in [text] (case-insensitive), or -1.
  static int matchIndex(String text, String query) {
    final q = query.trim();
    if (q.isEmpty) return -1;
    return text.toLowerCase().indexOf(q.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final at = matchIndex(text, query);
    if (at < 0) return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);

    final colors = Theme.of(context).colorScheme;
    final end = at + query.trim().length;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: text.substring(at, end),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.onPrimaryContainer,
              backgroundColor: colors.primaryContainer,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
