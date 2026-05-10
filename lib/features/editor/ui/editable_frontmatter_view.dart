import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/editor_buffers_controller.dart';
import '../domain/frontmatter.dart';
import '../domain/frontmatter_format.dart';

/// Editable frontmatter section. Known Hugo fields get typed inputs (title,
/// description, slug as text; date as text+date picker; draft as switch;
/// tags/categories as chip lists). Unknown fields render as editable
/// key/value rows with add/remove. All edits are routed through
/// [editorBuffersProvider].
class EditableFrontmatterView extends ConsumerWidget {
  const EditableFrontmatterView({
    super.key,
    required this.absolutePath,
  });

  final String absolutePath;

  static const Set<String> _stringFields = {
    'title',
    'description',
    'slug',
  };
  static const Set<String> _chipFields = {'tags', 'categories'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final buffer = ref.watch(
      editorBuffersProvider.select((m) => m[absolutePath]),
    );
    if (buffer == null) return const SizedBox.shrink();

    if (buffer.format == FrontmatterFormat.none) {
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
          Text(
            l10n.frontmatterFormatLabel(buffer.format.name.toUpperCase()),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < buffer.currentEntries.length; i++) ...[
            _Row(
              absolutePath: absolutePath,
              index: i,
              entry: buffer.currentEntries[i],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          _AddFieldButton(absolutePath: absolutePath),
        ],
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({
    required this.absolutePath,
    required this.index,
    required this.entry,
  });

  final String absolutePath;
  final int index;
  final FrontmatterEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isKnown = EditableFrontmatterView._stringFields.contains(entry.key) ||
        EditableFrontmatterView._chipFields.contains(entry.key) ||
        entry.key == 'date' ||
        entry.key == 'draft';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: isKnown
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    entry.key,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : _KeyEditor(
                  absolutePath: absolutePath,
                  index: index,
                  initialKey: entry.key,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ValueEditor(
            absolutePath: absolutePath,
            entry: entry,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          tooltip: 'Remove field',
          visualDensity: VisualDensity.compact,
          onPressed: () => ref
              .read(editorBuffersProvider.notifier)
              .removeEntry(absolutePath, index),
        ),
      ],
    );
  }
}

class _KeyEditor extends ConsumerStatefulWidget {
  const _KeyEditor({
    required this.absolutePath,
    required this.index,
    required this.initialKey,
  });

  final String absolutePath;
  final int index;
  final String initialKey;

  @override
  ConsumerState<_KeyEditor> createState() => _KeyEditorState();
}

class _KeyEditorState extends ConsumerState<_KeyEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKey);
  }

  @override
  void didUpdateWidget(_KeyEditor old) {
    super.didUpdateWidget(old);
    if (old.initialKey != widget.initialKey &&
        widget.initialKey != _controller.text) {
      _controller.text = widget.initialKey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => ref
          .read(editorBuffersProvider.notifier)
          .renameEntry(widget.absolutePath, widget.index, value),
    );
  }
}

class _ValueEditor extends ConsumerWidget {
  const _ValueEditor({required this.absolutePath, required this.entry});

  final String absolutePath;
  final FrontmatterEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = entry.value;
    if (entry.key == 'draft' && value is bool?) {
      return _BoolField(
        absolutePath: absolutePath,
        keyName: entry.key,
        value: value ?? false,
      );
    }
    if (entry.key == 'date') {
      return _DateField(absolutePath: absolutePath, value: value);
    }
    if (EditableFrontmatterView._chipFields.contains(entry.key)) {
      final list =
          value is List ? value.cast<dynamic>() : const <dynamic>[];
      return _ChipListField(
        absolutePath: absolutePath,
        keyName: entry.key,
        values: list,
      );
    }
    if (EditableFrontmatterView._stringFields.contains(entry.key)) {
      return _StringField(
        absolutePath: absolutePath,
        keyName: entry.key,
        initial: value?.toString() ?? '',
      );
    }
    if (value is bool) {
      return _BoolField(
        absolutePath: absolutePath,
        keyName: entry.key,
        value: value,
      );
    }
    if (value is List) {
      return _ChipListField(
        absolutePath: absolutePath,
        keyName: entry.key,
        values: value.cast<dynamic>(),
      );
    }
    if (value is Map) {
      return _RawJsonStub(value: value);
    }
    return _StringField(
      absolutePath: absolutePath,
      keyName: entry.key,
      initial: value?.toString() ?? '',
    );
  }
}

