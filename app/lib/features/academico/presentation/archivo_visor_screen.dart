import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../domain/archivo_asignatura_dto.dart';
import '../domain/fuente_estudio.dart';
import 'widgets/asistente_ia_sheet.dart';

/// Visor completo de archivos (Clean UI — fondo claro).
///
/// Soporta previsualización en-app de imágenes y PDFs, más apertura externa
/// para cualquier tipo de archivo.
class ArchivoVisorScreen extends StatefulWidget {
  const ArchivoVisorScreen({required this.archivo, super.key});

  final ArchivoAsignaturaDto archivo;

  @override
  State<ArchivoVisorScreen> createState() => _ArchivoVisorScreenState();
}

class _ArchivoVisorScreenState extends State<ArchivoVisorScreen> {
  // Nullable (NO `late`): durante la carga asíncrona del PDF, `build` lee este
  // campo antes de asignarlo. Con `late final` eso lanzaba un
  // LateInitializationError temporal. Como nullable arranca en null y se asigna
  // tras la descarga; `dispose` y `build` lo tratan de forma segura.
  pdfx.PdfController? _pdfController;
  bool _pdfCargando = true;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    if (widget.archivo.tipo == TipoArchivo.pdf) {
      _iniciarPdf();
    }
  }

  Future<void> _iniciarPdf() async {
    try {
      final response = await Dio().get<List<int>>(
        widget.archivo.urlPublica,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data == null) throw Exception('Respuesta vacía');
      if (!mounted) return;
      final bytes = Uint8List.fromList(response.data!);
      final document = pdfx.PdfDocument.openData(bytes);
      setState(() {
        _pdfController = pdfx.PdfController(document: document);
        _pdfCargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pdfError = 'No se pudo cargar el PDF: $e';
        _pdfCargando = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _abrirExternamente() async {
    final uri = Uri.parse(widget.archivo.urlPublica);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No se encontró una aplicación para abrir este archivo.'),
        ),
      );
    }
  }

  /// Devuelve el mimeType si el archivo puede analizarse con IA (PDF o imagen,
  /// los tipos que Gemini soporta de forma multimodal); null en caso contrario.
  String? _mimeIaSoportado() {
    final nombre = widget.archivo.nombreArchivo;
    final ext =
        nombre.contains('.') ? nombre.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => null,
    };
  }

  void _asistenteIa(String mime) {
    mostrarAsistenteIa(
      context,
      FuenteArchivo(
        titulo: widget.archivo.nombreArchivo,
        fuenteId: widget.archivo.id,
        asignaturaId: widget.archivo.asignaturaId,
        url: widget.archivo.urlPublica,
        mimeType: mime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.archivo;
    final tipo = a.tipo;
    final color = tipo.color;
    final iaMime = _mimeIaSoportado();

    return Scaffold(
      backgroundColor: SVColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _BarraSuperior(
              nombre: a.nombreArchivo,
              tamano: a.tamanoLegible,
              color: color,
              onAbrirExternamente: _abrirExternamente,
              onIa: iaMime != null ? () => _asistenteIa(iaMime) : null,
            ),
            Expanded(child: _buildContenido(tipo, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(TipoArchivo tipo, Color color) {
    switch (tipo) {
      case TipoArchivo.imagen:
        return _VisorImagen(url: widget.archivo.urlPublica);
      case TipoArchivo.pdf:
        return _VisorPdf(
          controller: _pdfController,
          cargando: _pdfCargando,
          error: _pdfError,
          onReintentar: _iniciarPdf,
        );
      default:
        return _TarjetaArchivoExterno(
          archivo: widget.archivo,
          color: color,
          onAbrir: _abrirExternamente,
        );
    }
  }
}

// ── Barra superior ──────────────────────────────────────────────────────

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({
    required this.nombre,
    required this.tamano,
    required this.color,
    required this.onAbrirExternamente,
    this.onIa,
  });

  final String nombre;
  final String tamano;
  final Color color;
  final VoidCallback onAbrirExternamente;
  final VoidCallback? onIa;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: SVColors.onSurface),
            tooltip: 'Volver',
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: SVShapes.standard,
            ),
            child: Icon(
              TipoArchivo.desdeNombre(nombre).icono,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  tamano,
                  style: const TextStyle(
                    color: SVColors.onSurfaceMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (onIa != null)
            IconButton(
              onPressed: onIa,
              icon: const Icon(Icons.auto_awesome_outlined,
                  color: SVColors.primary),
              tooltip: 'Asistente IA',
            ),
          IconButton(
            onPressed: onAbrirExternamente,
            icon: const Icon(Icons.open_in_new, color: SVColors.onSurface),
            tooltip: 'Abrir externamente',
          ),
        ],
      ),
    );
  }
}

