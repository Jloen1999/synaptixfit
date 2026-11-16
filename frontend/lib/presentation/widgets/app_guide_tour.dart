import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_primary_button.dart';

/// Un paso de [showAppGuideTour]: la parte que se señala ([target], la clave
/// del widget en la pantalla) y lo que se dice de ella (título y una frase).
class AppGuideStep {
  const AppGuideStep({
    required this.target,
    required this.title,
    required this.body,
  });

  final GlobalKey target;
  final String title;
  final String body;

  /// La parte está pintada ahora mismo: se puede señalar.
  bool get visible {
    final box = target.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize;
  }
}

/// Guía la primera vez (ADR 0049): oscurece todo menos la parte de [steps]
/// que toca y, junto a ella, una tarjeta con su título, una frase, «Saltar» y
/// «Siguiente (n de N)» (en el último paso, «Entendido»). Va encima de todo
/// (navegador raíz) y se cierra también con «atrás» o Escape. Termina cuando se
/// cierra, de cualquier forma. Los pasos sin nada pintado se saltan.
Future<void> showAppGuideTour(
  BuildContext context, {
  required List<AppGuideStep> steps,
}) {
  final visible = [
    for (final step in steps)
      if (step.visible) step,
  ];
  if (visible.isEmpty) return Future.value();
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    // El velo con el hueco lo pinta la guía; tocar fuera no la cierra (se
    // perdería sin querer): para eso está «Saltar».
    barrierColor: Colors.transparent,
    transitionDuration: context.motion(TokensDuration.fast),
    pageBuilder: (_, _, _) => AppGuideTour(steps: visible),
    transitionBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Contenido de [showAppGuideTour]: velo con hueco y tarjeta del paso. El foco
/// va al botón principal de la tarjeta y el lector la lee como un diálogo
/// («Guía, paso 1 de 3. Tu día»); cada paso nuevo se anuncia entero. Sin
/// animaciones si el sistema pide reducir el movimiento.
class AppGuideTour extends StatefulWidget {
  const AppGuideTour({super.key, required this.steps});

  final List<AppGuideStep> steps;

  @override
  State<AppGuideTour> createState() => _AppGuideTourState();
}

class _AppGuideTourState extends State<AppGuideTour>
    with WidgetsBindingObserver {
  final _primary = FocusNode(debugLabel: 'guide-primary');
  int _index = 0;

  /// Dónde está la parte señalada, en las coordenadas de la guía (nulo
  /// mientras se coloca a la vista).
  Rect? _hole;

  AppGuideStep get _step => widget.steps[_index];
  bool get _last => _index >= widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_show(0)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _primary.dispose();
    super.dispose();
  }

  /// Al girar el móvil o cambiar el tamaño de la ventana, el hueco se recoloca.
  @override
  void didChangeMetrics() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  /// Lleva la parte del paso [index] a la vista (si está en una lista) y la
  /// señala; si ya no está pintada, pasa a la siguiente.
  Future<void> _show(int index) async {
    var next = index;
    while (next < widget.steps.length && !widget.steps[next].visible) {
      next++;
    }
    if (next >= widget.steps.length) {
      _close();
      return;
    }
    setState(() {
      _index = next;
      _hole = null;
    });
    final target = _step.target.currentContext;
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: context.motion(TokensDuration.normal),
      );
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
      _primary.requestFocus();
      // El primero ya lo lee el lector al abrirse la guía (nombre del
      // diálogo); los siguientes se anuncian enteros al cambiar.
      if (_index > 0) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          '${_step.title}. ${_step.body}',
          Directionality.of(context),
        );
      }
    });
  }

  void _measure() {
    if (!mounted) return;
    final target = _step.target.currentContext?.findRenderObject();
    final mine = context.findRenderObject();
    if (target is! RenderBox ||
        !target.attached ||
        !target.hasSize ||
        mine is! RenderBox) {
      setState(() => _hole = null);
      return;
    }
    final topLeft = mine.globalToLocal(target.localToGlobal(Offset.zero));
    setState(() => _hole = topLeft & target.size);
  }

  void _next() => _last ? _close() : unawaited(_show(_index + 1));

  void _close() {
    if (mounted) unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final total = widget.steps.length;
    final step = _step;
    final primary = AppPrimaryButton(
      label: _last ? l10n.guideDone : l10n.guideNext(_index + 1, total),
      focusNode: _primary,
      onPressed: _next,
    );
    final skip = TextButton(onPressed: _close, child: Text(l10n.guideSkip));
    final card = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: l10n.guideStepLabel(_index + 1, total, step.title),
      child: Material(
        color: context.colors.surfaceContainerHigh,
        // El borde la separa del velo también en el tema oscuro.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensRadius.l),
          side: BorderSide(color: context.colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TokensSpacing.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(step.title, style: context.textStyles.titleMedium),
              ),
              const SizedBox(height: TokensSpacing.xs),
              Text(
                step.body,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              // Con letra grande o poco ancho, uno debajo del otro: no se
              // corta ninguno (p. ej. en francés a 320 dp).
              if (context.largeText ||
                  MediaQuery.sizeOf(context).width <
                      TokensLayout.cardActionsInlineMin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    primary,
                    if (!_last) ...[
                      const SizedBox(height: TokensSpacing.xs),
                      skip,
                    ],
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_last) ...[
                      skip,
                      const SizedBox(width: TokensSpacing.s),
                    ],
                    Flexible(child: primary),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: Stack(
        children: [
          // El velo no se lee ni deja tocar lo de debajo durante la guía.
          Positioned.fill(
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: CustomPaint(
                  painter: _ScrimPainter(
                    hole: _hole,
                    color: context.colors.scrim.withValues(
                      alpha: TokensOpacity.guideScrim,
                    ),
                    ring: context.colors.primary,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _CardLayout(
                hole: _hole,
                padding: MediaQuery.paddingOf(context),
              ),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

/// Velo que cubre todo menos [hole], con un aro del color principal alrededor
/// del hueco (se ve también en el tema claro).
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({
    required this.hole,
    required this.color,
    required this.ring,
  });

  final Rect? hole;
  final Color color;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole == null) {
      canvas.drawPath(all, Paint()..color = color);
      return;
    }
    final cut = RRect.fromRectAndRadius(
      hole.inflate(TokensSpacing.xs),
      const Radius.circular(TokensRadius.m),
    );
    canvas
      ..drawPath(
        Path.combine(PathOperation.difference, all, Path()..addRRect(cut)),
        Paint()..color = color,
      )
      ..drawRRect(
        cut,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = TokensSize.focusRing,
      );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.color != color || old.ring != ring;
}

/// Coloca la tarjeta debajo del hueco si cabe, si no encima y, si tampoco
/// (letra muy grande o parte muy alta), abajo del todo. Nunca más ancha que un
/// formulario: en pantalla ancha no se estira.
class _CardLayout extends SingleChildLayoutDelegate {
  const _CardLayout({required this.hole, required this.padding});

  final Rect? hole;
  final EdgeInsets padding;

  static const _gutter = TokensSpacing.m;
  static const _gap = TokensSpacing.s;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(
      TokensLayout.formMaxWidth,
      constraints.maxWidth - padding.horizontal - _gutter * 2,
    );
    final height = constraints.maxHeight - padding.vertical - _gutter * 2;
    return BoxConstraints(
      minWidth: math.max(0, width),
      maxWidth: math.max(0, width),
      maxHeight: math.max(0, height),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final hole = this.hole;
    final left = padding.left + _gutter;
    final right = size.width - padding.right - _gutter - child.width;
    final top = padding.top + _gutter;
    final bottom = size.height - padding.bottom - _gutter - child.height;
    if (hole == null) {
      return Offset(
        (size.width - child.width) / 2,
        (size.height - child.height) / 2,
      );
    }
    final x = (hole.center.dx - child.width / 2)
        .clamp(left, math.max(left, right))
        .toDouble();
    final below = hole.bottom + _gap + TokensSpacing.xs;
    if (below <= bottom) return Offset(x, below);
    final above = hole.top - _gap - TokensSpacing.xs - child.height;
    if (above >= top) return Offset(x, above);
    return Offset(x, math.max(top, bottom));
  }

  @override
  bool shouldRelayout(_CardLayout old) =>
      old.hole != hole || old.padding != padding;
}
