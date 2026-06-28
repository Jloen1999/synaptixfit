import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../../shared/models/db_models.dart';
import '../application/apuntes_asignatura_provider.dart';
import '../application/apuntes_provider.dart';
import '../application/conteos_asignatura_provider.dart';
import '../domain/fuente_estudio.dart';
import 'asignatura_detalle_screen.dart';
import 'widgets/asistente_ia_sheet.dart';

/// Formatos de descarga ofrecidos para un apunte Markdown.
enum _FormatoExport { markdown, texto, html }

extension _FormatoExportX on _FormatoExport {
  String get extension => switch (this) {
        _FormatoExport.markdown => 'md',
        _FormatoExport.texto => 'txt',
        _FormatoExport.html => 'html',
      };

  String get etiqueta => switch (this) {
        _FormatoExport.markdown => 'Markdown',
        _FormatoExport.texto => 'Texto plano',
        _FormatoExport.html => 'HTML',
      };

  String get descripcion => switch (this) {
        _FormatoExport.markdown => 'Formato original (.md)',
        _FormatoExport.texto => 'Sin formato (.txt)',
        _FormatoExport.html => 'Página web con estilos (.html)',
      };

  IconData get icono => switch (this) {
        _FormatoExport.markdown => Icons.notes_rounded,
        _FormatoExport.texto => Icons.text_snippet_outlined,
        _FormatoExport.html => Icons.language_rounded,
      };
}

/// Visor de apuntes en MODO LECTURA con estética Clean UI.
///
/// Renderiza el Markdown ya formateado (solo lectura, seleccionable) y ofrece
/// acciones de editar, descargar (en varios formatos) y eliminar.
class ApunteVisorScreen extends ConsumerStatefulWidget {
  const ApunteVisorScreen({required this.apunte, super.key});

  final ApunteDb apunte;

  @override
  ConsumerState<ApunteVisorScreen> createState() => _ApunteVisorScreenState();
}