// ── Visor de imágenes ───────────────────────────────────────────────────

class _VisorImagen extends StatelessWidget {
  const _VisorImagen({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (_, __, ___) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined,
                    size: 48, color: SVColors.onSurfaceMuted),
                SizedBox(height: 10),
                Text(
                  'No se pudo cargar la imagen',
                  style: TextStyle(color: SVColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Visor de PDF ────────────────────────────────────────────────────────

class _VisorPdf extends StatelessWidget {
  const _VisorPdf({
    required this.controller,
    required this.cargando,
    this.error,
    this.onReintentar,
  });

  final pdfx.PdfController? controller;
  final bool cargando;
  final String? error;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 14),
            Text(
              'Cargando PDF…',
              style: TextStyle(color: SVColors.onSurfaceMuted),
            ),
          ],
        ),
      );
    }

    if (error != null || controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: SVColors.error),
              const SizedBox(height: 10),
              Text(
                error ?? 'Error al cargar el PDF.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SVColors.onSurfaceMuted),
              ),
              if (onReintentar != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onReintentar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return pdfx.PdfView(
      controller: controller!,
      scrollDirection: Axis.vertical,
    );
  }
}

// ── Tarjeta de archivo externo ──────────────────────────────────────────

class _TarjetaArchivoExterno extends StatelessWidget {
  const _TarjetaArchivoExterno({
    required this.archivo,
    required this.color,
    required this.onAbrir,
  });

  final ArchivoAsignaturaDto archivo;
  final Color color;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final tipo = archivo.tipo;
    final fecha = _formatearFecha(archivo.creadoEn);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(tipo.icono, color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              archivo.nombreArchivo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${archivo.tamanoLegible} · $fecha',
              style: const TextStyle(
                color: SVColors.onSurfaceMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _chipInfo(
                  icono: Icons.storage_outlined,
                  texto: archivo.tamanoLegible,
                  color: color,
                ),
                const SizedBox(width: 8),
                _chipInfo(
                  icono: Icons.calendar_today_outlined,
                  texto: fecha,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAbrir,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: SVColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: SVShapes.standard12,
                  ),
                ),
                icon: const Icon(Icons.open_in_new, size: 20),
                label: const Text(
                  'Abrir con aplicación externa',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _descripcionTipo(tipo),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SVColors.onSurfaceMuted,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo({
    required IconData icono,
    required String texto,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: SVShapes.standard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static String _descripcionTipo(TipoArchivo tipo) {
    return switch (tipo) {
      TipoArchivo.pdf => 'Los archivos PDF se muestran en el visor integrado.',
      TipoArchivo.imagen =>
        'Las imágenes se muestran con zoom y desplazamiento táctil.',
      TipoArchivo.presentacion =>
        'Las presentaciones se abren con la aplicación predeterminada.',
      TipoArchivo.hojaCalculo =>
        'Las hojas de cálculo se abren con la aplicación predeterminada.',
      TipoArchivo.documento =>
        'Los documentos se abren con la aplicación predeterminada.',
      TipoArchivo.comprimido =>
        'Los archivos comprimidos se abren con la aplicación predeterminada.',
      TipoArchivo.otro =>
        'Este tipo de archivo se abre con la aplicación predeterminada.',
    };
  }

  static String _formatearFecha(DateTime fecha) {
    final meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }
}
