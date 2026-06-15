import 'ejercicio_recomendado_dto.dart';

/// Datos de sesiones previas para que la IA pueda aplicar sobrecarga
/// progresiva y detectar patrones de fatiga.
class HistorialSesionDto {
  const HistorialSesionDto({
    this.totalSesionesCompletadas = 0,
    this.rpePromedio = 0.0,
    this.volumenSemanalEstimado = 0,
    this.ejerciciosRecientes = const [],
    this.diasCompletadosUltimaSemana = 0,
    this.semanasConsecutivasEntrenando = 0,
  });

  final int totalSesionesCompletadas;
  final double rpePromedio;
  final int volumenSemanalEstimado;
  final List<EjercicioRecienteDto> ejerciciosRecientes;
  final int diasCompletadosUltimaSemana;
  final int semanasConsecutivasEntrenando;

  bool get requiereDescarga =>
      rpePromedio > 8.0 && semanasConsecutivasEntrenando >= 4;
}
