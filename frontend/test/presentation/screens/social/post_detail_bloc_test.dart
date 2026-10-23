import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/like_status.dart';
import 'package:synaptixfit/domain/use_cases/social/delete_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/edit_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/get_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/report_post_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/set_post_like_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/post_detail/bloc/post_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/widgets/social_feedback.dart';

import 'social_fixtures.dart';

class _Get extends Mock implements GetPostUseCaseContract {}

class _Edit extends Mock implements EditPostUseCaseContract {}

class _Delete extends Mock implements DeletePostUseCaseContract {}

class _Report extends Mock implements ReportPostUseCaseContract {}

class _Like extends Mock implements SetPostLikeUseCaseContract {}

void main() {
  late _Get get;
  late _Edit edit;
  late _Delete delete;
  late _Report report;
  late _Like like;

  setUp(() {
    get = _Get();
    edit = _Edit();
    delete = _Delete();
    report = _Report();
    like = _Like();
  });

  PostDetailBloc build() => PostDetailBloc(
    getPost: get,
    editPost: edit,
    deletePost: delete,
    reportPost: report,
    setLike: like,
  );

  final p1 = post('p1', likes: 1, mine: true);
  final loaded = PostDetailState(
    postId: 'p1',
    status: SocialLoadStatus.loaded,
    post: p1,
  );

  blocTest<PostDetailBloc, PostDetailState>(
    'carga la publicación',
    setUp: () =>
        when(() => get(postId: 'p1')).thenAnswer((_) async => Success(p1)),
    build: build,
    act: (bloc) => bloc.add(const PostDetailEvent.started('p1')),
    expect: () => [const PostDetailState(postId: 'p1'), loaded],
  );

  blocTest<PostDetailBloc, PostDetailState>(
    'una publicación no visible muestra POST_NOT_FOUND',
    setUp: () => when(() => get(postId: 'p1')).thenAnswer(
      (_) async => const Failure(AppError.business('POST_NOT_FOUND')),
    ),
    build: build,
    act: (bloc) => bloc.add(const PostDetailEvent.started('p1')),
    expect: () => const [
      PostDetailState(postId: 'p1'),
      PostDetailState(
        postId: 'p1',
        status: SocialLoadStatus.failure,
        error: AppError.business('POST_NOT_FOUND'),
      ),
    ],
  );

  blocTest<PostDetailBloc, PostDetailState>(
    'me gusta optimista en el detalle',
    setUp: () => when(() => like(postId: 'p1', liked: true)).thenAnswer(
      (_) async =>
          const Success(LikeStatus(postId: 'p1', liked: true, likesCount: 2)),
    ),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const PostDetailEvent.likeToggled()),
    expect: () => [
      loaded.copyWith(post: p1.copyWith(likedByMe: true, likesCount: 2)),
    ],
  );

  blocTest<PostDetailBloc, PostDetailState>(
    'borrar marca la publicación como eliminada',
    setUp: () => when(
      () => delete(postId: 'p1'),
    ).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const PostDetailEvent.deleted()),
    expect: () => [
      loaded.copyWith(
        deleted: true,
        feedback: const SocialFeedback.message(SocialMessage.postDeleted),
      ),
      loaded.copyWith(deleted: true),
    ],
  );
}
