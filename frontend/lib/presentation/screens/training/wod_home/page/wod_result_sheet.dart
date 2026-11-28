import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/models/training/wod.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/wod_labels.dart';

/// Hoja «¿Cómo te fue?» de un WOD (ADR 0069): pide lo que toca según el
/// formato (tiempo, rondas y repeticiones o repeticiones) y Rx o Adaptado.
/// Con cronómetro, [elapsedSeconds] ya rellena el tiempo; [timeUp] marca «No
/// terminé a tiempo». Devuelve la marca o nulo si se cerró sin guardar.
Future<WodResultDraft?> showWodResultSheet(
  BuildContext context, {
  required Wod wod,
  required WodDivision division,
  int? elapsedSeconds,
  bool timeUp = false,
}) => showModalBottomSheet<WodResultDraft>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _WodResultSheet(
    wod: wod,
    division: division,
    elapsedSeconds: elapsedSeconds,
    timeUp: timeUp,
  ),
);

class _WodResultSheet extends StatefulWidget {
  const _WodResultSheet({
    required this.wod,
    required this.division,
    required this.elapsedSeconds,
    required this.timeUp,
  });

  final Wod wod;
  final WodDivision division;
  final int? elapsedSeconds;
  final bool timeUp;

  @override
  State<_WodResultSheet> createState() => _WodResultSheetState();
}

class _WodResultSheetState extends State<_WodResultSheet> {
  late WodDivision _division = widget.division;
  late bool _capped = widget.timeUp && widget.wod.format == WodFormat.forTime;
  late final _minutes = TextEditingController(
    text: widget.elapsedSeconds == null
        ? ''
        : '${widget.elapsedSeconds! ~/ 60}',
  );
  late final _seconds = TextEditingController(
    text: widget.elapsedSeconds == null ? '' : '${widget.elapsedSeconds! % 60}',
  );
  final _rounds = TextEditingController();
  final _reps = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    _rounds.dispose();
    _reps.dispose();
    super.dispose();
  }

  WodScoreType get _type => widget.wod.format.scoreType(capped: _capped);

  static int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  /// La marca escrita, o nulo si falta lo imprescindible.
  WodResultDraft? _draft() {
    final (int? value, int? extra) = switch (_type) {
      WodScoreType.time => (
        _minutes.text.trim().isEmpty && _seconds.text.trim().isEmpty
            ? null
            : (_int(_minutes) ?? 0) * 60 + (_int(_seconds) ?? 0),
        null,
      ),
      WodScoreType.roundsReps => (_int(_rounds), _int(_reps) ?? 0),
      WodScoreType.reps || WodScoreType.load => (_int(_reps), null),
    };
    if (value == null || (_type == WodScoreType.time && value < 1)) return null;
    return WodResultDraft(
      division: _division,
      value: value,
      extraReps: extra,
      capped: _capped,
      durationSeconds: widget.elapsedSeconds?.clamp(1, 18000),
    );
  }

  void _save() {
    final draft = _draft();
    if (draft == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(draft);
  }

  Widget _number(String label, TextEditingController controller) =>
      AppTextField(
        label: label,
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(5),
        ],
        onChanged: (_) {
          if (_invalid) setState(() => _invalid = false);
        },
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final wod = widget.wod;
    const gap = SizedBox(height: TokensSpacing.m);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: TokensSpacing.l,
          right: TokensSpacing.l,
          bottom: MediaQuery.viewInsetsOf(context).bottom + TokensSpacing.m,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.wodResultTitle,
                  style: context.textStyles.titleLarge,
                ),
              ),
              const SizedBox(height: TokensSpacing.xs),
              Text(
                '${WodLabels.title(l10n, wod)} · ${WodLabels.headline(l10n, wod)}',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              gap,
              if (wod.format == WodFormat.forTime &&
                  wod.timeCapSeconds != null) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _capped,
                  onChanged: (v) => setState(() {
                    _capped = v ?? false;
                    _invalid = false;
                  }),
                  title: Text(l10n.wodResultCapped),
                  subtitle: _capped ? Text(l10n.wodResultCappedHelp) : null,
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
              ...switch (_type) {
                WodScoreType.time => [
                  _number(l10n.wodResultMinutes, _minutes),
                  gap,
                  _number(l10n.wodResultSeconds, _seconds),
                ],
                WodScoreType.roundsReps => [
                  _number(l10n.wodResultRounds, _rounds),
                  gap,
                  _number(l10n.wodResultExtraReps, _reps),
                ],
                WodScoreType.reps ||
                WodScoreType.load => [_number(l10n.wodResultReps, _reps)],
              },
              gap,
              AppSegmentedChoice<WodDivision>(
                label: l10n.wodDivisionLabel,
                values: WodDivision.values,
                selected: _division,
                labelOf: (d) => WodLabels.division(l10n, d),
                spokenLabelOf: (d) => d == WodDivision.rx
                    ? l10n.wodDivisionRxSpoken
                    : l10n.wodDivisionScaled,
                onChanged: (d) => setState(() => _division = d ?? _division),
              ),
              if (_invalid) ...[
                const SizedBox(height: TokensSpacing.s),
                AppInlineMessage(message: l10n.wodResultInvalid),
              ],
              gap,
              AppPrimaryButton(
                label: l10n.wodResultSave,
                icon: AppIcons.check,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
