import 'package:flutter/material.dart';

import '../../domain/admin_auditoria_dto.dart';

/// Entrada de auditoria con diseno timeline moderno y profesional.
///
/// Columna lateral con punto coloreado por severidad y lineas conectoras,
/// tarjeta de contenido con chip de severidad, admin, accion y hora.
class AdminLogEntry extends StatelessWidget {
  const AdminLogEntry({
    required this.registro,
    this.esPrimero = false,
    this.esUltimo = false,
    super.key,
  });

  final AuditoriaRegistro registro;
  final bool esPrimero;
  final bool esUltimo;

  static String _traducirEntidad(String entidad) {
    switch (entidad) {
      case 'usuarios':
        return 'Usuario';
      case 'ejercicios':
        return 'Ejercicio';
      case 'actividades_sociales':
        return 'Publicacion';
      case 'comentarios_feed':
        return 'Comentario';
      case 'configuracion_global':
        return 'Config. Global';
      default:
        return entidad;
    }
  }

  Severidad _severidadParaAccion(String accion) {
    switch (accion) {
      case 'wipe':
      case 'eliminar_usuario':
      case 'anonimizar_usuario':
        return Severidad.critica;
      case 'activar_lockdown':
      case 'desactivar_lockdown':
      case 'reset_xp':
      case 'resetear_xp':
      case 'cambiar_nivel':
      case 'cambiar_rol':
        return Severidad.alta;
      case 'activar_shadowban':
      case 'desactivar_shadowban':
      case 'eliminar_contenido':
      case 'aprobar_contenido':
      case 'moderar':
        return Severidad.media;
      default:
        return Severidad.baja;
    }
  }

  static String _horaRelativa(DateTime fecha) {
    return '${fecha.day}/${fecha.month} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final severidad = _severidadParaAccion(registro.accion);
    final admin = registro.adminNombre ?? 'Admin';
    final entidadTraducida = _traducirEntidad(registro.entidad);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                if (!esPrimero)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _colorSeveridad(severidad).withValues(alpha: 0.15),
                    ),
                  ),
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: _colorSeveridad(severidad),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color:
                            _colorSeveridad(severidad).withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!esUltimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _colorSeveridad(severidad).withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 6),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _colorSeveridad(severidad).withValues(alpha: 0.1),
                  ),
                ),
                color: severidad == Severidad.critica
                    ? const Color(0xFFC0392B).withValues(alpha: 0.03)
                    : cs.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildChipSeveridad(severidad),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              admin,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _horaRelativa(registro.creadoEn),
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatearAccion(registro.accion)} $entidadTraducida',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      if (registro.detalle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatearDetalle(registro.detalle),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearAccion(String accion) {
    switch (accion) {
      case 'wipe':
        return 'Wipeo de datos de';
      case 'eliminar_usuario':
        return 'Elimino';
      case 'reset_xp':
      case 'resetear_xp':
        return 'Reseteo XP de';
      case 'cambiar_nivel':
        return 'Cambio nivel de';
      case 'cambiar_rol':
        return 'Cambio rol de';
      case 'eliminar_contenido':
        return 'Elimino';
      case 'aprobar_contenido':
        return 'Aprobo';
      case 'toggle_ejercicio':
        return 'Cambio estado de';
      case 'editar_ejercicio':
        return 'Edito';
      case 'activar_shadowban':
        return 'Shadowban activado en';
      case 'desactivar_shadowban':
        return 'Shadowban desactivado en';
      case 'activar_lockdown':
        return 'Modo Panico ACTIVADO';
      case 'desactivar_lockdown':
        return 'Modo Panico desactivado';
      case 'anonimizar_usuario':
        return 'Usuario anonimizado';
      case 'actualizar_nombre':
        return 'Cambio nombre de';
      case 'actualizar_email':
        return 'Cambio email de';
      default:
        return accion;
    }
  }

  Widget _buildChipSeveridad(Severidad severidad) {
    final color = _colorSeveridad(severidad);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        _etiquetaSeveridad(severidad),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatearDetalle(Map<String, dynamic> detalle) {
    final partes = <String>[];
    detalle.forEach((k, v) {
      if (v != null) partes.add('$k: $v');
    });
    return partes.join(' | ');
  }

  Color _colorSeveridad(Severidad s) {
    switch (s) {
      case Severidad.critica:
        return const Color(0xFFC0392B);
      case Severidad.alta:
        return const Color(0xFFE67E22);
      case Severidad.media:
        return const Color(0xFFF39C12);
      case Severidad.baja:
        return const Color(0xFF5D6D7E);
    }
  }

  String _etiquetaSeveridad(Severidad s) {
    switch (s) {
      case Severidad.critica:
        return 'CRÍTICO';
      case Severidad.alta:
        return 'ALTO';
      case Severidad.media:
        return 'MEDIO';
      case Severidad.baja:
        return 'INFO';
    }
  }
}

enum Severidad { critica, alta, media, baja }
