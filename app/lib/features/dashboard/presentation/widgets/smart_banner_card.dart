import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/smart_banner_provider.dart';

/// Banner inteligente que muestra el consejo diario generado por IA.
class SmartBannerCard extends ConsumerWidget {
  const SmartBannerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consejo = ref.watch(consejoSmartProvider);

    return consejo.when(
      loading: () => _buildSkeleton(context),
      data: (state) => _buildLoaded(context, state.textoVisible),
      error: (_, __) => _buildFallback(context, 'Consejo no disponible.'),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, String mensaje) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 16, color: Color(0xFF7C4DFF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context, String mensaje) {
    return _buildLoaded(context, mensaje);
  }
}
