import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_config.dart';
import '../../../core/providers/hive_cache_provider.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../domain/smart_banner_dto.dart';
import 'dashboard_provider.dart';

class SmartBannerNotifier extends StateNotifier<SmartBannerState> {
  final Ref _ref;
  bool _refreshEnProgreso = false;

  SmartBannerNotifier(this._ref)
      : super(const SmartBannerState(status: SmartBannerStatus.fallback)) {
    _cargarInmediato();
    _refreshEnBackground();
    // Reactividad en tiempo real: al cambiar bienestar / adherencia / contexto
    // académico, recalcula el consejo (fallback determinista) al instante.
    _ref.listen(estadoEnergeticoProvider, (_, __) => _actualizarPorContexto());
    _ref.listen(
        adherenciaAcademicaProvider, (_, __) => _actualizarPorContexto());
    _ref.listen(contextoAcademicoProvider, (_, __) => _actualizarPorContexto());
  }

  /// Recalcula el consejo a partir de los valores actuales de bienestar,
  /// adherencia y contexto académico (determinista, sin IA → instantáneo).
  void _actualizarPorContexto() {
    final energia = _ref.read(estadoEnergeticoProvider).valueOrNull;
    final adherencia = _ref.read(adherenciaAcademicaProvider).valueOrNull;
    final contexto = _ref.read(contextoAcademicoProvider).valueOrNull;
    final dash = _ref.read(dashboardProvider).valueOrNull;
    final ctx = SmartBannerContext(
      energiaValor: energia?.valor ?? 0,
      adherenciaValor: adherencia?.valor ?? 0,
      nivelEstres: contexto?.nivelEstres ?? 5,
      evaluacionesSemana: contexto?.evaluacionesSemana ?? 0,
      tieneExamenesProximos: contexto?.tieneExamenesProximos ?? false,
      rachaEntrenamiento: dash?.racha ?? 0,
      rachaEstudio: adherencia?.rachaDias ?? 0,
      tieneCheckIn: energia != null,
      tieneAdherencia: adherencia != null,
    );
    if (!mounted) return;
    state = SmartBannerState(
      status: SmartBannerStatus.fallback,
      fallbackMensaje: _generarFallback(ctx),
    );
  }

  void _cargarInmediato() {
    final hiveBox = _ref.read(hiveSmartCacheProvider);
    final dash = _ref.read(dashboardProvider).valueOrNull;
    if (dash == null) {
      state = const SmartBannerState(
        status: SmartBannerStatus.fallback,
        fallbackMensaje:
            'Mantén el equilibrio entre estudio y ejercicio. Cada día cuenta.',
      );
      return;
    }

    final cacheKey = 'smart_banner_v2_${dash.usuario.id}';
    final cached = hiveBox.get(cacheKey);

    if (cached != null) {
      final mensaje = cached['mensaje'] as String?;
      final generadoEnStr = cached['generadoEn'] as String?;
      if (mensaje != null && mensaje.isNotEmpty) {
        final cleaned = _limpiarTexto(mensaje);
        state = SmartBannerState(
          status: SmartBannerStatus.loaded,
          mensaje: cleaned,
          generadoEn:
              generadoEnStr != null ? DateTime.tryParse(generadoEnStr) : null,
        );
        return;
      }
    }

    state = const SmartBannerState(
      status: SmartBannerStatus.fallback,
      fallbackMensaje:
          'Mantén el equilibrio entre estudio y ejercicio. Cada día cuenta.',
    );
  }

