import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_form_fields.dart';
import 'planner_visuals.dart';

/// Pide las fechas de inicio y fin de clases. Devuelve el par o `null`.
class SemesterDatesSheet extends StatefulWidget {
  const SemesterDatesSheet({super.key});

  static Future<({DateTime start, DateTime end})?> show(BuildContext context) =>
      showModalBottomSheet<({DateTime start, DateTime end})>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const SemesterDatesSheet(),
      );

  @override
  State<SemesterDatesSheet> createState() => _SemesterDatesSheetState();
}

class _SemesterDatesSheetState extends State<SemesterDatesSheet> {
  DateTime? _start;
  DateTime? _end;
  bool _invalid = false;

  void _submit() {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return;
    if (!end.isAfter(start)) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop((start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final now = DateTime.now();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        0,
        TokensSpacing.m,
        TokensSpacing.l,
      ),
      children: [
        Text(
          l10n.plannerSemesterDatesTitle,
          style: context.textStyles.titleLarge,
        ),
        const SizedBox(height: TokensSpacing.xs),
        Text(
          l10n.plannerSemesterDatesIntro,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        PickerField(
          label: l10n.plannerClassesStart,
          value: _start == null
              ? l10n.plannerPickDate
              : PlannerFormats.longDate(_start!),
          icon: Icons.event_rounded,
          onTap: () async {
            final picked = await pickPlannerDate(
              context,
              initial: _start ?? now,
              first: DateTime(now.year - 1),
            );
            if (picked != null) {
              setState(() {
                _start = picked;
                _invalid = false;
              });
            }
          },
        ),
        const SizedBox(height: TokensSpacing.s),
        PickerField(
          label: l10n.plannerClassesEnd,
          value: _end == null
              ? l10n.plannerPickDate
              : PlannerFormats.longDate(_end!),
          icon: Icons.event_available_rounded,
          onTap: () async {
            final picked = await pickPlannerDate(
              context,
              initial: _end ?? (_start ?? now).add(const Duration(days: 120)),
              first: DateTime(now.year - 1),
            );
            if (picked != null) {
              setState(() {
                _end = picked;
                _invalid = false;
              });
            }
          },
        ),
        if (_invalid) ...[
          const SizedBox(height: TokensSpacing.s),
          AppInlineMessage(message: l10n.plannerDatesInvalid),
        ],
        const SizedBox(height: TokensSpacing.l),
        AppPrimaryButton(
          label: l10n.plannerSaveAndScan,
          onPressed: _start == null || _end == null ? null : _submit,
        ),
      ],
    );
  }
}
