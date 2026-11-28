import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/wod.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/training_section_bar.dart';
import '../../widgets/wod_labels.dart';
import '../bloc/wod_editor_bloc.dart';

/// Editor de mi WOD (`/training/wods/edit`, ADR 0069): título, formato,
/// límite, rondas, fuerza y movimientos. Sin [wod] se crea desde cero; con
/// una plantilla de ejemplo (sin id) se parte de ella; con un WOD mío se
/// cambia o se elimina. Las reglas de cada formato las valida el servidor.
class WodEditorPage extends StatelessWidget {
  const WodEditorPage({super.key, this.wod});

  final Wod? wod;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<WodEditorBloc>(),
    child: _WodEditorView(wod: wod),
  );
}

/// Un movimiento del formulario. [code] es el de la plantilla: se conserva
/// mientras no se le cambie el nombre, así sigue siendo «el mismo WOD» para
/// la mejor marca.
class _Row {
  _Row({
    this.code,
    String name = '',
    int? quantity,
    this.unit = WodUnit.reps,
    double? rxKg,
    double? scaledKg,
  }) : original = name,
       name = TextEditingController(text: name),
       quantity = TextEditingController(text: quantity?.toString() ?? ''),
       rxKg = TextEditingController(text: _kg(rxKg)),
       scaledKg = TextEditingController(text: _kg(scaledKg));

  final String? code;
  final String original;
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController rxKg;
  final TextEditingController scaledKg;
  WodUnit unit;

  static String _kg(double? value) => value == null
      ? ''
      : (value == value.roundToDouble() ? '${value.round()}' : '$value');

  static double? _parseKg(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  WodMovement? toMovement() {
    final text = name.text.trim();
    if (text.isEmpty) return null;
    final sameAsTemplate = code != null && text == original;
    return WodMovement(
      code: sameAsTemplate ? code : null,
      name: sameAsTemplate ? null : text,
      quantity: int.tryParse(quantity.text.trim()),
      unit: unit,
      rxKg: _parseKg(rxKg.text),
      scaledKg: _parseKg(scaledKg.text),
    );
  }

  void dispose() {
    name.dispose();
    quantity.dispose();
    rxKg.dispose();
    scaledKg.dispose();
  }
}

class _WodEditorView extends StatefulWidget {
  const _WodEditorView({required this.wod});

  final Wod? wod;

