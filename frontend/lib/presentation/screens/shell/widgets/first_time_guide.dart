import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/guide_id.dart';
import '../../../widgets/widgets.dart';
import '../../auth/session/bloc/session_bloc.dart';
import '../bloc/guide_tour_bloc.dart';
import 'guide_coordinator.dart';

export 'guide_coordinator.dart';

/// Envuelve una pantalla con su guía la primera vez (ADR 0049). Sale una vez
/// por cuenta y teléfono, cuando la pantalla ya tiene su contenido ([ready]),
/// se ve y no tiene nada encima (hoja, diálogo u otra pantalla). Si la visita
/// la abrió un aviso o un enlace, espera a la siguiente. Los pasos señalan
/// partes por su clave: mover una parte de sitio no rompe la guía.
class FirstTimeGuide extends StatefulWidget {
  const FirstTimeGuide({
    super.key,
    required this.guide,
    required this.ready,
    required this.steps,
    required this.child,
  });

  final GuideId guide;

  /// La pantalla ha cargado su contenido (ni cargando ni con error).
  final bool ready;

  /// Pasos con sus textos; los que no estén pintados se saltan.
  final List<AppGuideStep> Function(BuildContext context) steps;
  final Widget child;

  @override
  State<FirstTimeGuide> createState() => _FirstTimeGuideState();
}

class _FirstTimeGuideState extends State<FirstTimeGuide> {
  GuideCoordinator? _coordinator;
  GuideTourBloc? _bloc;
  StreamSubscription<GuideTourState>? _changes;

  /// La pantalla se ve (su pestaña es la activa y nada opaco la tapa).
  bool _visible = false;

  /// Su ruta es la de arriba de su navegador.
  bool _onTop = false;

  /// Esta visita la abrió un aviso o un enlace.
  bool _fromOutside = false;
  bool _scheduled = false;
  bool _opening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coordinator = _coordinator ??= GuideScope.maybeOf(context);
    if (coordinator == null) return;
    if (_bloc == null) {
      final bloc = _bloc = coordinator.createBloc();
      _changes = bloc.stream.listen((_) => _schedule());
      coordinator.popups.addListener(_schedule);
    }
    final visible = TickerMode.valuesOf(context).enabled;
    // Cada entrada (o vuelta) a la pantalla es una visita nueva.
    if (visible && !_visible) _fromOutside = coordinator.arrivedFromOutside;
    _visible = visible;
    _onTop = ModalRoute.of(context)?.isCurrent ?? true;
    _schedule();
  }

  @override
  void didUpdateWidget(FirstTimeGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    _coordinator?.popups.removeListener(_schedule);
    // Con la guía abierta, el bloc se cierra cuando ella se cierre (y la apunte).
    if (!_opening) unawaited(_bloc?.close());
    super.dispose();
  }

  bool get _free =>
      _visible && _onTop && (_coordinator?.popups.value ?? 0) == 0;

  /// Se mira tras pintar: la pantalla ya está colocada y sus partes medidas.
  void _schedule() {
    if (_scheduled || !mounted || _bloc == null) return;
    _scheduled = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _scheduled = false;
        _check();
      })
      ..ensureVisualUpdate();
  }

  void _check() {
    final bloc = _bloc;
    if (!mounted || bloc == null || bloc.isClosed) return;
    switch (bloc.state.status) {
      case GuideTourStatus.idle:
        if (!widget.ready || _fromOutside || !_free) return;
        final accountId = context.read<SessionBloc>().account?.id ?? '';
        bloc.add(
          GuideTourEvent.requested(guide: widget.guide, accountId: accountId),
        );
      case GuideTourStatus.showing:
        if (_opening || !widget.ready || !_free) return;
        unawaited(_open(bloc));
      case GuideTourStatus.checking ||
          GuideTourStatus.saving ||
          GuideTourStatus.done:
        return;
    }
  }

  Future<void> _open(GuideTourBloc bloc) async {
    _opening = true;
    final steps = [
      for (final step in widget.steps(context))
        if (step.visible) step,
    ];
    if (steps.isEmpty) {
      _opening = false;
      bloc.add(const GuideTourEvent.abandoned());
      return;
    }
    await showAppGuideTour(context, steps: steps);
    // Vista aunque la pantalla ya se haya cerrado: no vuelve a salir.
    bloc.add(const GuideTourEvent.closed());
    await bloc.stream.firstWhere((s) => s.status == GuideTourStatus.done);
    _opening = false;
    if (!mounted) await bloc.close();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
