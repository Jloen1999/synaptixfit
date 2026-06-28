// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../models/db_models.dart';
import '../../core/design_system/sv_colors.dart';
import '../../features/bienestar/application/rutina_provider.dart';

// ---------------------------------------------------------------------------
// Helpers reutilizables de color y construcción
// ---------------------------------------------------------------------------

Color colorParaScore(double v) {
  if (v < 30) return SVColors.error;
  if (v < 50) return const Color(0xFFE8A838);
  if (v < 70) return const Color(0xFFF5A623);
  return SVColors.secondary;
}

Widget buildFormulaBar(
    BuildContext ctx, String title, IconData icon, List<Widget> items,
    {String? formula,
    List<({String label, double pct, Color color})>? barItems}) {
  final cs = Theme.of(ctx).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest.withAlpha(80),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
          ],
        ),
        if (barItems != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 24,
              child: Row(
                children: barItems.map((item) {
                  return Expanded(
                    flex: (item.pct * 100).round().clamp(1, 100),
                    child: Container(color: item.color),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        ...items,
        if (formula != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(6)),
            child: Text(formula,
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontFamily: 'DM Sans',
                    height: 1.5)),
          ),
        ],
      ],
    ),
  );
}

Widget buildCalcRow(
    BuildContext ctx, String label, double raw, double contrib, Color color) {
  final cs = Theme.of(ctx).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 45,
          child: Text(
            raw.toStringAsFixed(0),
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(
          width: 45,
          child: Text(
            contrib.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

Widget buildGateRow(BuildContext ctx, IconData icon, String name,
    String thresholdLabel, String ruleText, int? value, double? multiplier) {
  final active = multiplier != null && multiplier < 1.0;
  final chipColor = active ? const Color(0xFFBA1A1A) : const Color(0xFF2E7D32);
  final chipBg = active
      ? const Color(0xFFBA1A1A).withAlpha(20)
      : const Color(0xFF2E7D32).withAlpha(15);
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFBA1A1A).withAlpha(180)),
        const SizedBox(width: 5),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFBA1A1A).withAlpha(220))),
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A).withAlpha(12),
                    borderRadius: BorderRadius.circular(3)),
                child: Text('$thresholdLabel → $ruleText',
                    style: TextStyle(
                        fontSize: 9,
                        color: const Color(0xFFBA1A1A).withAlpha(160))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (value != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: chipBg, borderRadius: BorderRadius.circular(4)),
                  child: Text('$value/5',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: chipColor)),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A).withAlpha(10),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('—',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFBA1A1A).withAlpha(80))),
                ),
              const SizedBox(width: 4),
              if (multiplier != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: chipBg, borderRadius: BorderRadius.circular(4)),
                  child: Text('×${multiplier.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: chipColor)),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A).withAlpha(10),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('×?',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFBA1A1A).withAlpha(80))),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildStatCard(
    BuildContext ctx, String label, String value, IconData icon) {
  final cs = Theme.of(ctx).colorScheme;
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest.withAlpha(80),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Diálogos del dashboard
// ---------------------------------------------------------------------------

void mostrarDialogoEnergia(BuildContext context, EnergiaComponentes? comp) {
  final cs = Theme.of(context).colorScheme;
  final valor = comp?.valor ?? 0;
  final color = colorParaScore(valor.toDouble());
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Estado Energético',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${valor.round()}/100',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              buildFormulaBar(
                  ctx,
                  'Como se calcula',
                  Icons.functions_rounded,
                  [
                    buildCalcRow(
                      ctx,
                      'Energia diaria',
                      comp != null ? comp.eDiaria / 5.0 * 100 : 0,
                      comp?.contribE ?? 0,
                      const Color(0xFF2196F3),
                    ),
                    buildCalcRow(
                      ctx,
                      'Calidad del sueño',
                      comp != null ? comp.eSueno / 5.0 * 100 : 0,
                      comp?.contribS ?? 0,
                      const Color(0xFF7C4DFF),
                    ),
                    buildCalcRow(
                      ctx,
                      'Recuperacion fisica',
                      comp != null ? comp.eRecup / 5.0 * 100 : 0,
                      comp?.contribR ?? 0,
                      const Color(0xFF009688),
                    ),
                    buildCalcRow(
                      ctx,
                      'Descarga cognitiva',
                      comp?.eCog ?? 0,
                      comp?.contribC ?? 0,
                      const Color(0xFFE8A838),
                    ),
                    buildCalcRow(
                      ctx,
                      'Manejo del estres',
                      comp?.eEstres ?? 0,
                      comp?.contribEs ?? 0,
                      const Color(0xFF78909C),
                    ),
                  ],
                  formula:
                      'energía×30% + sueño×25% + recup×20% + cognitiva×15% + estrés×10%',
                  barItems: [
                    (
                      label: 'Energía',
                      pct: 0.30,
                      color: const Color(0xFF2196F3)
                    ),
                    (label: 'Sueño', pct: 0.25, color: const Color(0xFF7C4DFF)),
                    (
                      label: 'Recuperación',
                      pct: 0.20,
                      color: const Color(0xFF009688)
                    ),
                    (
                      label: 'Cognitiva',
                      pct: 0.15,
                      color: const Color(0xFFE8A838)
                    ),
                    (
                      label: 'Estrés',
                      pct: 0.10,
                      color: const Color(0xFF78909C)
                    ),
                  ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: cs.primaryContainer.withAlpha(30),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                    comp != null
                        ? '${comp.base.toStringAsFixed(1)} × ${comp.gateS} × ${comp.gateR} × ${comp.gateE} = ${comp.valor.round()}/100'
                        : 'Sin datos de check-in diario.\nRegistra tu estado para ver tu energía real.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.primary)),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A).withAlpha(12),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Color(0xFFBA1A1A)),
                        SizedBox(width: 6),
                        Text('Penalizadores',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFBA1A1A))),
                      ]),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          SizedBox(width: 18),
                          Expanded(
                              flex: 3,
                              child: Text('Regla del gate',
                                  style: TextStyle(
                                      fontSize: 8, color: Color(0x80BA1A1A)))),
                          SizedBox(width: 6),
                          Expanded(
                              flex: 2,
                              child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('Tu valor',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0x80BA1A1A))))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      comp != null
                          ? Column(children: [
                              buildGateRow(
                                  ctx,
                                  Icons.bedtime_rounded,
                                  'Sueño',
                                  '≤2/5',
                                  '×0,40 / ×0,70',
                                  comp.eSueno,
                                  comp.gateS),
                              buildGateRow(
                                  ctx,
                                  Icons.healing_rounded,
                                  'Dolor',
                                  '≤2/5',
                                  '×0,60 / ×0,85',
                                  comp.eRecup,
                                  comp.gateR),
                              buildGateRow(
                                  ctx,
                                  Icons.bolt_rounded,
                                  'Energía',
                                  '≤2/5',
                                  '×0,50 / ×0,75',
                                  comp.eDiaria,
                                  comp.gateE),
                            ])
                          : Column(children: [
                              buildGateRow(ctx, Icons.bedtime_rounded, 'Sueño',
                                  '≤2/5', '×0,40 / ×0,70', null, null),
                              buildGateRow(ctx, Icons.healing_rounded, 'Dolor',
                                  '≤2/5', '×0,60 / ×0,85', null, null),
                              buildGateRow(ctx, Icons.bolt_rounded, 'Energía',
                                  '≤2/5', '×0,50 / ×0,75', null, null),
                            ]),
                    ]),
              ),
              if (comp != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    valor.round() < 30
                        ? 'Crítico — priorizar descanso.'
                        : valor.round() < 50
                            ? 'Bajo — reducir intensidad.'
                            : valor.round() < 70
                                ? 'Moderado — entrenar con precaución.'
                                : 'Bueno — rendimiento óptimo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void mostrarDialogoAdherencia(
    BuildContext context, AdherenciaComponentes? comp) {
  final cs = Theme.of(context).colorScheme;
  final valor = (comp?.valor ?? 0).round();
  final color = colorParaScore(comp?.valor ?? 0);
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12)),
                  child:
                      Icon(Icons.auto_awesome_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Adherencia academica',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface))),
                Text('$valor/100',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ]),
              const SizedBox(height: 20),
              buildFormulaBar(
                  ctx,
                  'Como se calcula',
                  Icons.functions_rounded,
                  [
                    buildCalcRow(
                        ctx,
                        'Cumplimiento de horas',
                        comp != null ? comp.cumplimientoHoras * 100 : 0,
                        comp?.contribH ?? 0,
                        const Color(0xFF2196F3)),
                    buildCalcRow(
                        ctx,
                        'Tareas y evaluaciones',
                        comp != null ? comp.completitudTareas * 100 : 0,
                        comp?.contribT ?? 0,
                        const Color(0xFF009688)),
                    buildCalcRow(
                        ctx,
                        'Racha de estudio',
                        comp != null ? comp.rachaDias * 100 : 0,
                        comp?.contribR ?? 0,
                        const Color(0xFFE8A838)),
                  ],
                  formula:
                      '= cumplimiento horas × 60% + tareas × 30% + racha × 10%',
                  barItems: [
                    (label: 'Horas', pct: 0.60, color: const Color(0xFF2196F3)),
                    (
                      label: 'Tareas',
                      pct: 0.30,
                      color: const Color(0xFF009688)
                    ),
                    (label: 'Racha', pct: 0.10, color: const Color(0xFFE8A838)),
                  ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  comp != null
                      ? '${comp.contribH.toStringAsFixed(1)} + ${comp.contribT.toStringAsFixed(1)} + ${comp.contribR.toStringAsFixed(1)} = ${comp.valor.round()}/100'
                      : 'Sin datos de carga académica.\nSincroniza tu plan de estudio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.primary),
                ),
              ),
              if (comp != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          'Mide solo disciplina académica (sueño y estrés no afectan)',
                          style: TextStyle(
                              fontSize: 10, color: cs.onSurfaceVariant)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                      comp.valor < 40
                          ? 'Baja — requiere atención.'
                          : comp.valor < 70
                              ? 'En progreso — buena dirección.'
                              : 'Alta — excelente disciplina.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void mostrarDialogoEstudio(
    BuildContext context, CargaAcademicaSemanalDb carga) {
  final cs = Theme.of(context).colorScheme;
  final pct = (carga.horasEstudioReales /
          carga.horasEstudioPlaneadas.clamp(1, 120) *
          100)
      .clamp(0, 100);
  final color = colorParaScore(pct.toDouble());
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timer_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Progreso de Estudio',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${pct.round()}/100',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: buildStatCard(ctx, 'Horas reales',
                        '${carga.horasEstudioReales}h', Icons.timer_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildStatCard(ctx, 'Planeadas',
                        '${carga.horasEstudioPlaneadas}h', Icons.event_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildStatCard(
                        ctx,
                        'Evaluaciones',
                        '${carga.evaluacionesSemana}',
                        Icons.assignment_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildStatCard(ctx, 'Entregas',
                        '${carga.entregasSemana}', Icons.task_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  pct >= 80
                      ? 'Meta semanal cumplida — +150 XP otorgado.'
                      : 'Por debajo del 80% de la meta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void mostrarDialogoConsejo(BuildContext context, String texto) {
  final cs = Theme.of(context).colorScheme;
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF7C4DFF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Consejo del día',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
