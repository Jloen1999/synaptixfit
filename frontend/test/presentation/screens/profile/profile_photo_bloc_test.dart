import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/remove_avatar_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/upload_avatar_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/edit_account/bloc/profile_photo_bloc.dart';
import 'package:synaptixfit/presentation/widgets/photo_pick.dart';

import 'profile_fixtures.dart';

const _url = 'https://app.test/api/v1/avatars/u/f.jpg';

/// Sube lo que recibe y devuelve la cuenta con la foto (o el error indicado).
class FakeUploadAvatar implements UploadAvatarUseCaseContract {
  final uploads = <String>[];
  AppError? error;

  @override
  Future<AppResult<Account>> call({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    uploads.add(fileName);
    final failure = error;
    if (failure != null) return Result.failure(failure);
    return Result.success(testAccount.copyWith(avatarUrl: _url));
  }
}

class FakeRemoveAvatar implements RemoveAvatarUseCaseContract {
  int calls = 0;

  @override
  Future<AppResult<Account>> call() async {
    calls++;
    return Result.success(testAccount.copyWith(avatarUrl: null));
  }
}

const PickedPhoto _photo = (
  bytes: [1, 2, 3],
  fileName: 'selfie.jpg',
  mimeType: 'image/jpeg',
);

void main() {
  late FakeUploadAvatar upload;
  late FakeRemoveAvatar remove;

  setUp(() {
    upload = FakeUploadAvatar();
    remove = FakeRemoveAvatar();
  });

  ProfilePhotoBloc build() => ProfilePhotoBloc(upload: upload, remove: remove);

  blocTest<ProfilePhotoBloc, ProfilePhotoState>(
    'elegir una foto solo la enseña: no se sube hasta «Usar esta foto»',
    build: build,
    act: (bloc) => bloc.add(const ProfilePhotoEvent.picked(_photo)),
    expect: () => [const ProfilePhotoState(preview: _photo)],
    verify: (_) => expect(upload.uploads, isEmpty),
  );

  blocTest<ProfilePhotoBloc, ProfilePhotoState>(
    '«Usar esta foto» sube, quita la vista previa y deja la cuenta nueva',
    build: build,
    seed: () => const ProfilePhotoState(preview: _photo),
    act: (bloc) => bloc.add(const ProfilePhotoEvent.uploadRequested()),
    expect: () => [
      const ProfilePhotoState(preview: _photo, saving: true),
      ProfilePhotoState(
        account: testAccount.copyWith(avatarUrl: _url),
        outcome: ProfilePhotoOutcome.changed,
      ),
    ],
    verify: (_) => expect(upload.uploads, ['selfie.jpg']),
  );

  blocTest<ProfilePhotoBloc, ProfilePhotoState>(
    'si falla, la vista previa sigue para reintentar o elegir otra',
    build: () {
      upload.error = const AppError.business('AVATAR_TOO_LARGE');
      return build();
    },
    seed: () => const ProfilePhotoState(preview: _photo),
    act: (bloc) => bloc.add(const ProfilePhotoEvent.uploadRequested()),
    skip: 1,
    expect: () => [
      const ProfilePhotoState(
        preview: _photo,
        error: AppError.business('AVATAR_TOO_LARGE'),
      ),
    ],
  );

  blocTest<ProfilePhotoBloc, ProfilePhotoState>(
    '«Cancelar» descarta la foto elegida sin subir nada',
    build: build,
    seed: () => const ProfilePhotoState(preview: _photo),
    act: (bloc) => bloc.add(const ProfilePhotoEvent.discarded()),
    expect: () => [const ProfilePhotoState()],
  );

  blocTest<ProfilePhotoBloc, ProfilePhotoState>(
    '«Quitar foto» la quita y avisa',
    build: build,
    act: (bloc) => bloc.add(const ProfilePhotoEvent.removeRequested()),
    skip: 1,
    expect: () => [
      ProfilePhotoState(
        account: testAccount.copyWith(avatarUrl: null),
        outcome: ProfilePhotoOutcome.removed,
      ),
    ],
    verify: (_) => expect(remove.calls, 1),
  );
}
