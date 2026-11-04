import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/health_consent_bloc.dart';

/// Se llama justo antes de guardar el registro diario. Si la persona ya dio el
/// permiso para guardar sus datos de salud (o no se puede comprobar ahora),
/// devuelve `true` sin enseñar nada; si no, abre una hoja que explica para qué
/// se usan, con una casilla y «Dar permiso» (ADR 0034). Es aparte de aceptar
/// la política: el RGPD pide un consentimiento expreso para datos de salud.
Future<bool> ensureHealthConsent(BuildContext context) async {
  final bloc = getIt<HealthConsentBloc>()
    ..add(const HealthConsentEvent.started());
  try {
    final ready = await bloc.stream.firstWhere((s) => !s.loading);
    // Sin conexión no se sabe: se intenta guardar y, si falta, el servidor
    // responde HEALTH_CONSENT_REQUIRED con su explicación.
    if (ready.given || ready.error != null) return true;
    if (!context.mounted) return false;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const HealthConsentSheet()),
    );
    return accepted ?? false;
  } finally {
    unawaited(bloc.close());
  }
}

/// Hoja del permiso de datos de salud: para qué se usan, casilla obligatoria y
/// «Dar permiso y seguir». Cierra con `true` cuando el servidor lo ha guardado.
class HealthConsentSheet extends StatefulWidget {
  const HealthConsentSheet({super.key});

  @override
  State<HealthConsentSheet> createState() => _HealthConsentSheetState();
}

class _HealthConsentSheetState extends State<HealthConsentSheet>
    with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<HealthConsentBloc, HealthConsentState>(
      listenWhen: (a, b) => !a.given && b.given,
      listener: (context, _) => Navigator.pop(context, true),
      builder: (context, state) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.l,
            0,
            TokensSpacing.l,
            TokensSpacing.l,
          ),
          child: AppContentWidth.reading(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      size: TokensSize.iconXl,
                      color: context.colors.secondary,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.trainingHealthConsentTitle,
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleLarge,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  Text(
                    l10n.trainingHealthConsentBody,
                    style: context.textStyles.bodyLarge,
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  AppConsentCheckbox(
                    label: l10n.trainingHealthConsentCheckbox,
                    requiredMessage: l10n.trainingHealthConsentRequired,
                    enabled: !state.saving,
                    autofocus: true,
                  ),
                  if (state.saveError case final error?) ...[
                    const SizedBox(height: TokensSpacing.s),
                    AppInlineMessage(message: errorMessage(context, error)),
                  ],
                  const SizedBox(height: TokensSpacing.m),
                  AppPrimaryButton(
                    label: l10n.trainingHealthConsentAccept,
                    icon: Icons.check_rounded,
                    loading: state.saving,
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      context.read<HealthConsentBloc>().add(
                        const HealthConsentEvent.given(),
                      );
                    },
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  TextButton(
                    onPressed: state.saving
                        ? null
                        : () => Navigator.pop(context, false),
                    child: Text(l10n.profilePermissionNotNow),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
