import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../../app/config/app_config.dart';
import '../../../../app/di/app_di.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Mapa de Correr y del detalle de una carrera (ADR 0037): teselas ráster de
/// MapTiler (`MAP_TILES_KEY`, `MAP_TILES_URL`) con la atribución obligatoria,
/// la ruta con su salida y llegada y, si se da, «Estás aquí». Sin clave, la
/// ruta se dibuja sobre un fondo liso con «Mapa no disponible»: nada se rompe.
/// Es solo para mirar (sin gestos), así no se pelea con el desplazamiento de
/// la página; el resumen va en [semanticLabel].
class RunMap extends StatelessWidget {
  const RunMap({
    super.key,
    this.route = const [],
    this.here,
    required this.semanticLabel,
    this.height = TokensSize.mapHeight,
  });

  final List<(double, double)> route;
  final (double, double)? here;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final config = getIt.isRegistered<AppConfig>() ? getIt<AppConfig>() : null;
    final key = config?.mapTilesKey;
    final map = Semantics(
      label: semanticLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokensRadius.l),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ExcludeSemantics(
            child: key == null
                ? _PlainRoute(route: route, here: here)
                : _TiledMap(
                    route: route,
                    here: here,
                    url: config!.mapTilesUrl,
                    apiKey: key,
                  ),
          ),
        ),
      ),
    );
    if (route.length < 2) return map;
    // Leyenda: la salida y la llegada no se distinguen solo por el color.
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        map,
        const SizedBox(height: TokensSpacing.xs),
        ExcludeSemantics(
          child: Wrap(
            spacing: TokensSpacing.m,
            children: [
              _Legend(
                icon: Icons.circle,
                color: context.colors.primary,
                label: l10n.runMapStart,
              ),
              _Legend(
                icon: Icons.flag_rounded,
                color: context.colors.error,
                label: l10n.runMapFinish,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: TokensSize.iconXs),
      const SizedBox(width: TokensSpacing.xs),
      Text(label, style: context.textStyles.bodySmall),
    ],
  );
}

class _TiledMap extends StatelessWidget {
  const _TiledMap({
    required this.route,
    required this.here,
    required this.url,
    required this.apiKey,
  });

  final List<(double, double)> route;
  final (double, double)? here;
  final String url;
  final String apiKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final points = [for (final (lat, lon) in route) LatLng(lat, lon)];
    final center = here == null ? null : LatLng(here!.$1, here!.$2);
    final fit = points.length >= 2
        ? CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(TokensSpacing.l),
          )
        : null;
    return FlutterMap(
      options: MapOptions(
        initialCenter:
            center ??
            (points.isEmpty ? const LatLng(40.4168, -3.7038) : points.first),
        initialZoom: center != null || points.isNotEmpty ? 15 : 5,
        initialCameraFit: fit,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: url,
          additionalOptions: {'key': apiKey},
          userAgentPackageName: 'com.synaptixfit.app',
        ),
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: TokensSize.routeLine,
                color: colors.primary,
                borderStrokeWidth: TokensSize.focusRing,
                borderColor: colors.surface,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (points.length >= 2) ...[
              Marker(
                point: points.first,
                child: _Dot(color: colors.primary),
              ),
              Marker(
                point: points.last,
                child: _Dot(color: colors.error, flag: true),
              ),
            ],
            if (center != null)
              Marker(
                point: center,
                child: _Dot(color: colors.tertiary),
              ),
          ],
        ),
        SimpleAttributionWidget(
          source: Text(context.localizations.runMapAttribution),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.flag = false});

  final Color color;
  final bool flag;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: context.colors.surface,
        width: TokensSize.focusRing,
      ),
    ),
    child: flag
        ? Icon(
            Icons.flag_rounded,
            color: context.colors.onError,
            size: TokensSize.iconXs,
          )
        : const SizedBox.expand(),
  );
}

/// Sin clave del mapa: la forma de la ruta sobre un fondo liso.
class _PlainRoute extends StatelessWidget {
  const _PlainRoute({required this.route, required this.here});

  final List<(double, double)> route;
  final (double, double)? here;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Stack(
        children: [
          if (route.length >= 2)
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePainter(
                  route: route,
                  line: colors.primary,
                  start: colors.primary,
                  end: colors.error,
                ),
              ),
            )
          else
            Center(
              child: Icon(
                here == null ? Icons.map_outlined : Icons.my_location_rounded,
                color: colors.onSurfaceVariant,
                size: TokensSize.iconXl,
              ),
            ),
          Positioned(
            left: TokensSpacing.s,
            bottom: TokensSpacing.s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(TokensRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensSpacing.s,
                  vertical: TokensSpacing.xs,
                ),
                child: Text(
                  context.localizations.runMapUnavailable,
                  style: context.textStyles.labelMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.route,
    required this.line,
    required this.start,
    required this.end,
  });

  final List<(double, double)> route;
  final Color line;
  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = route.first.$1, maxLat = route.first.$1;
    var minLon = route.first.$2, maxLon = route.first.$2;
    for (final (lat, lon) in route) {
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLon = math.min(minLon, lon);
      maxLon = math.max(maxLon, lon);
    }
    // La longitud se encoge con la latitud: sin esto la ruta saldría ancha.
    final lonScale = math.cos(((minLat + maxLat) / 2) * math.pi / 180);
    final spanX = math.max((maxLon - minLon) * lonScale, 1e-9);
    final spanY = math.max(maxLat - minLat, 1e-9);
    const pad = TokensSpacing.l;
    final scale = math.min(
      (size.width - 2 * pad) / spanX,
      (size.height - 2 * pad) / spanY,
    );
    final offsetX = (size.width - spanX * scale) / 2;
    final offsetY = (size.height - spanY * scale) / 2;
    Offset at((double, double) p) => Offset(
      offsetX + (p.$2 - minLon) * lonScale * scale,
      size.height - (offsetY + (p.$1 - minLat) * scale),
    );
    final path = Path()..moveTo(at(route.first).dx, at(route.first).dy);
    for (final p in route.skip(1)) {
      final o = at(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = TokensSize.routeLine
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Salida redonda y llegada cuadrada: no se distinguen solo por el color
    // (WCAG 1.4.1); la leyenda de [RunMap] lo explica.
    canvas
      ..drawCircle(
        at(route.first),
        TokensSize.routeMarker / 2,
        Paint()..color = start,
      )
      ..drawRect(
        Rect.fromCenter(
          center: at(route.last),
          width: TokensSize.routeMarker,
          height: TokensSize.routeMarker,
        ),
        Paint()..color = end,
      );
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.route != route || old.line != line;
}
