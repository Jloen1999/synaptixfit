import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../insignias/application/insignias_provider.dart';
import '../application/dashboard_provider.dart';
import 'widgets/saludo_card.dart';
import 'widgets/smart_banner_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/plan_week_bar.dart';
import 'widgets/cognitive_load_bar.dart';
import 'widgets/estado_section.dart';
import 'widgets/timeline_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);

    // Mostrar toast de insignias recién obtenidas
    ref.listen(insigniasRecienObtenidasProvider, (prev, next) {
      if (next.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            mostrarInsigniaToast(context, next);
          }
        });
      }
    });

    return FeatureScaffold(
      title: '',
      centerTitle: false,
      hideAppBar: true,
      child: data.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLoader(height: 160),
              SizedBox(height: 12),
              SkeletonLoader(height: 80),
              SizedBox(height: 12),
              SkeletonLoader(height: 80),
              SizedBox(height: 12),
              SkeletonLoader(height: 80),
            ],
          ),
        ),
        error: (error, _) {
          final msg = error.toString();
          final esErrorRed = msg.contains('SocketException') ||
              msg.contains('Failed host lookup') ||
              msg.contains('No address associated');
          return Center(
            child: EmptyState(
              title: esErrorRed ? 'Sin conexión' : 'Error al cargar',
              message: esErrorRed
                  ? 'No se pudo conectar con el servidor. Comprueba tu conexión a internet.'
                  : 'No se pudo cargar el dashboard.',
              icon:
                  esErrorRed ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
              action: TextButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: const Text('Reintentar'),
              ),
            ),
          );
        },
        data: (value) {
          final topPadding = MediaQuery.of(context).padding.top + 8;
          return LayoutBuilder(
            builder: (context, constraints) {
              // ignore: unused_local_variable
              final isWide = constraints.maxWidth >= 760;
              // ignore: unused_local_variable
              final isVeryWide = constraints.maxWidth >= 1040;

              return ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  // 1. SaludoCard — greeting + avatar + XP + nivel + streaks
                  Consumer(
                    builder: (context, ref, _) {
                      final adherenciaAsync =
                          ref.watch(adherenciaAcademicaProvider);
                      return adherenciaAsync.when(
                        loading: () => SaludoCard(
                          data: value,
                          rachaEntrenamiento: value.racha,
                          diasEstudio: null, // Muestra shimmer, no un 0 falso
                        ),
                        error: (_, __) => SaludoCard(
                          data: value,
                          rachaEntrenamiento: value.racha,
                          diasEstudio: 0, // Degradación elegante
                        ),
                        data: (adherencia) => SaludoCard(
                          data: value,
                          rachaEntrenamiento: value.racha,
                          diasEstudio: adherencia?.rachaDias.round() ?? 0,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  // 2. SmartBannerCard — consejo IA (Gemini o fallback)
                  const SmartBannerCard(),
                  const SizedBox(height: 14),
                  // 3. QuickActionsRow — 4 chips de acceso rápido
                  const QuickActionsRow(),
                  const SizedBox(height: 16),
                  // 4. PlanWeekBar — "Semana X de Y" (auto-hide si no hay rutina)
                  const PlanWeekBar(),
                  const SizedBox(height: 12),
                  // 5. CognitiveLoadBar — barra de carga cognitiva (auto-hide si no hay datos)
                  const CognitiveLoadBar(),
                  const SizedBox(height: 12),
                  // 6. EstadoSection — EnergyRing + Adherencia (+ Estudio si hay carga)
                  const EstadoSection(),
                  const SizedBox(height: 14),
                  // 7. TimelineSection — linea de tiempo unificada (3 tabs)
                  const TimelineSection(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
