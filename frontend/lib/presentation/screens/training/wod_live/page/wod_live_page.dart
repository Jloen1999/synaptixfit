import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../../domain/models/training/wod.dart';
import '../../../../../domain/models/training/wod_timer.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/sport_labels.dart';
import '../../widgets/training_section_bar.dart';
import '../../widgets/wod_labels.dart';
import '../../wod_home/page/wod_result_sheet.dart';
import '../bloc/wod_live_bloc.dart';

/// Lo que necesita el WOD en marcha: la pizarra (con su título ya en el idioma
/// de la persona) y cómo se va a hacer.
typedef WodLiveArgs = ({Wod wod, WodDivision division});

/// WOD en marcha (`/training/wods/live`, ADR 0069), a pantalla completa y con
/// estilo de póster: foto oscurecida, el formato con cifras enormes, los
/// movimientos y el cronómetro, con «Pausa» y «Terminar» siempre a mano. Va
/// siempre con el tema oscuro: el velo sobre la foto es la superficie oscura
/// al 85 %, así el texto claro cumple contraste con cualquier foto. Abierta
/// sin WOD (en frío) lleva de vuelta al apartado.
class WodLivePage extends StatelessWidget {
  const WodLivePage({super.key, this.args});

  final WodLiveArgs? args;

  static String get _back => TrainingPaths.section(TrainingSection.wod);

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.dark,
    child: switch (args) {
      null => const _Missing(),
      final args => BlocProvider(
        create: (_) =>
            getIt<WodLiveBloc>()
              ..add(WodLiveEvent.started(args.wod, args.division)),
        child: const _WodLiveView(),
      ),
    },
  );
}

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar(
        leading: AppBackButton(fallback: WodLivePage._back),
        title: Text(l10n.wodLiveTitle),
      ),
      body: AppEmptyState(
        icon: AppIcons.focusTimer,
        title: l10n.wodLiveMissingTitle,
        message: l10n.wodLiveMissingMessage,
        action: FilledButton(
          onPressed: () => context.go(WodLivePage._back),
          child: Text(l10n.wodLiveGoToWod),
        ),
      ),
    );
  }
}

class _WodLiveView extends StatefulWidget {
  const _WodLiveView();

  @override
  State<_WodLiveView> createState() => _WodLiveViewState();
}

class _WodLiveViewState extends State<_WodLiveView> with ErrorsMessageMixin {
  /// Ya se confirmó salir: se deja pasar el «atrás».
  bool _leaving = false;

  /// El estado anterior al que llega al oyente, para saber qué ha cambiado.
  WodLiveState _previous = const WodLiveState();

  Future<void> _askResult(WodLiveState state) async {
    final bloc = context.read<WodLiveBloc>();
    final wod = state.wod!;
    final draft = await showWodResultSheet(
      context,
      wod: wod,
      division: state.division,
      elapsedSeconds: state.elapsedSeconds,
      timeUp: state.timeUp,
    );
    if (bloc.isClosed) return;
    bloc.add(
      draft == null
          ? const WodLiveEvent.resumed()
          : WodLiveEvent.resultSubmitted(wod, draft),
    );
  }

