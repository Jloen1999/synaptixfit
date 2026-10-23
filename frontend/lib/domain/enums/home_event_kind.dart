/// Origen de un evento de hoy en el inicio: bloque del calendario o entrega/examen.
enum HomeEventKind {
  block,
  deadline;

  static HomeEventKind fromApi(String? value) =>
      value == 'DEADLINE' ? deadline : block;
}
