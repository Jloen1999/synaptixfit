import 'package:flutter/material.dart';
import '../../domain/calendar_dtos.dart';

/// Widget que renderiza un banner de reto en el lienzo continuo con
/// barra de progreso y píldoras de tareas para retos complejos.
class RetoBannerWidget extends StatelessWidget {
  const RetoBannerWidget({
    required this.banner,
    required this.columnWidth,
    required this.startCol,
    required this.endCol,
    this.onTap,
    this.onTapTarea,
    super.key,
  });

  final RetoBanner banner;
  final double columnWidth;
  final int startCol;
  final int endCol;
  final VoidCallback? onTap;
  final VoidCallback? onTapTarea;

  double get _totalWidth => (endCol - startCol + 1) * columnWidth - 4;
  double get _height => banner.esComplejo && banner.tareas.isNotEmpty ? 44 : 28;

  @override
  Widget build(BuildContext context) {
    final esComplejo = banner.esComplejo && banner.tareas.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _totalWidth,
        height: _height,
        decoration: BoxDecoration(
          color: banner.color.withValues(alpha: 0.15),
          border: Border(
            left: BorderSide(color: banner.color, width: 3),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 4, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 12,
                    color: banner.color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      banner.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: banner.color,
                      ),
                    ),
                  ),
                  if (banner.meta != null && banner.meta!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        banner.meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: banner.color.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 40,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: banner.progreso.clamp(0.0, 1.0),
                        backgroundColor: banner.color.withValues(alpha: 0.15),
                        color: banner.color,
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (esComplejo)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 2, top: 2),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: banner.tareas.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (_, i) {
                      final tarea = banner.tareas[i];
                      final completada = tarea.completada;
                      return GestureDetector(
                        onTap: completada ? null : onTapTarea,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: completada
                                ? banner.color.withValues(alpha: 0.08)
                                : banner.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: completada
                                  ? banner.color.withValues(alpha: 0.2)
                                  : banner.color.withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tarea.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: completada
                                  ? banner.color.withValues(alpha: 0.4)
                                  : banner.color,
                              decoration: completada
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor:
                                  banner.color.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
