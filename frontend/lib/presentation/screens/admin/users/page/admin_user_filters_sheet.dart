import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/enums/admin/admin_user_status.dart';
import '../../../../../domain/enums/user_role.dart';
import '../../../../../domain/models/admin/admin_queries.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/admin_labels.dart';

/// Hoja inferior con los filtros del buscador de usuarios. Devuelve la nueva
/// consulta o `null` si se cierra sin aplicar.
Future<AdminUserQuery?> showAdminUserFiltersSheet(
  BuildContext context,
  AdminUserQuery query,
) => showModalBottomSheet<AdminUserQuery>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FiltersSheet(initial: query),
);

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});

  final AdminUserQuery initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late AdminUserQuery _query = widget.initial;
  late final _minLevel = TextEditingController(
    text: widget.initial.minLevel?.toString() ?? '',
  );
  late final _maxLevel = TextEditingController(
    text: widget.initial.maxLevel?.toString() ?? '',
  );

  @override
  void dispose() {
    _minLevel.dispose();
    _maxLevel.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(
      _query.copyWith(
        minLevel: int.tryParse(_minLevel.text),
        maxLevel: int.tryParse(_maxLevel.text),
      ),
    );
  }

  void _clear() {
    Navigator.of(context).pop(
      AdminUserQuery(
        text: _query.text,
        sort: _query.sort,
        direction: _query.direction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          TokensSpacing.l,
          0,
          TokensSpacing.l,
          TokensSpacing.l + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adminFiltersTitle, style: context.textStyles.titleLarge),
            const SizedBox(height: TokensSpacing.m),
            _Label(l10n.adminFiltersRole),
            SegmentedButton<UserRole?>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: null, label: Text(l10n.adminFilterAny)),
                for (final role in UserRole.values)
                  ButtonSegment(
                    value: role,
                    label: Text(role.adminLabel(l10n)),
                  ),
              ],
              selected: {_query.role},
              onSelectionChanged: (s) =>
                  setState(() => _query = _query.copyWith(role: s.first)),
            ),
            const SizedBox(height: TokensSpacing.m),
            _Label(l10n.adminFiltersShadowban),
            SegmentedButton<bool?>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: null, label: Text(l10n.adminFilterAny)),
                ButtonSegment(value: true, label: Text(l10n.adminFilterYes)),
                ButtonSegment(value: false, label: Text(l10n.adminFilterNo)),
              ],
              selected: {_query.shadowbanned},
              onSelectionChanged: (s) => setState(
                () => _query = _query.copyWith(shadowbanned: s.first),
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            _Label(l10n.adminFiltersStatus),
            SegmentedButton<AdminUserStatus>(
              showSelectedIcon: false,
              segments: [
                for (final status in AdminUserStatus.values)
                  ButtonSegment(value: status, label: Text(status.label(l10n))),
              ],
              selected: {_query.status},
              onSelectionChanged: (s) =>
                  setState(() => _query = _query.copyWith(status: s.first)),
            ),
            const SizedBox(height: TokensSpacing.m),
            _Label(l10n.adminFiltersLevel),
            Row(
              children: [
                Expanded(
                  child: _LevelField(
                    controller: _minLevel,
                    label: l10n.adminFiltersMinLevel,
                  ),
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: _LevelField(
                    controller: _maxLevel,
                    label: l10n.adminFiltersMaxLevel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.l),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: l10n.adminFiltersClear,
                    onPressed: _clear,
                  ),
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: AppPrimaryButton(
                    label: l10n.adminFiltersApply,
                    onPressed: _apply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
    child: Text(text, style: context.textStyles.labelLarge),
  );
}

class _LevelField extends StatelessWidget {
  const _LevelField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, isDense: true),
  );
}
