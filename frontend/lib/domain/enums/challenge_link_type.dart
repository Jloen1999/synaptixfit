/// Lo que completa un reto o tarea vinculado: una entrega o examen del
/// planificador o un día de la rutina en curso (ADR 0032). Los bloques de
/// estudio no son un vínculo: se asignan a una tarea desde el editor de
/// bloques del planificador (ADR 0028).
enum ChallengeLinkType { exam, delivery, routineDay }
