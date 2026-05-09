import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../academico/application/usuario_carreras_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_PerfilData>(
      future: _cargarPerfil(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FeatureScaffold(
            title: 'Perfil',
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const FeatureScaffold(
            title: 'Perfil',
            child: Center(child: Text('No se pudo cargar el perfil.')),
          );
        }

        final usuario = data.usuario;
        final perfil = data.perfil;

        return FeatureScaffold(
          title: 'Perfil',
          child: DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _HeroHeader(usuario: usuario, perfil: perfil),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      tabs: const [
                        Tab(text: 'Estadísticas'),
                        Tab(text: 'Bienestar'),
                        Tab(text: 'Ajustes'),
                      ],
                      labelStyle:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                      indicatorSize: TabBarIndicatorSize.label,
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _EstadisticasTab(
                    usuario: usuario,
                    sesiones: data.sesiones,
                    logros: data.logros,
                    caloriasAcumuladas: data.caloriasAcumuladas,
                  ),
                  _BienestarTab(perfil: perfil, historial: data.historial),
                  _AjustesTab(usuario: usuario, prefs: data.preferencias),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_PerfilData> _cargarPerfil() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Sesión no activa');

    final usuarioMap =
        await client.from('usuarios').select().eq('id', user.id).maybeSingle();

    final usuario = usuarioMap != null
        ? UsuarioDb.fromMap(usuarioMap)
        : UsuarioDb(
            id: user.id,
            email: user.email ?? '',
            nombreCompleto:
                user.userMetadata?['full_name']?.toString() ?? 'Usuario',
            urlAvatar: user.userMetadata?['avatar_url']?.toString(),
            nivel: 1,
            xpTotal: 0,
            rachaActual: 0,
            creadoEn: DateTime.now(),
            actualizadoEn: DateTime.now(),
          );

    final perfilMap = await client
        .from('perfil_bienestar_usuario')
        .select()
        .eq('usuario_id', user.id)
        .maybeSingle();

    final perfil = perfilMap != null
        ? PerfilBienestarDb.fromMap(perfilMap)
        : PerfilBienestarDb(
            id: '',
            usuarioId: user.id,
            edad: 0,
            sexo: '',
            pesoKg: 0,
            alturaCm: 0,
            imc: 0,
            nivelActividad: '',
            objetivoPrincipal: '',
            objetivos: [],
            equipamientoDisponible: [],
            diasDisponiblesSemana: 0,
            minutosPorSesion: 0,
            onboardingCompletado: false,
            creadoEn: DateTime.now(),
            actualizadoEn: DateTime.now(),
          );

    final sesionesData = await client
        .from('sesiones_registradas')
        .select()
        .eq('usuario_id', user.id);
    final sesiones = (sesionesData as List).length;
    final calorias = (sesionesData as List).fold<int>(
      0,
      (t, s) => t + ((s['calorias_quemadas'] ?? 0) as num).round(),
    );

    final retosData = await client
        .from('retos')
        .select('id')
        .eq('usuario_id', user.id)
        .eq('esta_completado', true);
    final logros = (retosData as List).length;

    final historialData = await client
        .from('historial_peso')
        .select()
        .eq('usuario_id', user.id)
        .order('registrado_en', ascending: false);
    final historialPeso = (historialData as List)
        .map((h) => HistorialPesoDb.fromMap(h as Map<String, dynamic>))
        .toList();

    final prefsMap = await client
        .from('preferencias_notificacion')
        .select()
        .eq('usuario_id', user.id)
        .maybeSingle();

    final preferencias = prefsMap != null
        ? PreferenciasNotificacionDb.fromMap(prefsMap)
        : PreferenciasNotificacionDb(
            id: '',
            usuarioId: user.id,
            categoriasActivas: ['conflict', 'milestone', 'social'],
            horaSilencioInicio: '23:00',
            horaSilencioFin: '07:00',
            limiteDiario: 10,
            modoActual: 'normal',
            creadoEn: DateTime.now(),
            actualizadoEn: DateTime.now(),
          );

    return _PerfilData(
      usuario: usuario,
      perfil: perfil,
      sesiones: sesiones,
      logros: logros,
      caloriasAcumuladas: calorias,
      historial: historialPeso,
      preferencias: preferencias,
    );
  }
}

class _PerfilData {
  final UsuarioDb usuario;
  final PerfilBienestarDb perfil;
  final int sesiones;
  final int logros;
  final int caloriasAcumuladas;
  final List<HistorialPesoDb> historial;
  final PreferenciasNotificacionDb preferencias;
  _PerfilData(
      {required this.usuario,
      required this.perfil,
      required this.sesiones,
      required this.logros,
      required this.caloriasAcumuladas,
      required this.historial,
      required this.preferencias});
}

// ---------------------------------------------------------------------------
// Hero Header con avatar prominente, nombre, nivel y barra XP
// ---------------------------------------------------------------------------
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.usuario, required this.perfil});

  final UsuarioDb usuario;
  final PerfilBienestarDb perfil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = usuario.nombreCompleto;
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    final xpMax = 1000 * usuario.nivel;
    final xpProgreso = (usuario.xpTotal / xpMax).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            usuario.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Nivel + XP Bar
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded,
                        size: 16, color: Color(0xFF72FE8F)),
                    const SizedBox(width: 4),
                    Text(
                      'Nivel ${usuario.nivel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${usuario.xpTotal} / $xpMax XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: xpProgreso,
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF72FE8F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Racha y días
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniStat(icon: '🔥', label: '${usuario.rachaActual} racha'),
              const SizedBox(width: 20),
              _MiniStat(
                  icon: '📅',
                  label: '${perfil.diasDisponiblesSemana} días/sem'),
              const SizedBox(width: 20),
              _MiniStat(
                  icon: '⏱️', label: '${perfil.minutosPorSesion} min/ses'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Estadísticas
// ---------------------------------------------------------------------------
class _EstadisticasTab extends StatelessWidget {
  const _EstadisticasTab({
    required this.usuario,
    required this.sesiones,
    required this.logros,
    required this.caloriasAcumuladas,
  });

  final UsuarioDb usuario;
  final int sesiones;
  final int logros;
  final int caloriasAcumuladas;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KpiCard(
          title: 'XP total',
          value: '${usuario.xpTotal}',
          icon: Icons.stars_rounded,
          subtitle: 'Nivel ${usuario.nivel}',
          progress: (usuario.xpTotal / (1000 * usuario.nivel)).clamp(0.0, 1.0),
        ),
        const SizedBox(height: 10),
        KpiCard(
          title: 'Sesiones registradas',
          value: '$sesiones',
          icon: Icons.fitness_center_rounded,
        ),
        const SizedBox(height: 10),
        KpiCard(
          title: 'Retos completados',
          value: '$logros',
          icon: Icons.emoji_events_rounded,
          gradientColors: [
            const Color(0xFFE65100).withValues(alpha: 0.10),
            const Color(0xFFE65100).withValues(alpha: 0.03),
          ],
        ),
        const SizedBox(height: 10),
        KpiCard(
          title: 'Calorías acumuladas',
          value: '$caloriasAcumuladas kcal',
          icon: Icons.local_fire_department_rounded,
          gradientColors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.10),
            const Color(0xFFFF6B35).withValues(alpha: 0.03),
          ],
        ),
        const SizedBox(height: 10),
        KpiCard(
          title: 'Racha actual',
          value: '${usuario.rachaActual} días',
          icon: Icons.whatshot_rounded,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Bienestar
// ---------------------------------------------------------------------------
class _BienestarTab extends StatelessWidget {
  const _BienestarTab({required this.perfil, required this.historial});

  final PerfilBienestarDb perfil;
  final List<HistorialPesoDb> historial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Perfil físico actual
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil físico actual',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _DatoRow(label: 'Peso', valor: '${perfil.pesoKg} kg'),
                _DatoRow(label: 'Altura', valor: '${perfil.alturaCm} cm'),
                _DatoRow(
                    label: 'IMC',
                    valor:
                        '${perfil.imc.toStringAsFixed(1)} (${perfil.imcCategoria})'),
                _DatoRow(label: 'Edad', valor: '${perfil.edad} años'),
                _DatoRow(
                    label: 'Actividad',
                    valor: perfil.nivelActividad.toUpperCase()),
                _DatoRow(label: 'Objetivo', valor: perfil.objetivoPrincipal),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Historial de peso simplificado
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evolución de peso',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (historial.isEmpty)
                  const Text('Sin registros aún')
                else
                  ...historial.map((h) => _DatoRow(
                        label: _formatFecha(h.registradoEn),
                        valor: '${h.pesoKg} kg (IMC ${h.imc})',
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Equipamiento
        if (perfil.equipamientoDisponible.isNotEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipamiento disponible',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: perfil.equipamientoDisponible
                        .map((e) => Chip(
                              label: Text(e.replaceAll('_', ' ')),
                              avatar:
                                  const Icon(Icons.fitness_center, size: 16),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

class _DatoRow extends StatelessWidget {
  const _DatoRow({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            valor,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Ajustes
// ---------------------------------------------------------------------------
class _AjustesTab extends ConsumerWidget {
  const _AjustesTab({required this.usuario, required this.prefs});

  final UsuarioDb usuario;
  final PreferenciasNotificacionDb prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_rounded),
                title: const Text('Visibilidad del perfil'),
                subtitle: const Text('Privado'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_rounded),
                title: const Text('Notificaciones'),
                subtitle: Text(
                  'Modo: ${prefs.modoActual} · Límite: ${prefs.limiteDiario}/día',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: const Text('Modo silencio'),
                subtitle: Text(
                  '${prefs.horaSilencioInicio ?? '--'} a ${prefs.horaSilencioFin ?? '--'}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CarrerasCard(),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () async {
              try {
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/acceso');
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo cerrar la sesión.'),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Delegate para tab bar persistente en NestedScrollView
// ---------------------------------------------------------------------------
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

class _CarrerasCard extends ConsumerWidget {
  const _CarrerasCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrerasAsync = ref.watch(usuarioCarrerasProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: carrerasAsync.when(
        data: (carreras) {
          final nombresAsync = carreras.isNotEmpty
              ? ref.watch(carrerasUsuarioConNombreProvider(carreras))
              : null;
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.school_rounded),
                title: const Text('Mis carreras'),
                subtitle: carreras.isEmpty
                    ? const Text('Sin carreras configuradas')
                    : null,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    context.push('/academico/configuracion'),
              ),
              if (nombresAsync != null)
                nombresAsync.whenOrNull(
                  data: (cats) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: cats
                          .map((c) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                          Icons.school_outlined,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(c.nombre,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          if (c.universidadNombre !=
                                              null)
                                            Text(
                                                c.universidadNombre!,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Theme.of(
                                                            context)
                                                        .colorScheme
                                                        .onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ) ?? const SizedBox.shrink(),
            ],
          );
        },
        loading: () => const ListTile(
          leading: Icon(Icons.school_rounded),
          title: Text('Mis carreras'),
          subtitle: Text('Cargando...'),
        ),
        error: (_, __) => const ListTile(
          leading: Icon(Icons.school_rounded),
          title: Text('Mis carreras'),
          subtitle: Text('Error'),
        ),
      ),
    );
  }
}
