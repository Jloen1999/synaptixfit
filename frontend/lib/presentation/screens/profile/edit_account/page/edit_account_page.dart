import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../app/validators/validators.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../extensions/validation_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../widgets/birth_date_field.dart';
import '../../widgets/usage_focus_selector.dart';
import '../../widgets/profile_labels.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/edit_account_bloc.dart';
import '../bloc/profile_photo_bloc.dart';
import 'profile_photo_section.dart';
import '../../profile_routes.dart';

/// Edición de la cuenta: foto, nombre, fecha de nacimiento, privacidad y modo
/// de uso. Al guardar actualiza `SessionBloc` (todas las pantallas lo ven). La
/// foto se guarda al momento con su propio bloc ([ProfilePhotoSection]).
class EditAccountPage extends StatelessWidget {
  const EditAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<EditAccountBloc>()),
        BlocProvider(create: (_) => getIt<ProfilePhotoBloc>()),
      ],
      child: const _EditAccountView(),
    );
  }
}

class _EditAccountView extends StatefulWidget {
  const _EditAccountView();

  @override
  State<_EditAccountView> createState() => _EditAccountViewState();
}

class _EditAccountViewState extends State<_EditAccountView>
    with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late Visibility _privacy;
  late UsageFocus _focus;
  DateTime? _birthDate;
  bool _hadBirthDate = false;

  @override
  void initState() {
    super.initState();
    final account = context.read<SessionBloc>().account;
    _name = TextEditingController(text: account?.fullName ?? '');
    _privacy = account?.privacy ?? Visibility.private;
    _focus = account?.usageFocus ?? UsageFocus.both;
    _birthDate = account?.birthDate;
    _hadBirthDate = _birthDate != null;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<EditAccountBloc>().add(
      EditAccountEvent.submitted(
        fullName: _name.text,
        privacy: _privacy,
        usageFocus: _focus,
        birthDate: _birthDate,
        // Quitarla solo si la había: sin fecha y sin cambios no se toca.
        clearBirthDate: _hadBirthDate && _birthDate == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(
        leading: const AppBackButton(fallback: ProfilePaths.root),
        title: Text(l10n.profileEditAccountTitle),
      ),
      body: BlocConsumer<EditAccountBloc, EditAccountState>(
        listener: (context, state) {
          switch (state) {
            case EditAccountSuccess(:final account):
              context.read<SessionBloc>().add(
                SessionEvent.accountUpdated(account),
              );
              context.showSnack(l10n.commonSaved);
              context.pop(true);
            case EditAccountFailure(:final error):
              context.showSnack(errorMessage(context, error));
            default:
              break;
          }
        },
        builder: (context, state) {
          return ProfileScrollBody(
            children: [
              Center(child: ProfilePhotoSection(name: _name.text)),
              const SizedBox(height: TokensSpacing.l),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: l10n.fieldFullName,
                      controller: _name,
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.minLength(v, 2)?.text(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              BirthDateField(
                value: _birthDate,
                onChanged: (v) => setState(() => _birthDate = v),
              ),
              const SizedBox(height: TokensSpacing.l),
              ProfileFormSection(
                title: l10n.profilePrivacyTitle,
                subtitle: l10n.profilePrivacySubtitle,
                child: RadioGroup<Visibility>(
                  groupValue: _privacy,
                  onChanged: (v) {
                    if (v != null) setState(() => _privacy = v);
                  },
                  child: Column(
                    children: [
                      for (final option in const [
                        Visibility.public,
                        Visibility.friends,
                        Visibility.private,
                      ])
                        AppFocusOutline(
                          child: RadioListTile<Visibility>(
                            value: option,
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(option.icon),
                            title: Text(option.label(l10n)),
                            subtitle: Text(option.hint(l10n)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ProfileFormSection(
                title: l10n.profileFocusTitle,
                subtitle: l10n.profileFocusEditHint,
                child: UsageFocusSelector(
                  value: _focus,
                  onChanged: (v) => setState(() => _focus = v),
                ),
              ),
              AppPrimaryButton(
                label: l10n.commonSave,
                loading: state is EditAccountSubmitting,
                onPressed: _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}
