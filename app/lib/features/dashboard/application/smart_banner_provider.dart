import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_config.dart';
import '../../../core/providers/hive_cache_provider.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../domain/smart_banner_dto.dart';
import 'dashboard_provider.dart';

/// Genera un consejo personalizado para el SmartBanner usando Gemini.
/// Cachea el resultado en Hive por 1 hora.
/// Si Gemini falla, retorna un consejo determinista de fallback.
final consejoSmartProvider = FutureProvider<SmartBannerState>((ref) async {
  // Esperar a que los datos estén disponibles (usar .future, no .valueOrNull)
  final dash = await ref.watch(dashboardProvider.future);
  final energia = await ref.watch(estadoEnergeticoProvider.future);
  final adherencia = await ref.watch(adherenciaAcademicaProvider.future);
  final contexto = await ref.watch(contextoAcademicoProvider.future);

  // Construir contexto
  final ctx = SmartBannerContext(
    energiaValor: energia?.valor ?? 0,
    adherenciaValor: adherencia?.valor ?? 0,
    nivelEstres: contexto?.nivelEstres ?? 5,
    evaluacionesSemana: contexto?.evaluacionesSemana ?? 0,
    tieneExamenesProximos: contexto?.tieneExamenesProximos ?? false,
    rachaEntrenamiento: dash.racha,
    rachaEstudio: adherencia?.rachaDias ?? 0,
  );

  // Intentar cache Hive primero
  final hiveBox = ref.read(hiveSmartCacheProvider);
  final cacheKey = 'smart_banner_${dash.usuario.id}';
  final cached = hiveBox.get(cacheKey);
  if (cached != null) {
    final cachedAt = cached['generadoEn'] as String?;
    if (cachedAt != null) {
      final cachedDate = DateTime.tryParse(cachedAt);
      if (cachedDate != null &&
          DateTime.now().difference(cachedDate).inHours < 1) {
        return SmartBannerState(
          status: SmartBannerStatus.loaded,
          mensaje: cached['mensaje'] as String,
          generadoEn: cachedDate,
        );
      }
    }
  }

  // Sin API key → fallback inmediato
  if (!EnvConfig.hasGeminiApiKey) {
    final fallback = _generarFallback(ctx);
    return SmartBannerState(
      status: SmartBannerStatus.fallback,
      fallbackMensaje: fallback,
    );
  }

  // Llamar a Gemini vía el servicio compartido
  try {
    final gemini = ref.read(geminiServiceProvider);
    final apiKey = ref.read(geminiApiKeyProvider);
    final prompt = ctx.toPrompt();
    final respuesta = await gemini.generarTexto(apiKey, prompt).timeout(
          const Duration(seconds: 8),
        );

    // Cachear en Hive
    final ahora = DateTime.now();
    hiveBox.put(cacheKey, {
      'mensaje': respuesta,
      'generadoEn': ahora.toIso8601String(),
    });

    return SmartBannerState(
      status: SmartBannerStatus.loaded,
      mensaje: respuesta,
      generadoEn: ahora,
    );
  } catch (_) {
    final fallback = _generarFallback(ctx);
    return SmartBannerState(
      status: SmartBannerStatus.fallback,
      fallbackMensaje: fallback,
    );
  }
});

String _generarFallback(SmartBannerContext ctx) {
  if (ctx.energiaValor < 30) {
    return 'Tu energía está baja hoy. Prioriza el descanso y la recuperación.';
  }
  if (ctx.tieneExamenesProximos) {
    return 'Tienes exámenes próximos. Ajusta tu entrenamiento para mantener el foco académico.';
  }
  if (ctx.energiaValor > 70 && ctx.nivelEstres < 5) {
    return 'Energía alta y estrés bajo. Es un gran día para un entrenamiento intenso.';
  }
  if (ctx.rachaEntrenamiento >= 5) {
    return '¡${ctx.rachaEntrenamiento} días seguidos entrenando! Mantén la constancia.';
  }
  return 'Mantén el equilibrio entre estudio y ejercicio. Cada día cuenta.';
}