  @override
  State<_WodEditorView> createState() => _WodEditorViewState();
}

class _WodEditorViewState extends State<_WodEditorView>
    with ErrorsMessageMixin {
  static const _maxMovements = 12;
  static const _maxCapMinutes = 60;
  static const _maxRounds = 50;
  static const _defaultCapMinutes = 12;

  final _title = TextEditingController();
  final _strength = TextEditingController();
  final _rows = <_Row>[];
  late WodFormat _format = widget.wod?.format ?? WodFormat.forTime;
  late int _capMinutes = widget.wod == null
      ? _defaultCapMinutes
      : ((widget.wod!.timeCapSeconds ?? 0) / 60).ceil();
  late int _rounds = widget.wod?.rounds ?? 1;
  bool _needsMovement = false;
  bool _filled = false;

  String get _back => TrainingPaths.section(TrainingSection.wod);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    // Los nombres de una plantilla llegan como códigos: se escriben ya en el
    // idioma de la persona para que pueda cambiarlos.
    final l10n = context.localizations;
    final wod = widget.wod;
    if (wod == null) {
      _rows.add(_Row());
      return;
    }
    _title.text = WodLabels.title(l10n, wod);
    _strength.text = wod.strength ?? '';
    for (final m in wod.movements) {
      _rows.add(
        _Row(
          code: m.code,
          name: WodLabels.movementName(l10n, m),
          quantity: m.quantity,
          unit: m.unit,
          rxKg: m.rxKg,
          scaledKg: m.scaledKg,
        ),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _strength.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _save() {
    final movements = [for (final row in _rows) ?row.toMovement()];
    if (movements.isEmpty) {
      setState(() => _needsMovement = true);
      return;
    }
    final title = _title.text.trim();
    final strength = _strength.text.trim();
    final capMinutes = _format == WodFormat.forTime
        ? _capMinutes
        : _capMinutes.clamp(1, _maxCapMinutes);
    context.read<WodEditorBloc>().add(
      WodEditorEvent.saveRequested(
        Wod(
          id: widget.wod?.id,
          templateCode: widget.wod?.templateCode,
          title: title.isEmpty ? null : title,
          strength: strength.isEmpty ? null : strength,
          format: _format,
          timeCapSeconds: _format == WodFormat.tabata || capMinutes == 0
              ? null
              : capMinutes * 60,
          rounds: _format == WodFormat.forTime ? _rounds : null,
          movements: movements,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final l10n = context.localizations;
    final bloc = context.read<WodEditorBloc>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.wodEditorDeleteTitle,
      message: l10n.wodEditorDeleteMessage,
      confirmLabel: l10n.wodEditorDelete,
    );
    if (ok && !bloc.isClosed) {
      bloc.add(WodEditorEvent.deleteRequested(widget.wod!.id!));
    }
  }

  static final _digits = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(5),
  ];
  static final _decimals = [
    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
    LengthLimitingTextInputFormatter(6),
  ];

  Widget _movement(AppLocalizations l10n, int index) {
    final row = _rows[index];
    const gap = SizedBox(height: TokensSpacing.s);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.wodEditorMovementN(index + 1),
                  style: context.textStyles.titleSmall,
                ),
              ),
              if (_rows.length > 1)
                IconButton(
                  tooltip: l10n.wodEditorRemoveMovement(index + 1),
                  icon: const Icon(AppIcons.remove),
                  onPressed: () => setState(() {
                    _rows.removeAt(index).dispose();
                  }),
                ),
            ],
          ),
          AppTextField(
            label: l10n.wodEditorMovementName,
            controller: row.name,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_needsMovement) setState(() => _needsMovement = false);
            },
          ),
          gap,
          AppTextField(
            label: l10n.wodEditorQuantity,
            controller: row.quantity,
            keyboardType: TextInputType.number,
            inputFormatters: _digits,
            hint: l10n.wodMaxReps,
          ),
          gap,
          DropdownButtonFormField<WodUnit>(
            initialValue: row.unit,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.wodEditorUnit),
            items: [
              for (final unit in WodUnit.values)
                DropdownMenuItem(
                  value: unit,
                  child: Text(switch (unit) {
                    WodUnit.reps => l10n.wodUnitNameReps,
                    WodUnit.calories => l10n.wodUnitNameCalories,
                    WodUnit.meters => l10n.wodUnitNameMeters,
                  }),
                ),
            ],
            onChanged: (unit) => setState(() => row.unit = unit ?? row.unit),
          ),
          gap,
          AppTextField(
            label: l10n.wodEditorRxKg,
            controller: row.rxKg,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _decimals,
          ),
          gap,
          AppTextField(
            label: l10n.wodEditorScaledKg,
            controller: row.scaledKg,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _decimals,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final mine = widget.wod?.id != null;
    const gap = SizedBox(height: TokensSpacing.m);
    return BlocConsumer<WodEditorBloc, WodEditorState>(
      listenWhen: (p, c) =>
          (c.outcome != null && p.outcome != c.outcome) ||
          (c.error != null && p.error != c.error),
      listener: (context, state) {
        if (state.error case final error?) {
          context.showSnack(errorMessage(context, error));
          return;
        }
        context.showSnack(
          state.outcome == WodEditorOutcome.deleted
              ? l10n.wodDeleted
              : l10n.wodSavedWhere,
        );
        context.popOrGo(_back, true);
      },
      builder: (context, state) => Scaffold(
        appBar: AppPageBar.reading(
          leading: AppBackButton(fallback: _back),
          title: Text(mine ? l10n.wodEditorEditTitle : l10n.wodEditorNewTitle),
        ),
        body: AppContentWidth.reading(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              AppTextField(
                label: l10n.wodEditorName,
                controller: _title,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
              ),
              gap,
              AppSegmentedChoice<WodFormat>(
                label: l10n.wodEditorFormat,
                values: WodFormat.values,
                selected: _format,
                labelOf: (f) => WodLabels.format(l10n, f),
                onChanged: (f) => setState(() {
                  _format = f ?? _format;
                  // AMRAP y EMOM necesitan tiempo: «Sin límite» solo vale
                  // en «por tiempo».
                  if (_format != WodFormat.forTime && _capMinutes == 0) {
                    _capMinutes = _defaultCapMinutes;
                  }
                }),
              ),
              const SizedBox(height: TokensSpacing.xs),
              Text(
                WodLabels.formatHelp(l10n, _format),
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              gap,
              if (_format == WodFormat.tabata)
                AppInlineMessage(
                  message: l10n.wodEditorTabataNote,
                  tone: AppMessageTone.info,
                  live: false,
                )
              else
                AppStepperField(
                  label: _format == WodFormat.forTime
                      ? l10n.wodEditorTimeCap
                      : l10n.wodEditorDuration,
                  value: _capMinutes,
                  min: _format == WodFormat.forTime ? 0 : 1,
                  max: _maxCapMinutes,
                  display: (v) =>
                      v == 0 ? l10n.wodEditorNoCap : l10n.wodEditorMinutes(v),
                  onChanged: (v) => setState(() => _capMinutes = v),
                ),
              if (_format == WodFormat.forTime) ...[
                gap,
                AppStepperField(
                  label: l10n.wodEditorRounds,
                  value: _rounds,
                  min: 1,
                  max: _maxRounds,
                  onChanged: (v) => setState(() => _rounds = v),
                ),
              ],
              gap,
              AppTextField(
                label: l10n.wodEditorStrength,
                controller: _strength,
                hint: l10n.wodEditorStrengthHint,
                maxLength: 300,
                maxLines: 3,
                minLines: 1,
              ),
              gap,
              AppSectionHeader(title: l10n.wodEditorMovements),
              const SizedBox(height: TokensSpacing.s),
              for (var i = 0; i < _rows.length; i++) ...[
                _movement(l10n, i),
                const SizedBox(height: TokensSpacing.s),
              ],
              if (_rows.length < _maxMovements)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _rows.add(_Row())),
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.wodEditorAddMovement),
                  ),
                ),
              if (_needsMovement) ...[
                const SizedBox(height: TokensSpacing.s),
                AppInlineMessage(message: l10n.wodEditorNeedsMovement),
              ],
              const SizedBox(height: TokensSpacing.l),
              AppPrimaryButton(
                label: l10n.wodEditorSave,
                icon: AppIcons.check,
                loading: state.saving,
                onPressed: state.busy ? null : _save,
              ),
              if (mine) ...[
                const SizedBox(height: TokensSpacing.l),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppDangerButton(
                    label: l10n.wodEditorDelete,
                    onPressed: state.busy ? null : _delete,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
