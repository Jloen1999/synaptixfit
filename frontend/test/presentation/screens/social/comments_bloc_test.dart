import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/social/add_comment_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/delete_comment_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/edit_comment_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/get_comments_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/report_comment_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/comments/bloc/comments_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/widgets/social_feedback.dart';

import 'social_fixtures.dart';

class _Get extends Mock implements GetCommentsUseCaseContract {}

class _Add extends Mock implements AddCommentUseCaseContract {}

class _Edit extends Mock implements EditCommentUseCaseContract {}

class _Delete extends Mock implements DeleteCommentUseCaseContract {}

class _Report extends Mock implements ReportCommentUseCaseContract {}

void main() {
  late _Get get;
  late _Add add;
  late _Edit edit;
  late _Delete delete;
  late _Report report;

  setUp(() {
    get = _Get();
    add = _Add();
    edit = _Edit();
    delete = _Delete();
    report = _Report();
  });

  CommentsBloc build() => CommentsBloc(
    getComments: get,
    addComment: add,
    editComment: edit,
    deleteComment: delete,
    reportComment: report,
  );

  final c1 = comment('c1');
  final loaded = CommentsState(
    postId: 'p1',
    status: SocialLoadStatus.loaded,
    comments: [c1],
    totalCount: 1,
  );

  blocTest<CommentsBloc, CommentsState>(
    'carga los comentarios de la publicación',
    setUp: () => when(
      () => get(
        postId: 'p1',
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Success(page([c1]))),
    build: build,
    act: (bloc) => bloc.add(const CommentsEvent.started('p1')),
    expect: () => [const CommentsState(postId: 'p1'), loaded],
  );

  blocTest<CommentsBloc, CommentsState>(
    'emite failure si no se pueden cargar',
    setUp: () =>
        when(
          () => get(
            postId: 'p1',
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        ).thenAnswer(
          (_) async => const Failure(AppError.business('POST_NOT_FOUND')),
        ),
    build: build,
    act: (bloc) => bloc.add(const CommentsEvent.started('p1')),
    expect: () => const [
      CommentsState(postId: 'p1'),
      CommentsState(
        postId: 'p1',
        status: SocialLoadStatus.failure,
        error: AppError.business('POST_NOT_FOUND'),
      ),
    ],
  );

  blocTest<CommentsBloc, CommentsState>(
    'enviar añade el comentario al final y aumenta el total',
    setUp: () => when(
      () => add(postId: 'p1', text: 'Genial'),
    ).thenAnswer((_) async => Success(comment('c2', mine: true))),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const CommentsEvent.submitted('  Genial ')),
    expect: () => [
      loaded.copyWith(sending: true),
      loaded.copyWith(
        comments: [c1, comment('c2', mine: true)],
        totalCount: 2,
        sentCount: 1,
      ),
    ],
  );

  blocTest<CommentsBloc, CommentsState>(
    'borrar quita el comentario y confirma',
    setUp: () => when(
      () => delete(commentId: 'c1'),
    ).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const CommentsEvent.deleted('c1')),
    expect: () => [
      loaded.copyWith(
        comments: [],
        totalCount: 0,
        feedback: const SocialFeedback.message(SocialMessage.commentDeleted),
      ),
      loaded.copyWith(comments: [], totalCount: 0),
    ],
  );

  blocTest<CommentsBloc, CommentsState>(
    'editar un comentario ajeno muestra COMMENT_FORBIDDEN',
    setUp: () => when(() => edit(commentId: 'c1', text: 'x')).thenAnswer(
      (_) async => const Failure(AppError.business('COMMENT_FORBIDDEN')),
    ),
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(const CommentsEvent.edited(commentId: 'c1', text: 'x')),
    expect: () => [
      loaded.copyWith(
        feedback: const SocialFeedback.error(
          AppError.business('COMMENT_FORBIDDEN'),
        ),
      ),
      loaded,
    ],
  );
}
