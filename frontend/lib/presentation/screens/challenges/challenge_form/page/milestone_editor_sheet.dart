import 'package:flutter/material.dart';

import '../../../../../domain/enums/challenge_difficulty.dart';
import '../../../../../domain/enums/milestone_condition.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_draft_validator.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../attachment_picker/page/attachment_picker_sheet.dart';
import '../../link_picker/page/link_picker_sheet.dart';
import '../../widgets/challenge_labels.dart';
import '../../widgets/challenge_selectors.dart';
import '../bloc/challenge_form_bloc.dart';

/// Claves de las tareas que dependen (directa o indirectamente) de [key]:
/// elegirlas como dependencia de [key] crearía un ciclo.
Set<String> dependentsOf(String key, List<MilestoneFormItem> items) {
  final result = <String>{};
  var changed = true;
  while (changed) {
    changed = false;
    for (final m in items) {
      if (result.contains(m.key) || m.key == key) continue;
      if (m.dependsOnKeys.any((k) => k == key || result.contains(k))) {
        result.add(m.key);
        changed = true;
      }
    }
  }
  return result;
}

/// Hoja para crear o editar una tarea del reto. Devuelve la tarea editada.
Future<MilestoneFormItem?> showMilestoneEditorSheet(
  BuildContext context, {
  required MilestoneFormItem initial,
  required List<MilestoneFormItem> allItems,
  required bool showDependencies,
  required bool isNew,
  String? subjectId,
  DateTime? periodFrom,
  DateTime? periodTo,
}) {
  return showModalBottomSheet<MilestoneFormItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _MilestoneEditor(
      initial: initial,
      allItems: allItems,
      showDependencies: showDependencies,
      isNew: isNew,
      subjectId: subjectId,
      periodFrom: periodFrom,
      periodTo: periodTo,
    ),
  );
}

class _MilestoneEditor extends StatefulWidget {
  const _MilestoneEditor({
    required this.initial,
    required this.allItems,
    required this.showDependencies,
    required this.isNew,
    this.subjectId,
    this.periodFrom,
    this.periodTo,
  });

  final MilestoneFormItem initial;
  final List<MilestoneFormItem> allItems;

  /// Editor completo de dependencias: solo si el reto ya las tenía a medida
  /// (lo simple es «Hacer las tareas en orden», en el formulario).
  final bool showDependencies;
  final bool isNew;
  final String? subjectId;

  /// Periodo del reto: solo se ofrecen entregas que vencen dentro.
  final DateTime? periodFrom;
  final DateTime? periodTo;

  @override
  State<_MilestoneEditor> createState() => _MilestoneEditorState();
}

