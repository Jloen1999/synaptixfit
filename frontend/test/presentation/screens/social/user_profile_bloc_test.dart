import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/feed_period.dart';
import 'package:synaptixfit/domain/enums/friendship_relation.dart';
import 'package:synaptixfit/domain/enums/shared_notes_scope.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/note.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/public_profile.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_shared_notes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/accept_friend_request_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/block_user_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/get_feed_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/get_public_profile_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/reject_friend_request_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/remove_friendship_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/send_friend_request_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/set_post_like_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/user_profile/bloc/user_profile_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/widgets/social_feedback.dart';

import 'social_fixtures.dart';

class _Profile extends Mock implements GetPublicProfileUseCaseContract {}

class _Feed extends Mock implements GetFeedUseCaseContract {}

class _Like extends Mock implements SetPostLikeUseCaseContract {}

class _Send extends Mock implements SendFriendRequestUseCaseContract {}

class _Accept extends Mock implements AcceptFriendRequestUseCaseContract {}

class _Reject extends Mock implements RejectFriendRequestUseCaseContract {}

class _Remove extends Mock implements RemoveFriendshipUseCaseContract {}

class _Block extends Mock implements BlockUserUseCaseContract {}

class _Notes extends Mock implements GetSharedNotesUseCaseContract {}

void main() {
  late _Profile profile;
  late _Feed feed;
  late _Send send;
  late _Block block;
  late _Notes notes;

  setUpAll(() {
    registerFallbackValue(FeedPeriod.all);
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(SharedNotesScope.all);
  });

  setUp(() {
    profile = _Profile();
    feed = _Feed();
    send = _Send();
    block = _Block();
    notes = _Notes();
    when(
      () => notes(
        page: any(named: 'page'),
        scope: any(named: 'scope'),
        authorId: any(named: 'authorId'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const Success(
        SharedNoteSummaryPage(items: [], page: 0, totalPages: 0),
      ),
    );
  });

  UserProfileBloc build() => UserProfileBloc(
    getProfile: profile,
    getFeed: feed,
    setLike: _Like(),
    sendRequest: send,
    acceptRequest: _Accept(),
    rejectRequest: _Reject(),
    removeFriendship: _Remove(),
    blockUser: block,
    getSharedNotes: notes,
  );

  PublicProfile profileWith(FriendshipRelation relation, {String? fid}) =>
      PublicProfile(
        id: 'u2',
        fullName: 'Luis Gil',
        privacy: Visibility.public,
        restricted: false,
        level: 5,
        streak: 3,
        postsCount: 1,
        friendsCount: 4,
        relation: relation,
        friendshipId: fid,
      );

  void stubPosts() => when(
    () => feed(
      period: any(named: 'period'),
      since: any(named: 'since'),
      authorId: 'u2',
      page: any(named: 'page'),
      size: any(named: 'size'),
    ),
  ).thenAnswer((_) async => Success(page([post('p1')])));

  blocTest<UserProfileBloc, UserProfileState>(
    'carga el perfil y sus publicaciones',
    setUp: () {
      when(
        () => profile(userId: 'u2'),
      ).thenAnswer((_) async => Success(profileWith(FriendshipRelation.none)));
      stubPosts();
    },
    build: build,
    act: (bloc) => bloc.add(const UserProfileEvent.started('u2')),
    expect: () => [
      const UserProfileState(userId: 'u2'),
      UserProfileState(
        userId: 'u2',
        status: SocialLoadStatus.loaded,
        profile: profileWith(FriendshipRelation.none),
        posts: [post('p1')],
      ),
    ],
  );

  blocTest<UserProfileBloc, UserProfileState>(
    'un usuario no encontrado emite failure',
    setUp: () {
      when(() => profile(userId: 'u2')).thenAnswer(
        (_) async => const Failure(AppError.business('SOCIAL_USER_NOT_FOUND')),
      );
      stubPosts();
    },
    build: build,
    act: (bloc) => bloc.add(const UserProfileEvent.started('u2')),
    expect: () => const [
      UserProfileState(userId: 'u2'),
      UserProfileState(
        userId: 'u2',
        status: SocialLoadStatus.failure,
        error: AppError.business('SOCIAL_USER_NOT_FOUND'),
      ),
    ],
  );

  blocTest<UserProfileBloc, UserProfileState>(
    'añadir amigo envía la solicitud y recarga la relación',
    setUp: () {
      when(() => send(userId: 'u2')).thenAnswer(
        (_) async =>
            Success(friendship('s1', relation: FriendshipRelation.requestSent)),
      );
      when(() => profile(userId: 'u2')).thenAnswer(
        (_) async =>
            Success(profileWith(FriendshipRelation.requestSent, fid: 's1')),
      );
      stubPosts();
    },
    build: build,
    seed: () => UserProfileState(
      userId: 'u2',
      status: SocialLoadStatus.loaded,
      profile: profileWith(FriendshipRelation.none),
      posts: [post('p1')],
    ),
    act: (bloc) => bloc.add(
      const UserProfileEvent.relationActionRequested(
        ProfileRelationAction.sendRequest,
      ),
    ),
    verify: (bloc) {
      expect(bloc.state.profile?.relation, FriendshipRelation.requestSent);
      expect(bloc.state.busy, isFalse);
      verify(() => send(userId: 'u2')).called(1);
    },
  );

  blocTest<UserProfileBloc, UserProfileState>(
    'bloquear con error lo muestra sin recargar',
    setUp: () => when(() => block(userId: 'u2')).thenAnswer(
      (_) async => const Failure(AppError.business('FRIENDSHIP_SELF_TARGET')),
    ),
    build: build,
    seed: () => UserProfileState(
      userId: 'u2',
      status: SocialLoadStatus.loaded,
      profile: profileWith(FriendshipRelation.none),
    ),
    act: (bloc) => bloc.add(
      const UserProfileEvent.relationActionRequested(
        ProfileRelationAction.block,
      ),
    ),
    expect: () {
      final base = UserProfileState(
        userId: 'u2',
        status: SocialLoadStatus.loaded,
        profile: profileWith(FriendshipRelation.none),
      );
      return [
        base.copyWith(busy: true),
        base.copyWith(
          feedback: const SocialFeedback.error(
            AppError.business('FRIENDSHIP_SELF_TARGET'),
          ),
        ),
        base,
      ];
    },
  );
}
