import 'package:flutter/material.dart';

import '../../../../domain/models/academic/mind_map.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Mapa mental interactivo: árbol de izquierda a derecha con aristas Bézier,
/// nodos que se expanden o pliegan al tocarlos y zoom/desplazamiento.
class MindMapView extends StatefulWidget {
  const MindMapView({super.key, required this.map});

  final MindMap map;

  @override
  State<MindMapView> createState() => _MindMapViewState();
}

class _MindMapViewState extends State<MindMapView> {
  static const _nodeWidth = 188.0;
  static const _nodeHeight = 60.0;
  static const _hGap = 64.0;
  static const _vGap = 14.0;
  static const _padding = 24.0;

  /// Claves de los nodos desplegados ("0", "0.2", ...). La raíz siempre lo está.
  late Set<String> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = _initialExpanded();
  }

  @override
  void didUpdateWidget(MindMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.map != widget.map) _expanded = _initialExpanded();
  }

  /// Por defecto se ven la idea central, las ramas y su primer nivel.
  Set<String> _initialExpanded() => {
    for (var i = 0; i < widget.map.branches.length; i++) '$i',
  };

  void _toggle(String key) => setState(() {
    if (!_expanded.remove(key)) _expanded.add(key);
  });

  void _setAll(bool expand) => setState(() {
    _expanded = expand ? _allKeys() : <String>{};
  });

  Set<String> _allKeys() {
    final keys = <String>{};
    void visit(List<MindMapNode> nodes, String prefix) {
      for (var i = 0; i < nodes.length; i++) {
        final key = prefix.isEmpty ? '$i' : '$prefix.$i';
        if (nodes[i].children.isNotEmpty) {
          keys.add(key);
          visit(nodes[i].children, key);
        }
      }
    }

    visit(widget.map.branches, '');
    return keys;
  }

  List<Color> _branchColors(BuildContext context) => [
    context.palette.study,
    context.palette.sessions,
    context.colors.secondary,
    context.palette.calories,
    context.palette.accent,
    context.palette.success,
    context.colors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    final layout = _layout();
    final colors = _branchColors(context);
    final l10n = context.localizations;
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(240),
            minScale: 0.3,
            maxScale: 2.5,
            child: SizedBox(
              width: layout.width,
              height: layout.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _EdgePainter(
                        nodes: layout.nodes,
                        colors: colors,
                        nodeWidth: _nodeWidth,
                        nodeHeight: _nodeHeight,
                      ),
                    ),
                  ),
                  for (final node in layout.nodes)
                    Positioned(
                      left: node.x,
                      top: node.y,
                      width: _nodeWidth,
                      height: _nodeHeight,
                      child: _NodeBox(
                        node: node,
                        color: node.depth == 0
                            ? context.colors.tertiary
                            : colors[node.branch % colors.length],
                        onTap: node.hasChildren
                            ? () => _toggle(node.key)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: TokensSpacing.s,
          bottom: TokensSpacing.s,
          child: Card(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.academicMindMapExpandAll,
                  icon: const Icon(Icons.unfold_more_rounded),
                  onPressed: () => _setAll(true),
                ),
                IconButton(
                  tooltip: l10n.academicMindMapCollapseAll,
                  icon: const Icon(Icons.unfold_less_rounded),
                  onPressed: () => _setAll(false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Coloca cada nodo visible: x por profundidad, y centrada sobre sus hijos.
  _Layout _layout() {
    final nodes = <_PlacedNode>[];
    var nextLeafY = _padding;
    var maxDepth = 0;

    double place(
      String key,
      String title,
      List<MindMapNode> children,
      int depth,
      int branch,
      String? parentKey,
    ) {
      if (depth > maxDepth) maxDepth = depth;
      final expanded = depth == 0 || _expanded.contains(key);
      final visibleChildren = expanded ? children : const <MindMapNode>[];
      double y;
      if (visibleChildren.isEmpty) {
        y = nextLeafY;
        nextLeafY += _nodeHeight + _vGap;
      } else {
        final childYs = <double>[];
        for (var i = 0; i < visibleChildren.length; i++) {
          final childKey = depth == 0 ? '$i' : '$key.$i';
          childYs.add(
            place(
              childKey,
              visibleChildren[i].title,
              visibleChildren[i].children,
              depth + 1,
              depth == 0 ? i : branch,
              key,
            ),
          );
        }
        y = (childYs.first + childYs.last) / 2;
      }
      nodes.add(
        _PlacedNode(
          key: key,
          parentKey: parentKey,
          title: title,
          depth: depth,
          branch: branch,
          x: _padding + depth * (_nodeWidth + _hGap),
          y: y,
          hasChildren: depth > 0 && children.isNotEmpty,
          expanded: expanded,
        ),
      );
      return y;
    }

    place('root', widget.map.central, widget.map.branches, 0, 0, null);
    return _Layout(
      nodes: nodes,
      width: _padding * 2 + (maxDepth + 1) * _nodeWidth + maxDepth * _hGap,
      height: nextLeafY + _padding,
    );
  }
}

class _Layout {
  const _Layout({
    required this.nodes,
    required this.width,
    required this.height,
  });

  final List<_PlacedNode> nodes;
  final double width;
  final double height;
}

class _PlacedNode {
  const _PlacedNode({
    required this.key,
    required this.parentKey,
    required this.title,
    required this.depth,
    required this.branch,
    required this.x,
    required this.y,
    required this.hasChildren,
    required this.expanded,
  });

  final String key;
  final String? parentKey;
  final String title;
  final int depth;
  final int branch;
  final double x;
  final double y;
  final bool hasChildren;
  final bool expanded;
}

class _NodeBox extends StatelessWidget {
  const _NodeBox({required this.node, required this.color, this.onTap});

  final _PlacedNode node;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isRoot = node.depth == 0;
    final l10n = context.localizations;
    return Semantics(
      button: onTap != null,
      expanded: node.hasChildren ? node.expanded : null,
      label: node.title,
      child: Tooltip(
        message: node.title,
        child: Material(
          color: isRoot ? color : color.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensRadius.m),
            side: BorderSide(color: color.withValues(alpha: isRoot ? 1 : 0.6)),
          ),
          child: AppFocusOutline(
            borderRadius: BorderRadius.circular(TokensRadius.m),
            child: InkWell(
              borderRadius: BorderRadius.circular(TokensRadius.m),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensSpacing.s,
                  vertical: TokensSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (isRoot
                                    ? context.textStyles.titleSmall
                                    : context.textStyles.bodyMedium)
                                ?.copyWith(
                                  color: isRoot
                                      ? context.colors.onTertiary
                                      : context.colors.onSurface,
                                  fontWeight: node.depth <= 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                      ),
                    ),
                    if (node.hasChildren)
                      Icon(
                        node.expanded
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 20,
                        color: color,
                        semanticLabel: node.expanded
                            ? l10n.academicMindMapCollapse
                            : l10n.academicMindMapExpand,
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

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.nodes,
    required this.colors,
    required this.nodeWidth,
    required this.nodeHeight,
  });

  final List<_PlacedNode> nodes;
  final List<Color> colors;
  final double nodeWidth;
  final double nodeHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final byKey = {for (final n in nodes) n.key: n};
    for (final node in nodes) {
      final parent = node.parentKey == null ? null : byKey[node.parentKey];
      if (parent == null) continue;
      final start = Offset(parent.x + nodeWidth, parent.y + nodeHeight / 2);
      final end = Offset(node.x, node.y + nodeHeight / 2);
      final dx = (end.dx - start.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx + dx, start.dy, end.dx - dx, end.dy, end.dx, end.dy);
      final paint = Paint()
        ..color = colors[node.branch % colors.length].withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = node.depth == 1 ? 2.4 : 1.6;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) => oldDelegate.nodes != nodes;
}
