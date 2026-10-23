import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/usage_focus.dart';
import '../../auth/session/bloc/session_bloc.dart';

/// Enfoque de uso de la sesión para el planificador (qué tipos de bloque se
/// ofrecen lo decide [UsageFocus.allowsBlock]).
extension PlannerFocusContext on BuildContext {
  UsageFocus get usageFocus =>
      read<SessionBloc>().account?.usageFocus ?? UsageFocus.both;
}
