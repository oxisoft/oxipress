import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/frontmatter.dart';
import '../domain/frontmatter_format.dart';

/// Read-only display of a parsed frontmatter block. Known Hugo fields
/// (title, date, draft, tags, categories, description, slug) get typed
/// renderers; everything else falls back to a generic key/value row.
class FrontmatterView extends StatelessWidget {
  const FrontmatterView({super.key, required this.frontmatter});

  final Frontmatter frontmatter;

  static const Set<String> _knownStringFields = {
    'title',
    'description',
    'slug',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (frontmatter.format == FrontmatterFormat.none ||
        frontmatter.entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: theme.colorScheme.surfaceContainerLow,
        child: Text(
          l10n.frontmatterEmpty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.frontmatterFormatLabel(
                  frontmatter.format.name.toUpperCase(),
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in frontmatter.entries) ...[
            _Row(entry: entry),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});

  final FrontmatterEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            entry.key,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ValueView(
            keyName: entry.key,
            value: entry.value,
          ),
        ),
      ],
    );
  }
}

class _ValueView extends StatelessWidget {
  const _ValueView({required this.keyName, required this.value});

  final String keyName;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (keyName == 'draft' && value is bool) {
      final v = value! as bool;
      return Row(
        children: [
          Icon(
            v ? Icons.check_box : Icons.check_box_outline_blank,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(v ? 'true' : 'false', style: theme.textTheme.bodySmall),
        ],
      );
    }

    if ((keyName == 'tags' || keyName == 'categories') && value is List) {
      return _Chips(values: value! as List);
    }

    if (keyName == 'date') {
      return _DateView(value: value);
    }

    if (FrontmatterView._knownStringFields.contains(keyName) &&
        value is String) {
      return SelectableText(
        value! as String,
        style: theme.textTheme.bodyMedium,
      );
    }

    if (value is List) {
      return _Chips(values: value! as List);
    }
    if (value is bool) {
      return Text(
        (value! as bool) ? 'true' : 'false',
        style: theme.textTheme.bodySmall,
      );
    }
    if (value is Map) {
      return SelectableText(
        _formatMap(value! as Map),
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (value == null) {
      return Text(
        '—',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return SelectableText(
      value.toString(),
      style: theme.textTheme.bodyMedium,
    );
  }

  String _formatMap(Map<dynamic, dynamic> map) {
    final buffer = StringBuffer();
    map.forEach((k, v) {
      buffer.writeln('$k: $v');
    });
    return buffer.toString().trimRight();
  }
}

class _DateView extends StatelessWidget {
  const _DateView({required this.value});

  final Object? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = _coerce(value);
    if (dt == null) {
      return SelectableText(
        value?.toString() ?? '—',
        style: theme.textTheme.bodyMedium,
      );
    }
    final formatted = DateFormat.yMMMd().add_Hm().format(dt.toLocal());
    return SelectableText(
      '$formatted  ($value)',
      style: theme.textTheme.bodyMedium,
    );
  }

  DateTime? _coerce(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } on FormatException catch (_) {
        return null;
      }
    }
    return null;
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.values});

  final List<dynamic> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (values.isEmpty) {
      return Text(
        '[]',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final v in values)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              v.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}
