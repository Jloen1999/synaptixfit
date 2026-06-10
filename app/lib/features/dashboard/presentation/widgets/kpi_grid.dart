import 'package:flutter/material.dart';

import '../../../../shared/widgets/kpi_card.dart';
import '../../../../core/design_system/sv_colors.dart';
import '../../application/dashboard_provider.dart';

/// Grid de KPIs adaptables al ancho de pantalla: calorías y sesiones.
class KpiGrid extends StatelessWidget {
  const KpiGrid({
    required this.data,
    required this.isWide,
    required this.isVeryWide,
    super.key,
  });

  final DashboardData data;
  final bool isWide;
  final bool isVeryWide;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildKpiColumn(data),
      );
    }
    return _buildKpiGrid(data, isVeryWide);
  }

  List<Widget> _buildKpiColumn(DashboardData value) {
    final items = <Widget>[];
    if (value.calorias > 0) {
      items.addAll([
        KpiCard(
          title: 'Calorías hoy',
          value: '${value.calorias}',
          subtitle: 'Meta: 800 kcal',
          icon: Icons.local_fire_department_rounded,
          progress: (value.calorias / 800).clamp(0.0, 1.0),
          accentColor: SVColors.kpiCalorias,
        ),
        const SizedBox(height: 10),
      ]);
    }
    items.add(
      KpiCard(
        title: 'Sesiones completadas',
        value: '${value.sesiones}',
        subtitle: value.planSemanal != null
            ? '${value.sesionesRestantesSemana} restantes esta semana'
            : null,
        icon: Icons.fitness_center_rounded,
        progress: value.planSemanal != null
            ? (value.sesiones / value.planSemanal!.sesionesPlanificadas)
                .clamp(0.0, 1.0)
            : null,
        accentColor: SVColors.kpiSesiones,
      ),
    );
    return items;
  }

  Widget _buildKpiGrid(DashboardData value, bool isVeryWide) {
    final children = <Widget>[];
    if (value.calorias > 0) {
      children.add(
        KpiCard(
          title: 'Calorías hoy',
          value: '${value.calorias}',
          subtitle: 'Meta: 800 kcal',
          icon: Icons.local_fire_department_rounded,
          progress: (value.calorias / 800).clamp(0.0, 1.0),
          accentColor: SVColors.kpiCalorias,
        ),
      );
    }
    children.add(
      KpiCard(
        title: 'Sesiones completadas',
        value: '${value.sesiones}',
        subtitle: value.planSemanal != null
            ? '${value.sesionesRestantesSemana} restantes'
            : null,
        icon: Icons.fitness_center_rounded,
        accentColor: SVColors.kpiSesiones,
      ),
    );
    return GridView.count(
      crossAxisCount: children.length.clamp(1, 2),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isVeryWide ? 2.3 : 1.8,
      children: children,
    );
  }
}
