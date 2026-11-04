import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/post_type.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/post.dart';
import 'package:synaptixfit/domain/models/training/session_history.dart';
import 'package:synaptixfit/domain/use_cases/social/create_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/apply_recommendation_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/discard_recommendation_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_highlights_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/session_completed/bloc/session_completed_bloc.dart';

import 'training_fixtures.dart';
import 'package:synaptixfit/domain/models/progress/streak.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_page.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_query.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_my_challenges_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_streak_use_case.dart';

class _GetSession extends Mock implements GetSessionUseCaseContract {}

class _Apply extends Mock implements ApplyRecommendationUseCaseContract {}

class _Discard extends Mock implements DiscardRecommendationUseCaseContract {}

class _Highlights extends Mock implements GetSessionHighlightsUseCaseContract {}

class _CreatePost extends Mock implements CreatePostUseCaseContract {}

class _FakePost extends Fake implements Post {}

void main() {
  late _GetSession getSession;
  late _Highlights getHighlights;
  late _CreatePost createPost;

  const highlights = SessionHighlights(
    volumeKg: 1040,
    totalReps: 14,
    completedSets: 2,
    previousVolumeKg: 480,
  );

  setUpAll(() => registerFallbackValue(PostType.sessionCompleted));

  setUp(() {
    getSession = _GetSession();
    getHighlights = _Highlights();
    createPost = _CreatePost();
    when(() => getSession('s1')).thenAnswer(
      (_) async => Success(
        TrainingFixtures.session(startedAt: DateTime(2026, 10, 25, 10)),
      ),
    );
    when(
      () => getHighlights('s1'),
    ).thenAnswer((_) async => const Success(highlights));
    when(
      () => createPost(
        type: any(named: 'type'),
        description: any(named: 'description'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async => Success(_FakePost()));
  });

  SessionCompletedBloc build() => SessionCompletedBloc(
    getSession: getSession,
    apply: _Apply(),
    discard: _Discard(),
    getHighlights: getHighlights,
    createPost: createPost,
    getStreak: _Streak(),
    listChallenges: _Challenges(),
  );

  blocTest<SessionCompletedBloc, SessionCompletedState>(
    'carga lo destacado de la sesión después de mostrarla',
    build: build,
    act: (bloc) =>
        bloc.add(const SessionCompletedEvent.started(sessionId: 's1')),
    verify: (bloc) {
      expect(bloc.state.status, CompletedStatus.ready);
      expect(bloc.state.highlights, highlights);
      expect(bloc.state.highlights!.volumeDeltaKg, 560);
    },
  );

  blocTest<SessionCompletedBloc, SessionCompletedState>(
    'si el servidor dice que ya se compartió, queda como compartida sin error',
    setUp: () =>
        when(
          () => createPost(
            type: any(named: 'type'),
            description: any(named: 'description'),
            metadata: any(named: 'metadata'),
          ),
        ).thenAnswer(
          (_) async => const Failure(AppError.business('POST_ALREADY_SHARED')),
        ),
    build: build,
    act: (bloc) async {
      bloc.add(const SessionCompletedEvent.started(sessionId: 's1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SessionCompletedEvent.shareRequested('He entrenado'));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.shared, isTrue);
      expect(bloc.state.effect, isNull);
    },
  );

  blocTest<SessionCompletedBloc, SessionCompletedState>(
    'compartir publica una vez en el muro como sesión completada',
    build: build,
    act: (bloc) async {
      bloc.add(const SessionCompletedEvent.started(sessionId: 's1'));
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(const SessionCompletedEvent.shareRequested('He entrenado'))
        ..add(const SessionCompletedEvent.shareRequested('He entrenado'));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.shared, isTrue);
      verify(
        () => createPost(
          type: PostType.sessionCompleted,
          description: 'He entrenado',
          metadata: {'sessionId': 's1'},
        ),
      ).called(1);
    },
  );
}

class _Streak implements GetStreakUseCaseContract {
  @override
  Future<AppResult<Streak>> call() async => const Success(
    Streak(
      currentDays: 4,
      bestDays: 9,
      activeToday: true,
      atRisk: false,
      daysToNextMilestone: 3,
      milestoneProgress: 0.5,
    ),
  );
}

class _Challenges implements ListMyChallengesUseCaseContract {
  @override
  Future<AppResult<ChallengePage>> call({
    required ChallengeQuery query,
    int page = 0,
    int size = 20,
  }) async => const Success(
    ChallengePage(items: [], page: 0, totalPages: 0, totalItems: 0),
  );
}