class _StringField extends ConsumerStatefulWidget {
  const _StringField({
    required this.absolutePath,
    required this.keyName,
    required this.initial,
  });

  final String absolutePath;
  final String keyName;
  final String initial;

  @override
  ConsumerState<_StringField> createState() => _StringFieldState();
}

class _StringFieldState extends ConsumerState<_StringField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(_StringField old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial &&
        widget.initial != _controller.text) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => ref
          .read(editorBuffersProvider.notifier)
          .updateEntryValue(widget.absolutePath, widget.keyName, value),
    );
  }
}

class _BoolField extends ConsumerWidget {
  const _BoolField({
    required this.absolutePath,
    required this.keyName,
    required this.value,
  });

  final String absolutePath;
  final String keyName;
  final bool value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: (next) => ref
              .read(editorBuffersProvider.notifier)
              .updateEntryValue(absolutePath, keyName, next),
        ),
        const SizedBox(width: 8),
        Text(value ? 'true' : 'false'),
      ],
    );
  }
}

class _DateField extends ConsumerStatefulWidget {
  const _DateField({required this.absolutePath, required this.value});

  final String absolutePath;
  final Object? value;

  @override
  ConsumerState<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends ConsumerState<_DateField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatInitial(widget.value));
  }

  @override
  void didUpdateWidget(_DateField old) {
    super.didUpdateWidget(old);
    final next = _formatInitial(widget.value);
    if (next != _controller.text) _controller.text = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatInitial(Object? value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value?.toString() ?? '';
  }

  Future<void> _pickDate() async {
    final initial = _coerceDate() ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final iso = DateTime.utc(picked.year, picked.month, picked.day)
        .toIso8601String();
    _controller.text = iso;
    ref
        .read(editorBuffersProvider.notifier)
        .updateEntryValue(widget.absolutePath, 'date', iso);
  }

  DateTime? _coerceDate() {
    final v = widget.value;
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } on FormatException catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ref
                .read(editorBuffersProvider.notifier)
                .updateEntryValue(widget.absolutePath, 'date', value),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today, size: 18),
          tooltip: 'Pick date',
          onPressed: _pickDate,
        ),
        if (_coerceDate() != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              DateFormat.yMMMd()
                  .format(_coerceDate()!.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }
}

class _ChipListField extends ConsumerStatefulWidget {
  const _ChipListField({
    required this.absolutePath,
    required this.keyName,
    required this.values,
  });

  final String absolutePath;
  final String keyName;
  final List<dynamic> values;

  @override
  ConsumerState<_ChipListField> createState() => _ChipListFieldState();
}

class _ChipListFieldState extends ConsumerState<_ChipListField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addChip() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final next = [...widget.values.map((v) => v.toString()), text];
    ref
        .read(editorBuffersProvider.notifier)
        .updateEntryValue(widget.absolutePath, widget.keyName, next);
    _controller.clear();
  }

  void _removeChip(int index) {
    final next = widget.values.map((v) => v.toString()).toList()
      ..removeAt(index);
    ref
        .read(editorBuffersProvider.notifier)
        .updateEntryValue(widget.absolutePath, widget.keyName, next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < widget.values.length; i++)
          InputChip(
            label: Text(widget.values[i].toString()),
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.colorScheme.secondaryContainer,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
            deleteIconColor: theme.colorScheme.onSecondaryContainer,
            onDeleted: () => _removeChip(i),
          ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Add…',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addChip(),
          ),
        ),
      ],
    );
  }
}

class _RawJsonStub extends StatelessWidget {
  const _RawJsonStub({required this.value});

  final Map<dynamic, dynamic> value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        value.toString(),
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AddFieldButton extends ConsumerWidget {
  const _AddFieldButton({required this.absolutePath});

  final String absolutePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => ref
          .read(editorBuffersProvider.notifier)
          .addEntry(absolutePath, value: ''),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Add field'),
    );
  }
}