  Future<void> _refreshEnBackground() async {
    if (_refreshEnProgreso) return;
    _refreshEnProgreso = true;

    try {
      final dash = await _ref.read(dashboardProvider.future);
      final energia = await _ref.read(estadoEnergeticoProvider.future);
      final adherencia = await _ref.read(adherenciaAcademicaProvider.future);
      final contexto = await _ref.read(contextoAcademicoProvider.future);

      final ctx = SmartBannerContext(
        energiaValor: energia?.valor ?? 0,
        adherenciaValor: adherencia?.valor ?? 0,
        nivelEstres: contexto?.nivelEstres ?? 5,
        evaluacionesSemana: contexto?.evaluacionesSemana ?? 0,
        tieneExamenesProximos: contexto?.tieneExamenesProximos ?? false,
        rachaEntrenamiento: dash.racha,
        rachaEstudio: adherencia?.rachaDias ?? 0,
        tieneCheckIn: energia != null,
        tieneAdherencia: adherencia != null,
      );

      final cacheKey = 'smart_banner_${dash.usuario.id}';
      final hiveBox = _ref.read(hiveSmartCacheProvider);
      final cached = hiveBox.get(cacheKey);
      if (cached != null) {
        final cachedAt = cached['generadoEn'] as String?;
        if (cachedAt != null) {
          final cachedDate = DateTime.tryParse(cachedAt);
          if (cachedDate != null &&
              DateTime.now().difference(cachedDate).inHours < 1) {
            return;
          }
        }
      }

      if (!EnvConfig.hasGeminiApiKey) {
        state = SmartBannerState(
          status: SmartBannerStatus.fallback,
          fallbackMensaje: _generarFallback(ctx),
        );
        return;
      }

      final gemini = _ref.read(geminiServiceProvider);
      final apiKey = _ref.read(geminiApiKeyProvider);
      final prompt = ctx.toPrompt();

      final respuesta = await gemini.generarTexto(apiKey, prompt).timeout(
            const Duration(seconds: 8),
          );

      final limpio = _limpiarTexto(respuesta);
      final ahora = DateTime.now();
      hiveBox.put(cacheKey, {
        'mensaje': limpio,
        'generadoEn': ahora.toIso8601String(),
      });

      state = SmartBannerState(
        status: SmartBannerStatus.loaded,
        mensaje: limpio,
        generadoEn: ahora,
      );
    } catch (_) {
      // Mantener estado actual (cache o fallback)
    } finally {
      _refreshEnProgreso = false;
    }
  }

  String _limpiarTexto(String raw) {
    var text = raw.trim();

    final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = codeBlock.firstMatch(text);
    if (match != null) text = match.group(1)!.trim();

    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final map = json.decode(text) as Map<String, dynamic>;
        text = (map['mensaje'] ?? map['texto'] ?? map['consejo'] ?? text)
            .toString();
      } catch (_) {}
    }

    text = text.replaceAll(RegExp(r'[\{\}"\[\]]'), '').trim();

    return text;
  }
}

final consejoSmartProvider =
    StateNotifierProvider<SmartBannerNotifier, SmartBannerState>((ref) {
  return SmartBannerNotifier(ref);
});

String _generarFallback(SmartBannerContext ctx) {
  // 1. Señales académicas concretas (no dependen del check-in).
  if (ctx.tieneExamenesProximos) {
    return 'Tienes evaluaciones próximas. Modera la intensidad del entrenamiento y reserva bloques de repaso para llegar con la mente fresca.';
  }
  if (ctx.tieneAdherencia && ctx.adherenciaValor < 40) {
    return 'Tu adherencia académica está baja. Retoma tu plan con bloques cortos de estudio hoy; la constancia importa más que la intensidad.';
  }

  // 2. Señales de energía física (solo fiables si hay check-in).
  if (ctx.tieneCheckIn && ctx.energiaValor < 30) {
    return 'Tu energía está baja hoy. Prioriza el descanso y aligera tanto el estudio como el entrenamiento.';
  }
  if (ctx.tieneCheckIn && ctx.energiaValor > 70 && ctx.nivelEstres < 5) {
    return 'Energía alta y estrés bajo: gran día para un entrenamiento exigente y una sesión de estudio profunda.';
  }

  // 3. Refuerzo positivo por constancia.
  if (ctx.tieneAdherencia && ctx.rachaEstudio >= 5) {
    return '¡${ctx.rachaEstudio.round()} días seguidos cumpliendo tu plan de estudio! Mantén el ritmo y compénsalo con movimiento.';
  }
  if (ctx.rachaEntrenamiento >= 5) {
    return '¡${ctx.rachaEntrenamiento} días seguidos entrenando! Tu constancia también impulsa tu rendimiento académico.';
  }

  // 4. Invitación al check-in solo si no hay nada más relevante que destacar.
  if (!ctx.tieneCheckIn) {
    return 'Empieza con tu check-in diario: así ajustamos tu estudio y tu entrenamiento a cómo te sientes hoy.';
  }

  return 'Mantén el equilibrio entre estudio y ejercicio. Cada día cuenta.';
}
