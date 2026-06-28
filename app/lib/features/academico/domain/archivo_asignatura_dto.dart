import 'package:flutter/material.dart';

/// Categoría semántica de un archivo adjunto, derivada de su extensión.
/// Determina el icono y el color tenue del micro-chip en la pestaña Archivos.
enum TipoArchivo {
  pdf,
  imagen,
  presentacion,
  hojaCalculo,
  documento,
  comprimido,
  otro;

  /// Deriva el tipo a partir del nombre de archivo o su extensión.
  static TipoArchivo desdeNombre(String nombre) {
    final ext = nombre.contains('.')
        ? nombre.split('.').last.toLowerCase()
        : nombre.toLowerCase();
    switch (ext) {
      case 'pdf':
        return TipoArchivo.pdf;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'heic':
      case 'bmp':
        return TipoArchivo.imagen;
      case 'ppt':
      case 'pptx':
      case 'key':
      case 'odp':
        return TipoArchivo.presentacion;
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ods':
        return TipoArchivo.hojaCalculo;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
      case 'rtf':
      case 'odt':
        return TipoArchivo.documento;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return TipoArchivo.comprimido;
      default:
        return TipoArchivo.otro;
    }
  }

  IconData get icono => switch (this) {
        TipoArchivo.pdf => Icons.picture_as_pdf,
        TipoArchivo.imagen => Icons.image_outlined,
        TipoArchivo.presentacion => Icons.slideshow_outlined,
        TipoArchivo.hojaCalculo => Icons.table_chart_outlined,
        TipoArchivo.documento => Icons.description_outlined,
        TipoArchivo.comprimido => Icons.folder_zip_outlined,
        TipoArchivo.otro => Icons.insert_drive_file_outlined,
      };

  /// Color semántico tenue (Flat Design) según el tipo de archivo.
  Color get color => switch (this) {
        TipoArchivo.pdf => const Color(0xFFE57373),
        TipoArchivo.imagen => const Color(0xFF81C784),
        TipoArchivo.presentacion => const Color(0xFFFFB74D),
        TipoArchivo.hojaCalculo => const Color(0xFF4DB6AC),
        TipoArchivo.documento => const Color(0xFF64B5F6),
        TipoArchivo.comprimido => const Color(0xFFBA9DDB),
        TipoArchivo.otro => const Color(0xFF90A4AE),
      };
}

/// DTO de un archivo de asignatura. Los metadatos viven en Supabase
/// (`archivos_asignatura`); el binario físico vive en Cloudflare R2.
class ArchivoAsignaturaDto {
  const ArchivoAsignaturaDto({
    required this.id,
    required this.usuarioId,
    required this.asignaturaId,
    required this.nombreArchivo,
    required this.cloudflareObjectKey,
    required this.urlPublica,
    required this.tamanoBytes,
    this.tipoMime,
    required this.creadoEn,
  });

  final String id;
  final String usuarioId;
  final String asignaturaId;
  final String nombreArchivo;
  final String cloudflareObjectKey;
  final String urlPublica;
  final int tamanoBytes;
  final String? tipoMime;
  final DateTime creadoEn;

  TipoArchivo get tipo => TipoArchivo.desdeNombre(nombreArchivo);

  /// Tamaño legible para humanos (B / KB / MB / GB).
  String get tamanoLegible {
    if (tamanoBytes <= 0) return '—';
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (tamanoBytes >= gb) {
      return '${(tamanoBytes / gb).toStringAsFixed(1)} GB';
    }
    if (tamanoBytes >= mb) {
      return '${(tamanoBytes / mb).toStringAsFixed(1)} MB';
    }
    if (tamanoBytes >= kb) {
      return '${(tamanoBytes / kb).toStringAsFixed(0)} KB';
    }
    return '$tamanoBytes B';
  }

  factory ArchivoAsignaturaDto.fromMap(Map<String, dynamic> map) {
    return ArchivoAsignaturaDto(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      asignaturaId: map['asignatura_id'] as String,
      nombreArchivo: map['nombre_archivo'] as String,
      cloudflareObjectKey: map['cloudflare_object_key'] as String,
      urlPublica: map['url_publica_o_firmada'] as String,
      tamanoBytes: (map['tamano_bytes'] as num?)?.toInt() ?? 0,
      tipoMime: map['tipo_mime'] as String?,
      creadoEn: DateTime.parse(map['creado_en'] as String),
    );
  }
}
