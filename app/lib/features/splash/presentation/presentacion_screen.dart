import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../core/design_system/sv_colors.dart';
import '../../../shared/widgets/sv_primary_button.dart';

class DatosPresentacion {
  final String titulo;
  final String descripcion;
  final Widget capaImagen;
  final Color colorBrillo;

  const DatosPresentacion({
    required this.titulo,
    required this.descripcion,
    required this.capaImagen,
    required this.colorBrillo,
  });
}

class PresentacionScreen extends ConsumerStatefulWidget {
  const PresentacionScreen({super.key});

  @override
  ConsumerState<PresentacionScreen> createState() => _PresentacionScreenState();
}

class _PresentacionScreenState extends ConsumerState<PresentacionScreen> {
  final PageController _controladorPaginas = PageController();
  int _indiceActual = 0;
  bool _validandoSesion = true;

  final List<DatosPresentacion> _paginas = const [
    DatosPresentacion(
      titulo: 'Planifica tu exito academico',
      descripcion:
          'Organiza semestres, bloques de estudio y examenes en un flujo claro para avanzar sin estres.',
      capaImagen: _ImagenPresentacionAcademica(),
      colorBrillo: SVColors.primaryContainer,
    ),
    DatosPresentacion(
      titulo: 'Convierte tu esfuerzo en logros',
      descripcion:
          'Acumula experiencia, completa retos y visualiza progreso real en cada sesion que termines.',
      capaImagen: _ImagenPresentacionRetos(),
      colorBrillo: SVColors.secondary,
    ),
    DatosPresentacion(
      titulo: 'Equilibra cuerpo y mente',
      descripcion:
          'Entrena con rutinas adaptadas, registra resultados y conecta con una comunidad universitaria activa.',
      capaImagen: _ImagenPresentacionBienestar(),
      colorBrillo: SVColors.secondaryContainer,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _validarSesionActiva();
  }

  @override
  void dispose() {
    _controladorPaginas.dispose();
    super.dispose();
  }

  Future<void> _validarSesionActiva() async {
    final sesion = await ref.read(authRepositoryProvider).estadoSesionActual();

    if (!mounted) return;

    if (sesion.autenticado) {
      context.go(sesion.requiereOnboarding ? '/onboarding' : '/dashboard');
      return;
    }

    setState(() {
      _validandoSesion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_validandoSesion) {
      return const Scaffold(
        backgroundColor: SVColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: SVColors.background,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: 500.ms,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.7),
                radius: 1.25,
                colors: [
                  _paginas[_indiceActual].colorBrillo.withValues(alpha: 0.2),
                  SVColors.background,
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SVColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SVColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SynaptixFit',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: SVColors.primary,
                            ),
                      ).animate().fade(duration: 350.ms).slideX(begin: -0.08),
                      TextButton(
                        onPressed: () => context.go('/acceso'),
                        child: const Text('Omitir'),
                      )
                          .animate()
                          .fade(duration: 350.ms, delay: 150.ms)
                          .slideX(begin: 0.08),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controladorPaginas,
                    onPageChanged: (indice) {
                      setState(() {
                        _indiceActual = indice;
                      });
                    },
                    itemCount: _paginas.length,
                    itemBuilder: (context, indice) {
                      final pagina = _paginas[indice];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(28, 10, 28, 8),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Center(child: pagina.capaImagen),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Text(
                                    pagina.titulo,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: SVColors.onBackground,
                                          height: 1.2,
                                        ),
                                  )
                                      .animate(key: ValueKey('titulo_$indice'))
                                      .fade(duration: 420.ms)
                                      .slideY(begin: 0.08),
                                  const SizedBox(height: 14),
                                  Text(
                                    pagina.descripcion,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: SVColors.onSurfaceVariant,
                                          height: 1.45,
                                        ),
                                  )
                                      .animate(
                                          key: ValueKey('descripcion_$indice'))
                                      .fade(duration: 420.ms, delay: 100.ms)
                                      .slideY(begin: 0.1),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _paginas.length,
                          (indice) => AnimatedContainer(
                            duration: 260.ms,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _indiceActual == indice ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _indiceActual == indice
                                  ? SVColors.primary
                                  : SVColors.outline.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: SVPrimaryButton(
                          label: _indiceActual == _paginas.length - 1
                              ? 'Ir a acceso'
                              : 'Siguiente',
                          onPressed: () {
                            if (_indiceActual == _paginas.length - 1) {
                              context.go('/acceso');
                              return;
                            }
                            _controladorPaginas.nextPage(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenPresentacionAcademica extends StatelessWidget {
  const _ImagenPresentacionAcademica();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SVColors.primary.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: SVColors.primaryContainer.withValues(alpha: 0.24),
                blurRadius: 58,
                spreadRadius: 16,
              ),
            ],
          ),
        ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.08, 1.08),
              duration: 1800.ms,
            ),
        Container(
          width: 210,
          height: 220,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SVColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: SVColors.primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Icon(Icons.school_rounded, color: SVColors.primary),
                ],
              ),
              const SizedBox(height: 18),
              ...List.generate(
                3,
                (indice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: SVColors.secondaryContainer
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: SVColors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            color: SVColors.outline.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(interval: 120.ms).fade(duration: 320.ms),
            ],
          ),
        ).animate().moveY(begin: 26, duration: 500.ms, curve: Curves.easeOut),
      ],
    );
  }
}

class _ImagenPresentacionRetos extends StatelessWidget {
  const _ImagenPresentacionRetos();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SVColors.secondary.withValues(alpha: 0.12),
            boxShadow: [
              BoxShadow(
                color: SVColors.secondaryContainer.withValues(alpha: 0.45),
                blurRadius: 66,
                spreadRadius: 12,
              ),
            ],
          ),
        ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.12, 1.12),
              duration: 1500.ms,
            ),
        Container(
          width: 166,
          height: 186,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: SVColors.secondary,
            boxShadow: [
              BoxShadow(
                color: SVColors.tertiary.withValues(alpha: 0.3),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 22,
                right: 22,
                child: const Icon(
                  Icons.star_rounded,
                  color: SVColors.secondaryContainer,
                  size: 30,
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.25, 1.25),
                      duration: 1200.ms,
                    ),
              ),
              const Icon(
                Icons.emoji_events_rounded,
                size: 84,
                color: SVColors.secondaryContainer,
              ).animate().shimmer(duration: 1800.ms, color: Colors.white),
            ],
          ),
        ).animate().moveY(begin: 26, duration: 500.ms, curve: Curves.easeOut),
      ],
    );
  }
}

class _ImagenPresentacionBienestar extends StatelessWidget {
  const _ImagenPresentacionBienestar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF9800).withValues(alpha: 0.11),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                blurRadius: 60,
                spreadRadius: 16,
              ),
            ],
          ),
        ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 1700.ms,
            ),
        Container(
          width: 206,
          height: 206,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SVColors.surfaceContainerLowest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 74,
                color: Color(0xFFFF5C35),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.14, 1.14),
                    duration: 780.ms,
                  ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: SVColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_run_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ).animate().slideX(begin: 0.7, duration: 600.ms),
              ),
            ],
          ),
        ).animate().moveY(begin: 26, duration: 500.ms, curve: Curves.easeOut),
      ],
    );
  }
}
