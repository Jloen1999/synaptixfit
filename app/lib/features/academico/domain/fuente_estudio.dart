import 'package:flutter/foundation.dart';

/// Fuente de estudio sobre la que el asistente de IA genera un resumen o un
/// mapa mental. Puede ser texto plano/Markdown (un apunte) o un archivo
/// (PDF o imagen) accesible por URL.
///
/// Lleva la identidad de la fuente ([fuenteTipo] + [fuenteId]) para poder
/// persistir y recuperar el documento generado (ver `DocumentoIaRepository`).
@immutable
sealed class FuenteEstudio {
  const FuenteEstudio({
    required this.titulo,
    required this.fuenteId,
    required this.fuenteTipo,
    this.asignaturaId,
  });

  /// Título legible de la fuente (nombre del apunte o del archivo).
  final String titulo;

  /// Id del apunte o del archivo de origen.
  final String fuenteId;

  /// 'apunte' | 'archivo'.
  final String fuenteTipo;

  /// Asignatura a la que pertenece la fuente (para agrupar los documentos).
  final String? asignaturaId;
}

/// Fuente de texto: el contenido ya está disponible en memoria (p. ej. el
/// cuerpo Markdown de un apunte).
class FuenteTexto extends FuenteEstudio {
  const FuenteTexto({
    required super.titulo,
    required super.fuenteId,
    super.asignaturaId,
    required this.contenido,
  }) : super(fuenteTipo: 'apunte');

  final String contenido;
}

/// Fuente de archivo: el binario se descarga desde [url] y se envía a la IA de
/// forma multimodal con su [mimeType] (PDF o imagen).
class FuenteArchivo extends FuenteEstudio {
  const FuenteArchivo({
    required super.titulo,
    required super.fuenteId,
    super.asignaturaId,
    required this.url,
    required this.mimeType,
  }) : super(fuenteTipo: 'archivo');

  final String url;
  final String mimeType;
}