  Future<void> _confirmExit() async {
    final l10n = context.localizations;
    final leave = await showConfirmDialog(
      context,
      title: l10n.wodLiveExitTitle,
      message: l10n.wodLiveExitMessage,
      confirmLabel: l10n.wodLiveExitConfirm,
      cancelLabel: l10n.wodLiveExitStay,
    );
    if (!leave || !mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.popOrGo(WodLivePage._back);
    });
  }

  /// Lo único que oye el lector del reloj: el cambio de fase o de ronda.
  String? _announcement(AppLocalizations l10n, WodFormat format, WodTick tick) {
    if (tick.done) return l10n.wodLiveAnnounceDone;
    return switch (format) {
      WodFormat.tabata =>
        tick.phase == WodPhase.rest
            ? l10n.wodLiveAnnounceRest
            : l10n.wodLiveAnnounceWork(tick.round),
      WodFormat.emom => l10n.wodLiveAnnounceMinute(tick.round),
      WodFormat.forTime || WodFormat.amrap => null,
    };
  }

  void _listen(
    BuildContext context,
    WodLiveState previous,
    WodLiveState state,
  ) {
    final l10n = context.localizations;
    if (state.error case final error? when previous.error != error) {
      context.showSnack(errorMessage(context, error));
    }
    if (state.saved case final mark? when previous.saved == null) {
      context.showSnack(mark.best ? l10n.wodMarkSavedBest : l10n.wodMarkSaved);
      context.popOrGo(WodLivePage._back, true);
      return;
    }
    final tick = state.tick;
    if (tick != null &&
        previous.tick != null &&
        previous.tick!.announceKey != tick.announceKey) {
      final text = _announcement(l10n, state.wod!.format, tick);
      if (text != null) {
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            text,
            Directionality.of(context),
          ),
        );
      }
    }
    if (state.status == WodLiveStatus.finished &&
        previous.status != WodLiveStatus.finished) {
      unawaited(_askResult(state));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WodLiveBloc, WodLiveState>(
      listenWhen: (previous, _) {
        _previous = previous;
        return true;
      },
      listener: (context, state) => _listen(context, _previous, state),
      builder: (context, state) {
        return PopScope(
          canPop: _leaving || !state.inProgress,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_confirmExit());
          },
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: Image(
                      image: SportLabels.photo(Sport.wod),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: context.colors.surface.withValues(
                      alpha: TokensOpacity.coverScrimMax,
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox(
                          height: TokensSize.toolbarHeight,
                          width: TokensSize.toolbarHeight,
                          child: AppBackButton(fallback: WodLivePage._back),
                        ),
                      ),
                      Expanded(child: _Poster(state: state)),
                      _Controls(
                        state: state,
                        onSaveMark: () => _askResult(state),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// El póster: titular del formato, estado del reloj, la cifra grande y los
/// movimientos.
class _Poster extends StatelessWidget {
  const _Poster({required this.state});

  final WodLiveState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final styles = context.textStyles;
    final colors = context.colors;
    final wod = state.wod!;
    final tick = state.tick!;
    final timer = WodTimer.of(wod);
    final time = WodLabels.clock(tick.clockSeconds);
    final phase = switch (state.status) {
      WodLiveStatus.paused => l10n.wodLivePaused,
      _ when tick.done => l10n.wodLiveTimeUp,
      _ when wod.format == WodFormat.tabata =>
        tick.phase == WodPhase.rest ? l10n.wodLiveRest : l10n.wodLiveWork,
      _ => tick.countsDown ? l10n.wodLiveTimeLeft : l10n.wodLiveElapsed,
    };
    final rounds = timer.totalRounds;
    final roundLine = rounds == null
        ? null
        : wod.format == WodFormat.emom
        ? l10n.wodLiveMinuteOf(tick.round, rounds)
        : l10n.wodLiveRoundOf(tick.round, rounds);
    final cap = WodLabels.timeCap(l10n, wod);
    return AppContentWidth.reading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${WodLabels.title(l10n, wod)} · '
              '${WodLabels.division(l10n, state.division)}',
              style: styles.titleMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                WodLabels.headline(l10n, wod).toUpperCase(),
                style: styles.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
            ),
            if (cap != null) Text(cap, style: styles.titleMedium),
            const SizedBox(height: TokensSpacing.l),
            // El estado sí cambia poco: se lee al enfocarlo, sin región viva.
            Text(
              roundLine == null ? phase : '$phase · $roundLine',
              style: styles.titleLarge?.copyWith(color: colors.primary),
            ),
            Semantics(
              label: l10n.wodLiveClockLabel(time),
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    time,
                    maxLines: 1,
                    style: styles.displayLarge?.copyWith(
                      fontSize: TokensSize.heroStat,
                      fontWeight: FontWeight.w900,
                      color: colors.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TokensSpacing.l),
            for (final m in wod.movements)
              Padding(
                padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                child: WodMovementLine(
                  movement: m,
                  division: state.division,
                  style: styles.headlineSmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            const SizedBox(height: TokensSpacing.m),
          ],
        ),
      ),
    );
  }
}

/// «Pausa» (o «Seguir») y «Terminar», siempre abajo. Cuando el WOD ya acabó
/// y la hoja de la marca se cerró o falló, queda «Guardar marca».
class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.onSaveMark});

  final WodLiveState state;
  final VoidCallback onSaveMark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<WodLiveBloc>();
    final Widget content;
    if (state.status == WodLiveStatus.finished) {
      content = AppPrimaryButton(
        label: l10n.wodResultSave,
        icon: AppIcons.check,
        loading: state.saving,
        onPressed: onSaveMark,
      );
    } else {
      final paused = state.status == WodLiveStatus.paused;
      final pause = OutlinedButton.icon(
        onPressed: () => bloc.add(const WodLiveEvent.pauseToggled()),
        icon: Icon(paused ? AppIcons.start : AppIcons.pause),
        label: Text(paused ? l10n.wodLiveResume : l10n.wodLivePause),
      );
      final finish = FilledButton.icon(
        onPressed: () => bloc.add(const WodLiveEvent.finishRequested()),
        icon: const Icon(AppIcons.finish),
        label: Text(l10n.wodLiveFinish),
      );
      // Con el texto grande los dos botones no caben en fila sin partirse.
      content = context.largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                pause,
                const SizedBox(height: TokensSpacing.s),
                finish,
              ],
            )
          : Row(
              children: [
                Expanded(child: pause),
                const SizedBox(width: TokensSpacing.m),
                Expanded(child: finish),
              ],
            );
    }
    return AppContentWidth.reading(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.l,
          TokensSpacing.s,
          TokensSpacing.l,
          TokensSpacing.m,
        ),
        child: content,
      ),
    );
  }
}
