import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/challenge_type.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../auth/session/bloc/session_bloc.dart';

/// Tipos de reto que permite el enfoque de uso de la persona (el servidor lo
/// exige igual al crear): con un solo enfoque no se elige tipo.
extension ChallengeFocusContext on BuildContext {
  List<ChallengeType> get allowedChallengeTypes {
    final focus = select(
      (SessionBloc bloc) => bloc.account?.usageFocus ?? UsageFocus.both,
    );
    return focus.challengeTypes;
  }

  /// Tipo con el que empieza un reto nuevo.
  ChallengeType get defaultChallengeType {
    final focus = read<SessionBloc>().account?.usageFocus ?? UsageFocus.both;
    return focus == UsageFocus.fitness
        ? ChallengeType.fitness
        : ChallengeType.academic;
  }
}
