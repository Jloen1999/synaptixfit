import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/auth/register_use_case.dart';

part 'register_bloc.freezed.dart';
part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required this._register}) : super(const RegisterState.idle()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  final RegisterUseCaseContract _register;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterState.submitting());
    final result = await _register(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
    );
    emit(result.fold(RegisterState.success, RegisterState.failure));
  }
}
