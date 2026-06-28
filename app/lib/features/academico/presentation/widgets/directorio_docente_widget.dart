import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../domain/guia_docente_dto.dart';

class DirectorioDocenteWidget extends StatelessWidget {
  const DirectorioDocenteWidget({required this.profesores, super.key});

  final List<ProfesorGuia> profesores;

  @override
  Widget build(BuildContext context) {
    if (profesores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Directorio docente',
            style: TextStyle(
              color: SVColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 4),
            itemCount: profesores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = profesores[i];
              return _TarjetaProfesor(profesor: p);
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaProfesor extends StatelessWidget {
  const _TarjetaProfesor({required this.profesor});

  final ProfesorGuia profesor;

  Future<void> _abrirCorreo() async {
    final uri = Uri(
      scheme: 'mailto',
      path: profesor.email,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneDespacho = profesor.despacho.isNotEmpty;
    final tieneEmail = profesor.email.isNotEmpty;

    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        borderRadius: SVShapes.standard12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SVColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline,
                    size: 17, color: SVColors.primary),
              ),
              const Spacer(),
              if (tieneEmail)
                GestureDetector(
                  onTap: _abrirCorreo,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SVColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.mail_outline,
                        size: 17, color: SVColors.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Text(
              profesor.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          if (tieneDespacho) ...[
            const SizedBox(height: 3),
            Text(
              profesor.despacho,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SVColors.onSurfaceMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