class _ApunteVisorScreenState extends ConsumerState<ApunteVisorScreen> {
  bool _procesando = false;

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _editar(ApunteDb apunte) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EditorApunteScreen(
          asignaturaId: apunte.asignaturaId ?? '',
          existente: apunte,
        ),
      ),
    );
    if (guardado == true && mounted) {
      ref.invalidate(apunteDetalleProvider(apunte.id));
      ref.invalidate(apuntesProvider);
      final asigId = apunte.asignaturaId;
      if (asigId != null) {
        ref.invalidate(apuntesPorAsignaturaProvider(asigId));
        ref.invalidate(conteosAsignaturaProvider(asigId));
      }
    }
  }

  Future<void> _eliminar(ApunteDb apunte) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SVColors.surfaceContainerLowest,
        title: const Text('Eliminar apunte',
            style: TextStyle(color: SVColors.onSurface)),
        content: Text(
          '¿Eliminar «${apunte.titulo}»? Esta acción no se puede deshacer.',
          style: const TextStyle(color: SVColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: SVColors.error))),
        ],
      ),
    );
    if (confirma != true) return;

    setState(() => _procesando = true);
    try {
      await eliminarApunte(apunte.id);
      if (!mounted) return;
      ref.invalidate(apuntesProvider);
      final asigId = apunte.asignaturaId;
      if (asigId != null) {
        ref.invalidate(apuntesPorAsignaturaProvider(asigId));
        ref.invalidate(conteosAsignaturaProvider(asigId));
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      _snack('No se pudo eliminar: $e', error: true);
    }
  }

  Future<void> _mostrarDescarga(ApunteDb apunte) async {
    final formato = await showModalBottomSheet<_FormatoExport>(
      context: context,
      backgroundColor: SVColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SVColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Descargar apunte',
                    style: TextStyle(
                        color: SVColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            for (final f in _FormatoExport.values)
              ListTile(
                leading: Icon(f.icono, color: SVColors.primary),
                title: Text(f.etiqueta,
                    style: const TextStyle(
                        color: SVColors.onSurface,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(f.descripcion,
                    style: const TextStyle(
                        color: SVColors.onSurfaceMuted, fontSize: 12)),
                onTap: () => Navigator.pop(context, f),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (formato == null) return;
    await _exportar(apunte, formato);
  }

  Future<void> _exportar(ApunteDb apunte, _FormatoExport formato) async {
    final contenido = switch (formato) {
      _FormatoExport.markdown => apunte.contenido,
      _FormatoExport.texto => _aTextoPlano(apunte.contenido),
      _FormatoExport.html => _aHtml(apunte.titulo, apunte.contenido),
    };
    final bytes = Uint8List.fromList(utf8.encode(contenido));
    final nombre = '${_sanitizar(apunte.titulo)}.${formato.extension}';

    setState(() => _procesando = true);
    try {
      final ruta = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar apunte',
        fileName: nombre,
        bytes: bytes,
      );
      if (!mounted) return;
      if (ruta != null) {
        _snack('Apunte descargado como ${formato.etiqueta}');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('No se pudo descargar: $e', error: true);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? SVColors.error : null,
      ),
    );
  }

  // ── Conversores de formato ───────────────────────────────────────────────

  /// Convierte Markdown a texto plano legible (elimina la sintaxis).
  String _aTextoPlano(String src) {
    var t = src;
    t = t.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '• ');
    t = t.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    t = t.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!);
    t = t.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!);
    t = t.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m[1]!);
    t = t.replaceAll(RegExp(r'^\s*---\s*$', multiLine: true), '');
    return t.trim();
  }

  /// Convierte Markdown a un documento HTML autónomo con estilos básicos.
  String _aHtml(String titulo, String contenidoMd) {
    final cuerpo = md.markdownToHtml(
      contenidoMd,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    final tituloSeguro = const HtmlEscape().convert(titulo);
    return '''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$tituloSeguro</title>
<style>
  body { font-family: -apple-system, system-ui, "Segoe UI", Roboto, sans-serif;
         max-width: 720px; margin: 2rem auto; padding: 0 1rem;
         line-height: 1.7; color: #181C1E; }
  h1, h2, h3 { line-height: 1.25; }
  code { background: #eef1f5; padding: .15em .35em; border-radius: 4px;
         font-family: ui-monospace, monospace; }
  pre { background: #eef1f5; padding: 1rem; border-radius: 8px; overflow: auto; }
  blockquote { border-left: 3px solid #002546; margin: 0; padding: .2rem 1rem;
               color: #42474F; }
  hr { border: none; border-top: 1px solid #C3C6D0; }
</style>
</head>
<body>
<h1>$tituloSeguro</h1>
$cuerpo
</body>
</html>''';
  }

  /// Limpia el título para usarlo como nombre de archivo.
  String _sanitizar(String titulo) {
    final limpio = titulo
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return limpio.isEmpty ? 'apunte' : limpio;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final apunteAsync = ref.watch(apunteDetalleProvider(widget.apunte.id));
    final apunte = apunteAsync.valueOrNull ?? widget.apunte;
    final fecha =
        DateFormat("d 'de' MMMM yyyy", 'es').format(apunte.actualizadoEn);

    return Scaffold(
      backgroundColor: SVColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: SVColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SVColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: const Text(
          'Apunte',
          style: TextStyle(
            color: SVColors.onSurfaceMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          if (apunte.contenido.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined,
                  color: SVColors.primary),
              tooltip: 'Asistente IA',
              onPressed: _procesando
                  ? null
                  : () => mostrarAsistenteIa(
                        context,
                        FuenteTexto(
                          titulo: apunte.titulo,
                          fuenteId: apunte.id,
                          asignaturaId: apunte.asignaturaId,
                          contenido: apunte.contenido,
                        ),
                      ),
            ),
          IconButton(
            icon: const Icon(Icons.download_outlined,
                color: SVColors.onSurfaceVariant),
            tooltip: 'Descargar',
            onPressed: _procesando ? null : () => _mostrarDescarga(apunte),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: SVColors.onSurfaceVariant),
            tooltip: 'Editar',
            onPressed: _procesando ? null : () => _editar(apunte),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: SVColors.error),
            tooltip: 'Eliminar',
            onPressed: _procesando ? null : () => _eliminar(apunte),
          ),
          const SizedBox(width: 4),
        ],
        bottom: _procesando
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                apunte.titulo,
                style: const TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: SVColors.onSurfaceMuted),
                  const SizedBox(width: 6),
                  Text(
                    fecha,
                    style: const TextStyle(
                        color: SVColors.onSurfaceMuted, fontSize: 12.5),
                  ),
                  const SizedBox(width: 10),
                  _VisibilidadChip(visibilidad: apunte.visibilidad),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: SVColors.outlineVariant),
              const SizedBox(height: 16),
              if (apunte.contenido.trim().isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Este apunte no tiene contenido.',
                      style: TextStyle(
                          color: SVColors.onSurfaceMuted, fontSize: 14),
                    ),
                  ),
                )
              else
                MarkdownBody(
                  data: apunte.contenido,
                  selectable: true,
                  styleSheet: _estiloMarkdown(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _estiloMarkdown(BuildContext context) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(
          color: SVColors.onSurface, fontSize: 15.5, height: 1.7),
      h1: const TextStyle(
          color: SVColors.onSurface,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          height: 1.3),
      h2: const TextStyle(
          color: SVColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.3),
      h3: const TextStyle(
          color: SVColors.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.3),
      listBullet: const TextStyle(
          color: SVColors.onSurface, fontSize: 15.5, height: 1.7),
      blockquote: const TextStyle(
          color: SVColors.onSurfaceVariant, fontSize: 15, height: 1.6),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
      blockquoteDecoration: BoxDecoration(
        color: SVColors.surfaceContainerLow,
        borderRadius: SVShapes.standard,
        border: Border(
          left: BorderSide(
              color: SVColors.primary.withValues(alpha: 0.4), width: 3),
        ),
      ),
      code: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: SVColors.onSurfaceVariant,
        backgroundColor: SVColors.surfaceContainerHighest,
      ),
      codeblockPadding: const EdgeInsets.all(14),
      codeblockDecoration: const BoxDecoration(
        color: SVColors.surfaceContainerLow,
        borderRadius: SVShapes.standard,
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: SVColors.outlineVariant, width: 1),
        ),
      ),
    );
  }
}

class _VisibilidadChip extends StatelessWidget {
  const _VisibilidadChip({required this.visibilidad});

  final String visibilidad;

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (visibilidad) {
      'public' => ('Público', SVColors.secondary),
      'solo_amigos' => ('Amigos', SVColors.accent),
      _ => ('Privado', SVColors.onSurfaceMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: SVShapes.pill,
      ),
      child: Text(
        texto,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
