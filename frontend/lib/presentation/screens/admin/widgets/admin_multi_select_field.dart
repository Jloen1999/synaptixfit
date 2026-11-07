import 'package:flutter/material.dart';

import '../../../../domain/models/admin/admin_exercise.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Campo de selección múltiple sobre un catálogo (músculos, partes del cuerpo,
/// equipamiento): muestra los elegidos como chips y abre un buscador.
class AdminMultiSelectField extends StatelessWidget {
  const AdminMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<AdminCatalogItem> options;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  Future<void> _open(BuildContext context) async {
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (_) =>
          _SelectDialog(title: label, options: options, initial: selected),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final chosen = options.where((o) => selected.contains(o.id)).toList();
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: l10n.adminSelectEdit(label),
          onPressed: () => _open(context),
          icon: const Icon(Icons.playlist_add_rounded),
        ),
      ),
      child: chosen.isEmpty
          ? Text(
              l10n.adminSelectNone,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          : Wrap(
              spacing: TokensSpacing.xs,
              runSpacing: TokensSpacing.xs,
              children: [
                for (final item in chosen)
                  InputChip(
                    label: Text(item.name),
                    onDeleted: () => onChanged({...selected}..remove(item.id)),
                    deleteButtonTooltipMessage: l10n.adminSelectRemove(
                      item.name,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SelectDialog extends StatefulWidget {
  const _SelectDialog({
    required this.title,
    required this.options,
    required this.initial,
  });

  final String title;
  final List<AdminCatalogItem> options;
  final Set<int> initial;

  @override
  State<_SelectDialog> createState() => _SelectDialogState();
}

class _SelectDialogState extends State<_SelectDialog> {
  late final Set<int> _selected = {...widget.initial};
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final filter = _filter.trim().toLowerCase();
    final visible = widget.options
        .where((o) => filter.isEmpty || o.name.toLowerCase().contains(filter))
        .toList();
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.m,
        TokensSpacing.m,
        0,
      ),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _filter = v),
              decoration: InputDecoration(
                labelText: l10n.adminSelectSearch,
                prefixIcon: const Icon(AppIcons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: TokensSpacing.s),
            Expanded(
              child: visible.isEmpty
                  ? Center(child: Text(l10n.adminSelectNoResults))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, index) {
                        final item = visible[index];
                        return AppFocusOutline(
                          child: CheckboxListTile(
                            dense: true,
                            value: _selected.contains(item.id),
                            title: Text(item.name),
                            onChanged: (checked) => setState(
                              () => checked == true
                                  ? _selected.add(item.id)
                                  : _selected.remove(item.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(_selected.clear),
          child: Text(l10n.adminSelectClear),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.adminSelectDone(_selected.length)),
        ),
      ],
    );
  }
}
