import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/feed_period.dart';
import 'package:synaptixfit/domain/enums/post_type.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/like_status.dart';
import 'package:synaptixfit/domain/models/social/post.dart';
import 'package:synaptixfit/domain/models/social/social_page.dart';
import 'package:synaptixfit/domain/use_cases/notifications/get_unread_notifications_count_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/create_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/delete_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/edit_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/get_feed_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/get_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/report_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/set_post_like_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/feed/bloc/feed_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/widgets/social_feedback.dart';

import 'social_fixtures.dart';

class _GetFeed extends Mock implements GetFeedUseCaseContract {}

class _GetPost extends Mock implements GetPostUseCaseContract {}

class _CreatePost extends Mock implements CreatePostUseCaseContract {}

class _EditPost extends Mock implements EditPostUseCaseContract {}

class _DeletePost extends Mock implements DeletePostUseCaseContract {}

class _ReportPost extends Mock implements ReportPostUseCaseContract {}

class _SetLike extends Mock implements SetPostLikeUseCaseContract {}

class _Unread extends Mock
    implements GetUnreadNotificationsCountUseCaseContract {}

void main() {
  late _GetFeed getFeed;
  late _GetPost getPost;
  late _CreatePost createPost;
  late _EditPost editPost;
  late _DeletePost deletePost;
  late _ReportPost reportPost;
  late _SetLike setLike;
  late _Unread unread;

  setUpAll(() {
    registerFallbackValue(FeedPeriod.all);
    registerFallbackValue(PostType.milestoneReached);
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    getFeed = _GetFeed();
    getPost = _GetPost();
    createPost = _CreatePost();
    editPost = _EditPost();
    deletePost = _DeletePost();
    reportPost = _ReportPost();
    setLike = _SetLike();
    unread = _Unread();
    when(() => unread()).thenAnswer((_) async => const Success(0));
  });

  FeedBloc build({Duration pollInterval = const Duration(seconds: 30)}) =>
      FeedBloc(
        getFeed: getFeed,
        getPost: getPost,
        createPost: createPost,
        editPost: editPost,
        deletePost: deletePost,
        reportPost: reportPost,
        setLike: setLike,
        unreadCount: unread,
        pollInterval: pollInterval,
      );

  void stubFeed(Future<Result<SocialPage<Post>, AppError>> Function() answer) =>
      when(
        () => getFeed(
          period: any(named: 'period'),
          since: any(named: 'since'),
          authorId: any(named: 'authorId'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) => answer());

  final p1 = post('p1', minutes: 10, likes: 2);
  final loaded = FeedState(status: SocialLoadStatus.loaded, posts: [p1]);

  group('carga', () {
    blocTest<FeedBloc, FeedState>(
      'carga la primera página del muro',
      setUp: () => stubFeed(() async => Success(page([p1], totalPages: 2))),
      build: build,
      act: (bloc) => bloc.add(const FeedEvent.started()),
      // La primera emisión (carga) se emite aunque coincida con el estado inicial.
      expect: () => [
        const FeedState(),
        FeedState(status: SocialLoadStatus.loaded, posts: [p1], hasMore: true),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'emite failure si falla la carga',
      setUp: () => stubFeed(() async => const Failure(AppError.network())),
      build: build,
      act: (bloc) => bloc.add(const FeedEvent.started()),
      expect: () => const [
        FeedState(),
        FeedState(status: SocialLoadStatus.failure, error: AppError.network()),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'el filtro temporal recarga con el periodo elegido',
      setUp: () => stubFeed(() async => Success(page([p1]))),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const FeedEvent.periodChanged(FeedPeriod.week)),
      expect: () => [
        const FeedState(period: FeedPeriod.week),
        FeedState(
          period: FeedPeriod.week,
          status: SocialLoadStatus.loaded,
          posts: [p1],
        ),
      ],
      verify: (_) => verify(
        () => getFeed(
          period: FeedPeriod.week,
          since: any(named: 'since'),
          authorId: any(named: 'authorId'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).called(1),
    );
  });

  group('me gusta optimista', () {
    blocTest<FeedBloc, FeedState>(
      'marca el me gusta al instante y aplica el contador del servidor',
      setUp: () => when(() => setLike(postId: 'p1', liked: true)).thenAnswer(
        (_) async =>
            const Success(LikeStatus(postId: 'p1', liked: true, likesCount: 5)),
      ),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const FeedEvent.likeToggled('p1')),
      expect: () => [
        loaded.copyWith(posts: [p1.copyWith(likedByMe: true, likesCount: 3)]),
        loaded.copyWith(posts: [p1.copyWith(likedByMe: true, likesCount: 5)]),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'revierte el me gusta y avisa si la API falla',
      setUp: () => when(
        () => setLike(postId: 'p1', liked: true),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const FeedEvent.likeToggled('p1')),
      expect: () => [
        loaded.copyWith(posts: [p1.copyWith(likedByMe: true, likesCount: 3)]),
        loaded.copyWith(
          feedback: const SocialFeedback.error(AppError.network()),
        ),
        loaded,
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'quitar el me gusta resta uno de inmediato',
      setUp: () => when(() => setLike(postId: 'p1', liked: false)).thenAnswer(
        (_) async => const Success(
          LikeStatus(postId: 'p1', liked: false, likesCount: 1),
        ),
      ),
      build: build,
      seed: () => FeedState(
        status: SocialLoadStatus.loaded,
        posts: [p1.copyWith(likedByMe: true)],
      ),
      act: (bloc) => bloc.add(const FeedEvent.likeToggled('p1')),
      expect: () => [
        loaded.copyWith(posts: [p1.copyWith(likedByMe: false, likesCount: 1)]),
      ],
    );
  });

  group('sondeo de novedades', () {
    final p2 = post('p2', minutes: 20);

    blocTest<FeedBloc, FeedState>(
      'consulta con since = la publicación más reciente y guarda las nuevas',
      setUp: () => stubFeed(() async => Success(page([p2]))),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const FeedEvent.pollTicked()),
      expect: () => [
        loaded.copyWith(newPosts: [p2]),
      ],
      verify: (_) => verify(
        () => getFeed(
          period: FeedPeriod.all,
          since: p1.createdAt,
          authorId: any(named: 'authorId'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'ignora publicaciones ya conocidas y los fallos del sondeo',
      setUp: () => stubFeed(() async => Success(page([p1]))),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const FeedEvent.pollTicked()),
      expect: () => const <FeedState>[],
    );

    blocTest<FeedBloc, FeedState>(
      'al tocar el aviso inserta las nuevas arriba',
      build: build,
      seed: () => loaded.copyWith(newPosts: [p2]),
      act: (bloc) => bloc.add(const FeedEvent.newPostsShown()),
      expect: () => [
        loaded.copyWith(posts: [p2, p1]),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'el temporizador sondea periódicamente hasta que se detiene',
      setUp: () => stubFeed(() async => Success(page([p1]))),
      build: () => build(pollInterval: const Duration(milliseconds: 10)),
      seed: () => loaded,
      act: (bloc) async {
        bloc.add(const FeedEvent.pollingStarted());
        await Future<void>.delayed(const Duration(milliseconds: 35));
        bloc.add(const FeedEvent.pollingStopped());
      },
      wait: const Duration(milliseconds: 40),
      verify: (_) {
        final calls = verify(
          () => getFeed(
            period: any(named: 'period'),
            since: p1.createdAt,
            authorId: any(named: 'authorId'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        ).callCount;
        expect(calls, inInclusiveRange(2, 4));
      },
    );
  });

  group('publicaciones', () {
    final created = post('p9', minutes: 30, mine: true);

    blocTest<FeedBloc, FeedState>(
      'publicar añade la publicación arriba y confirma',
      setUp: () => when(
        () => createPost(
          type: any(named: 'type'),
          description: any(named: 'description'),
          imageUrl: any(named: 'imageUrl'),
        ),
      ).thenAnswer((_) async => Success(created)),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(
        const FeedEvent.postSubmitted(
          type: PostType.milestoneReached,
          description: 'Hola',
        ),
      ),
      expect: () => [
        loaded.copyWith(submitting: true),
        loaded.copyWith(
          posts: [created, p1],
          feedback: const SocialFeedback.message(SocialMessage.postCreated),
        ),
        loaded.copyWith(posts: [created, p1]),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'borrar quita la publicación',
      setUp: () => when(
        () => deletePost(postId: 'p1'),
      ).thenAnswer((_) async => const Success(unit)),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const FeedEvent.postDeleted('p1')),
      expect: () => [
        const FeedState(
          status: SocialLoadStatus.loaded,
          feedback: SocialFeedback.message(SocialMessage.postDeleted),
        ),
        const FeedState(status: SocialLoadStatus.loaded),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'reportar contenido propio muestra el error de negocio',
      setUp: () => when(() => reportPost(postId: 'p1')).thenAnswer(
        (_) async => const Failure(
          AppError.business('SOCIAL_CANNOT_REPORT_OWN_CONTENT'),
        ),
      ),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const FeedEvent.postReported('p1')),
      expect: () => [
        loaded.copyWith(
          feedback: const SocialFeedback.error(
            AppError.business('SOCIAL_CANNOT_REPORT_OWN_CONTENT'),
          ),
        ),
        loaded,
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'al volver del detalle quita la publicación si ya no existe',
      setUp: () => when(() => getPost(postId: 'p1')).thenAnswer(
        (_) async => const Failure(AppError.business('POST_NOT_FOUND')),
      ),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const FeedEvent.postRefreshRequested('p1')),
      expect: () => const [FeedState(status: SocialLoadStatus.loaded)],
    );
  });
}
