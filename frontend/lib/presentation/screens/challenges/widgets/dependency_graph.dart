import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/enums/milestone_condition.dart';
import '../../../../domain/enums/milestone_status.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';

/// Grafo visual de dependencias entre tareas: niveles de arriba abajo según la
/// profundidad de cada tarea y aristas curvas dibujadas con [CustomPaint].
class DependencyGraph extends StatelessWidget {
  const DependencyGraph({super.key, required this.milestones, this.onTap});

  final List<Milestone> milestones;
  final ValueChanged<Milestone>? onTap;

  static const _nodeWidth = 150.0;
  static const _nodeHeight = 64.0;
  static const _hGap = TokensSpacing.m;
  static const _vGap = TokensSpacing.xl;

  /// Profundidad de cada tarea (0 = sin dependencias). Ignora ciclos.
  static Map<String, int> depths(List<Milestone> milestones) {
    final byId = {for (final m in milestones) m.id: m};
    final result = <String, int>{};
    int depthOf(String id, Set<String> visiting) {
      final cached = result[id];
      if (cached != null) return cached;
      final m = byId[id];
      if (m == null || !visiting.add(id)) return 0;
      var depth = 0;
      for (final dep in m.dependencies) {
        if (byId.containsKey(dep)) {
          depth = math.max(depth, depthOf(dep, visiting) + 1);
        }
      }
      visiting.remove(id);
      return result[id] = depth;
    }

    for (final m in milestones) {
      depthOf(m.id, <String>{});
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final depth = depths(milestones);
    final layers = <int, List<Milestone>>{};
    for (final m in milestones) {
      layers.putIfAbsent(depth[m.id] ?? 0, () => []).add(m);
    }
    final levelCount = layers.isEmpty ? 0 : layers.keys.reduce(math.max) + 1;
    final maxPerLayer = layers.values.fold(0, (a, l) => math.max(a, l.length));
    final width = maxPerLayer * (_nodeWidth + _hGap) - _hGap;
    final height = levelCount * (_nodeHeight + _vGap) - _vGap;

    final positions = <String, Offset>{};
    layers.forEach((level, nodes) {
      final rowWidth = nodes.length * (_nodeWidth + _hGap) - _hGap;
      final startX = (width - rowWidth) / 2;
      for (var i = 0; i < nodes.length; i++) {
        positions[nodes[i].id] = Offset(
          startX + i * (_nodeWidth + _hGap),
          level * (_nodeHeight + _vGap),
        );
      }
    });

    final edges = <(Offset, Offset, bool)>[];
    final byId = {for (final m in milestones) m.id: m};
    for (final m in milestones) {
      final to = positions[m.id];
      if (to == null) continue;
      for (final dep in m.dependencies) {
        final from = positions[dep];
        if (from == null) continue;
        edges.add((
          from + const Offset(_nodeWidth / 2, _nodeHeight),
          to + const Offset(_nodeWidth / 2, 0),
          byId[dep]?.completed ?? false,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Legend(),
        const SizedBox(height: TokensSpacing.m),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(width, 0),
            height: math.max(height, 0),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EdgesPainter(
                      edges: edges,
                      color: context.colors.outlineVariant,
                      doneColor: context.palette.success,
                    ),
                  ),
                ),
                for (final m in milestones)
                  if (positions[m.id] case final pos?)
                    Positioned(
                      left: pos.dx,
                      top: pos.dy,
                      width: _nodeWidth,
                      height: _nodeHeight,
                      child: _Node(
                        milestone: m,
                        onTap: onTap == null ? null : () => onTap!(m),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.milestone, this.onTap});

  final Milestone milestone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = milestone.status;
    final color = status.color(context);
    final deps = milestone.dependencies.length;
    // Nodo propio con la etiqueta; el InkWell aporta acción y foco al mismo
    // nodo (por eso se excluye solo el contenido, no el InkWell).
    return Semantics(
      container: true,
      label: '${milestone.title}. ${status.label(context)}',
      button: onTap != null,
      child: Material(
        color: status == MilestoneStatus.locked
            ? context.colors.surfaceContainerLow
            : color.withValues(alpha: AppPill.tintAlpha),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          side: BorderSide(color: color, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: AppFocusOutline(
          child: InkWell(
            onTap: onTap,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(TokensSpacing.s),
                child: Row(
                  children: [
                    Icon(status.icon, size: TokensSize.iconXs, color: color),
                    const SizedBox(width: TokensSpacing.xs),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            maxLines: deps > 1 ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelLarge,
                          ),
                          if (deps > 1)
                            Text(
                              milestone.condition.label(
                                context,
                                n:
                                    milestone.condition ==
                                        MilestoneCondition.xOfY
                                    ? milestone.conditionN
                                    : 1,
                                total: deps,
                              ),
                              style: context.textStyles.labelSmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TokensSpacing.m,
      runSpacing: TokensSpacing.xs,
      children: [
        for (final s in MilestoneStatus.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s.icon, size: TokensSize.iconXs, color: s.color(context)),
              const SizedBox(width: TokensSpacing.xs),
              Text(s.label(context), style: context.textStyles.labelSmall),
            ],
          ),
      ],
    );
  }
}

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({
    required this.edges,
    required this.color,
    required this.doneColor,
  });

  /// (origen, destino, dependencia completada).
  final List<(Offset, Offset, bool)> edges;
  final Color color;
  final Color doneColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (from, to, done) in edges) {
      final paint = Paint()
        ..color = done ? doneColor : color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final midY = (from.dy + to.dy) / 2;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy - 4);
      canvas.drawPath(path, paint);
      final arrow = Path()
        ..moveTo(to.dx - 5, to.dy - 9)
        ..lineTo(to.dx, to.dy - 2)
        ..lineTo(to.dx + 5, to.dy - 9);
      canvas.drawPath(arrow, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgesPainter old) =>
      old.edges != edges || old.color != color || old.doneColor != doneColor;
}
