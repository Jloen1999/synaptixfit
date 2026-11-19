import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../domain/models/academic/teaching_guide.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/academic_visuals.dart';
import 'guide_import_entry.dart';
import 'subject_tab_body.dart';

/// Pestaña Guía (ADR 0057): el profesorado (papel, despacho, tutorías y
/// «Escribir»), y plegados la bibliografía y los datos de la guía docente.
class GuideTab extends StatelessWidget {
  const GuideTab({super.key});

  @override
  Widget build(BuildContext context) => SubjectTabBody(
    children: (context, state) {
      final guide = state.guide;
      final l10n = context.localizations;
      if (guide == null) {
        return [
          GuideMissingView(
            subjectId: state.subjectId,
            icon: AppIcons.importGuide,
            title: l10n.academicGuideTabEmptyTitle,
            message: l10n.academicGuideTabEmptyMessage,
          ),
        ];
      }
      final data = _guideData(guide.info);
      return [
        if (guide.professors.isNotEmpty) ...[
          AppSectionHeader(title: l10n.academicGuideProfessors),
          for (final p in guide.professors) ...[
            ProfessorCard(professor: p),
            const SizedBox(height: TokensSpacing.s),
          ],
          const SizedBox(height: TokensSpacing.s),
        ],
        if (guide.bibliography.isNotEmpty) ...[
          _Fold(
            title: l10n.academicGuideBibliographyCount(
              guide.bibliography.length,
            ),
            children: [
              for (final item in guide.bibliography)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: TokensSize.iconXs,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: TokensSpacing.s),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        if (data.isNotEmpty) ...[
          _Fold(
            title: l10n.academicGuideData,
            children: [
              for (final line in data)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                  child: Text(line),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => reimportGuide(context, state.subjectId, guide),
            icon: const Icon(AppIcons.refresh),
            label: Text(l10n.academicGuideRegenerate),
          ),
        ),
      ];
    },
  );

  /// «Grado en Ingeniería Informática · Curso 2026-27 · Obligatoria» y, en
  /// otras líneas, centro, departamento y código, si la guía los trae.
  static List<String> _guideData(SubjectGuideInfo info) => [
    [
      ?info.degree,
      ?info.academicYear,
      if (info.character != null) sentenceCase(info.character!),
    ].join(' · '),
    [?info.center, ?info.university].join(' · '),
    ?info.department,
    ?info.code,
  ].where((line) => line.trim().isNotEmpty).toList();
}

/// Profesor de la guía: iniciales, nombre, papel, despacho, tutorías y
/// «Escribir» (abre el correo; sin email no hay botón).
class ProfessorCard extends StatelessWidget {
  const ProfessorCard({super.key, required this.professor});

  final Professor professor;

  Future<void> _write(BuildContext context, String email) async {
    final ok = await launchUrl(Uri(scheme: 'mailto', path: email));
    if (!ok && context.mounted) {
      context.showSnack(context.localizations.academicProfessorWriteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final p = professor;
    final email = p.email?.trim();
    final role = p.role?.trim();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: AppAvatar(name: p.name)),
              const SizedBox(width: TokensSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (role != null && role.isNotEmpty) ...[
                      const SizedBox(height: TokensSpacing.xxs),
                      AppPill(
                        label: role,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (p.office != null && p.office!.trim().isNotEmpty)
            _KeyValue(label: l10n.academicProfessorOffice, value: p.office!),
          if (p.officeHours != null && p.officeHours!.trim().isNotEmpty)
            _KeyValue(
              label: l10n.academicProfessorHours,
              value: p.officeHours!,
            ),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.s),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                container: true,
                button: true,
                excludeSemantics: true,
                label: l10n.academicProfessorWriteSpoken(p.name),
                // El lector oye a quién se escribe; el toque es el mismo.
                onTap: () => _write(context, email),
                child: AppSecondaryButton(
                  label: l10n.academicProfessorWrite,
                  icon: const Icon(AppIcons.email),
                  onPressed: () => _write(context, email),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: TokensSpacing.s),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
      style: context.textStyles.bodyMedium,
    ),
  );
}

/// Desplegable de la pestaña Guía (bibliografía, datos de la guía).
class _Fold extends StatelessWidget {
  const _Fold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: AppFocusOutline(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(title, style: context.textStyles.titleSmall),
        childrenPadding: const EdgeInsets.fromLTRB(
          TokensSpacing.m,
          0,
          TokensSpacing.m,
          TokensSpacing.s,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}
