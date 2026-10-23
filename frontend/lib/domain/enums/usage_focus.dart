import 'badge_category.dart';
import 'challenge_type.dart';
import 'home_event_type.dart';
import 'planner_enums.dart';

/// Para qué usa la app la persona: solo estudios, solo deporte o ambos. Decide
/// qué pestañas, secciones y avisos se muestran. Es el único sitio del cliente
/// que dice qué pertenece a cada ámbito, igual que en el servidor
/// (`ActivityType.visibleFor`, `ChallengeType.allowedFor`,
/// `BadgeCategory.visibleFor`); el servidor ya filtra lo que decide él.
enum UsageFocus {
  academic('ACADEMIC'),
  fitness('FITNESS'),
  both('BOTH');

  const UsageFocus(this.apiValue);

  final String apiValue;

  bool get includesAcademic => this != fitness;
  bool get includesFitness => this != academic;

  /// Sin valor (cuentas antiguas o aún sin elegir) equivale a ambos.
  static UsageFocus fromApi(String? value) =>
      values.firstWhere((f) => f.apiValue == value, orElse: () => both);

  /// Bloques del planificador de su ámbito: lo académico con estudios, el
  /// deporte con deporte; descanso, comida y sueño siempre.
  bool allowsBlock(BlockType type) => switch (type) {
    BlockType.sport => includesFitness,
    BlockType.study ||
    BlockType.classSession ||
    BlockType.exam ||
    BlockType.delivery ||
    BlockType.review => includesAcademic,
    _ => true,
  };

  /// Eventos de la agenda de Inicio, con el mismo criterio que los bloques
  /// (las entregas y exámenes son de estudios).
  bool allowsEvent(HomeEventType type) => switch (type) {
    HomeEventType.sport => includesFitness,
    HomeEventType.study ||
    HomeEventType.classSession ||
    HomeEventType.review ||
    HomeEventType.exam ||
    HomeEventType.delivery ||
    HomeEventType.presentation => includesAcademic,
    _ => true,
  };

  /// Tipos de reto que se pueden crear (el servidor lo valida igual).
  List<ChallengeType> get challengeTypes => [
    if (includesAcademic) ChallengeType.academic,
    if (includesFitness) ChallengeType.fitness,
  ];

  bool allowsBadges(BadgeCategory category) => switch (category) {
    BadgeCategory.training => includesFitness,
    BadgeCategory.study => includesAcademic,
    _ => true,
  };
}
