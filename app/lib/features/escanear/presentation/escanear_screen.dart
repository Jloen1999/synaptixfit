import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../academico/application/apuntes_provider.dart';
import '../../academico/application/asignaturas_provider.dart';
import '../application/escanear_provider.dart';

/// Pantalla de escaneo OCR.
///
/// En Web muestra un mensaje de no soportado.
/// En mobile ofrece un flujo simplificado: el usuario escribe/pega texto
/// y lo guarda como apunte.
class EscanearScreen extends ConsumerStatefulWidget {
  const EscanearScreen({super.key});

  @override
  ConsumerState<EscanearScreen> createState() => _EscanearScreenState();
}

class _EscanearScreenState extends ConsumerState<EscanearScreen> {
  final _textoCtrl = TextEditingController();
  String? _asignaturaId;

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebFallback(context);
    }
    return _buildMobileFlow(context);
  }

  /// Mensaje para plataforma Web indicando que requiere app movil.
  Widget _buildWebFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear apunte'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 80,
                color: theme.colorScheme.primary.withAlpha(100),
              ),
              const SizedBox(height: 24),
              Text(
                'Escanear requiere la app movil (Android/iOS). '
                'Descargala para usar esta funcion.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Flujo simplificado para mobile sin dependencia de camara.
  Widget _buildMobileFlow(BuildContext context) {
    final escanearState = ref.watch(escanearProvider);
    final asignaturasAsync = ref.watch(asignaturasActivasProvider);

    return FeatureScaffold(
      title: 'Escanear apunte',
      backPath: '/dashboard',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Campo de texto para escribir/pegar
          Text(
            'Escribe o pega el texto del apunte',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textoCtrl,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Texto extraido de tu apunte...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Selector de asignatura
          asignaturasAsync.when(
            data: (asigs) => DropdownButtonFormField<String>(
              initialValue: _asignaturaId,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Asignatura (opcional)'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Sin asignatura')),
                ...asigs.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.nombre, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => setState(() => _asignaturaId = v),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Boton de guardar
          FilledButton.icon(
            onPressed: escanearState.estado == EscanearEstado.processing
                ? null
                : () => _procesarYGuardar(),
            icon: escanearState.estado == EscanearEstado.processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              escanearState.estado == EscanearEstado.processing
                  ? 'Guardando...'
                  : 'Procesar y guardar',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),

          // Mensaje de estado
          if (escanearState.estado == EscanearEstado.error) ...[
            const SizedBox(height: 12),
            _StatusBanner(
              icon: Icons.error_outline,
              message: escanearState.resultado?.error ?? 'Error desconocido.',
              color: Colors.red,
            ),
          ],
          if (escanearState.estado == EscanearEstado.done) ...[
            const SizedBox(height: 12),
            const _StatusBanner(
              icon: Icons.check_circle_outline,
              message: 'Apunte guardado correctamente.',
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _procesarYGuardar() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe o pega texto antes de guardar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final notifier = ref.read(escanearProvider.notifier);

    await notifier.procesarTexto(texto, asignaturaId: _asignaturaId);

    final stateAfter = ref.read(escanearProvider);
    if (stateAfter.estado != EscanearEstado.done || !mounted) return;

    final titulo = texto.length > 50 ? '${texto.substring(0, 50)}...' : texto;
    final apunte = await notifier.guardarComoApunte(
      titulo: titulo,
      contenido: texto,
      asignaturaId: _asignaturaId,
    );

    if (apunte != null && mounted) {
      ref.invalidate(apuntesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apunte guardado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      // Limpiar campos
      _textoCtrl.clear();
      setState(() => _asignaturaId = null);
      notifier.reset();
    }
  }
}

/// Banner de estado (exito o error).
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