class _MilestoneEditorState extends State<_MilestoneEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late MilestoneFormItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.initial;
    _title = TextEditingController(text: _item.title);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  List<MilestoneFormItem> get _others =>
      widget.allItems.where((m) => m.key != _item.key).toList();

  void _toggleDependency(String key, bool selected) {
    final deps = [..._item.dependsOnKeys];
    selected ? deps.add(key) : deps.remove(key);
    setState(() {
      _item = _item.copyWith(
        dependsOnKeys: deps,
        condition: deps.length < 2 ? MilestoneCondition.all : _item.condition,
        conditionN: deps.isEmpty ? 1 : _item.conditionN.clamp(1, deps.length),
      );
    });
  }

  Future<void> _attach() async {
    final selection = await showAttachmentPickerSheet(
      context,
      subjectId: widget.subjectId,
    );
    if (selection == null) return;
    setState(() {
      _item = _item.copyWith(
        noteId: selection.noteId,
        noteTitle: selection.noteId == null ? null : selection.label,
        fileId: selection.fileId,
        fileName: selection.fileId == null ? null : selection.label,
      );
    });
  }

  Future<void> _link() async {
    final option = await showLinkPickerSheet(
      context,
      subjectId: widget.subjectId,
      from: widget.periodFrom,
      to: widget.periodTo,
    );
    if (option == null || !mounted) return;
    setState(() {
      _item = _item.copyWith(
        link: ChallengeLink(type: option.type, entityId: option.id),
        linkLabel: challengeLinkOptionLabel(context, option),
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _item.copyWith(title: _title.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final blocked = dependentsOf(_item.key, widget.allItems);
    final deps = _item.dependsOnKeys.length;
    final attachmentLabel = _item.noteId != null
        ? (_item.noteTitle ?? l10n.challengesMilestoneNote)
        : _item.fileId != null
        ? (_item.fileName ?? l10n.challengesMilestoneFile)
        : null;
    final link = _item.link;
    return Padding(
      padding: EdgeInsets.only(
        left: TokensSpacing.l,
        right: TokensSpacing.l,
        bottom: MediaQuery.viewInsetsOf(context).bottom + TokensSpacing.l,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isNew ? l10n.challengesTaskNew : l10n.challengesTaskEdit,
                style: context.textStyles.titleLarge,
              ),
              if (_item.completed) ...[
                const SizedBox(height: TokensSpacing.s),
                Text(
                  l10n.challengesTaskCompletedHint,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.palette.success,
                  ),
                ),
              ],
              const SizedBox(height: TokensSpacing.l),
              AppTextField(
                label: l10n.challengesTaskTitle,
                controller: _title,
                icon: Icons.task_alt_rounded,
                validator: (v) {
                  final length = v?.trim().length ?? 0;
                  return length < ChallengeDraftValidator.milestoneTitleMin ||
                          length > ChallengeDraftValidator.titleMax
                      ? l10n.challengesIssueTaskTitle
                      : null;
                },
              ),
              const SizedBox(height: TokensSpacing.m),
              Text(
                l10n.challengesEffortLabel,
                style: context.textStyles.labelLarge,
              ),
              const SizedBox(height: TokensSpacing.s),
              EffortSelector(
                value: _item.difficulty,
                onChanged: (ChallengeDifficulty d) =>
                    setState(() => _item = _item.copyWith(difficulty: d)),
              ),
              const SizedBox(height: TokensSpacing.xs),
              // Una sola medida de importancia: el esfuerzo fija también su
              // peso en el progreso y la XP.
              Text(
                l10n.challengesTaskEffortHint,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              if (widget.showDependencies) ...[
                const SizedBox(height: TokensSpacing.l),
                Text(
                  l10n.challengesTaskDependencies,
                  style: context.textStyles.labelLarge,
                ),
                const SizedBox(height: TokensSpacing.s),
                if (_others.isEmpty)
                  Text(
                    l10n.challengesTaskNoOtherTasks,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: TokensSpacing.s,
                    runSpacing: TokensSpacing.xs,
                    children: [
                      for (final o in _others)
                        if (blocked.contains(o.key))
                          Tooltip(
                            message: l10n.challengesTaskCycleDisabled,
                            child: FilterChip(
                              label: Text(o.title),
                              selected: false,
                              onSelected: null,
                            ),
                          )
                        else
                          FilterChip(
                            label: Text(o.title),
                            selected: _item.dependsOnKeys.contains(o.key),
                            onSelected: (s) => _toggleDependency(o.key, s),
                          ),
                    ],
                  ),
                if (deps >= 2) ...[
                  const SizedBox(height: TokensSpacing.m),
                  Text(
                    l10n.challengesTaskCondition,
                    style: context.textStyles.labelLarge,
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<MilestoneCondition>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: MilestoneCondition.all,
                          label: Text(l10n.challengesConditionAll),
                        ),
                        ButtonSegment(
                          value: MilestoneCondition.any,
                          label: Text(l10n.challengesConditionAny),
                        ),
                        ButtonSegment(
                          value: MilestoneCondition.xOfY,
                          label: Text(l10n.challengesConditionXOfYOption),
                        ),
                      ],
                      selected: {_item.condition},
                      onSelectionChanged: (s) => setState(
                        () => _item = _item.copyWith(condition: s.first),
                      ),
                    ),
                  ),
                  if (_item.condition == MilestoneCondition.xOfY) ...[
                    const SizedBox(height: TokensSpacing.s),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.challengesTaskConditionN,
                            style: context.textStyles.bodyMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.commonDecrease(
                            l10n.challengesTaskConditionN,
                          ),
                          onPressed: _item.conditionN > 1
                              ? () => setState(
                                  () => _item = _item.copyWith(
                                    conditionN: _item.conditionN - 1,
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        Text(
                          l10n.challengesConditionXOfY(_item.conditionN, deps),
                          style: context.textStyles.titleMedium,
                        ),
                        IconButton(
                          tooltip: l10n.commonIncrease(
                            l10n.challengesTaskConditionN,
                          ),
                          onPressed: _item.conditionN < deps
                              ? () => setState(
                                  () => _item = _item.copyWith(
                                    conditionN: _item.conditionN + 1,
                                  ),
                                )
                              : null,
                          icon: const Icon(AppIcons.add),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
              const SizedBox(height: TokensSpacing.l),
              Text(
                l10n.challengesTaskAttachment,
                style: context.textStyles.labelLarge,
              ),
              const SizedBox(height: TokensSpacing.s),
              if (attachmentLabel == null)
                AppSecondaryButton(
                  label: l10n.challengesTaskAttach,
                  icon: const Icon(Icons.attach_file_rounded),
                  onPressed: _attach,
                )
              else
                InputChip(
                  avatar: Icon(
                    _item.noteId != null
                        ? Icons.description_outlined
                        : Icons.attach_file_rounded,
                  ),
                  label: Text(attachmentLabel),
                  onPressed: _attach,
                  deleteButtonTooltipMessage:
                      l10n.challengesTaskRemoveAttachment,
                  onDeleted: () => setState(
                    () => _item = _item.copyWith(
                      noteId: null,
                      noteTitle: null,
                      fileId: null,
                      fileName: null,
                    ),
                  ),
                ),
              const SizedBox(height: TokensSpacing.m),
              Text(
                l10n.challengesTaskLink,
                style: context.textStyles.labelLarge,
              ),
              const SizedBox(height: TokensSpacing.s),
              if (link == null)
                AppSecondaryButton(
                  label: l10n.challengesFormAddLink,
                  icon: const Icon(Icons.link_rounded),
                  onPressed: _link,
                )
              else
                InputChip(
                  avatar: Icon(link.type.icon),
                  label: Text(_item.linkLabel ?? link.type.label(context)),
                  onPressed: _link,
                  deleteButtonTooltipMessage: l10n.challengesFormRemoveLink,
                  onDeleted: () => setState(
                    () => _item = _item.copyWith(link: null, linkLabel: null),
                  ),
                ),
              const SizedBox(height: TokensSpacing.l),
              AppPrimaryButton(
                label: l10n.challengesTaskSave,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
