import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/notifications/delete_notification_use_case.dart';
import 'package:synaptixfit/domain/use_cases/notifications/get_notifications_use_case.dart';
import 'package:synaptixfit/domain/use_cases/notifications/mark_all_notifications_read_use_case.dart';
import 'package:synaptixfit/domain/use_cases/notifications/mark_notification_read_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/notifications/bloc/notifications_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/widgets/social_feedback.dart';

import 'social_fixtures.dart';

class _Get extends Mock implements GetNotificationsUseCaseContract {}

class _Read extends Mock implements MarkNotificationReadUseCaseContract {}

class _ReadAll extends Mock
    implements MarkAllNotificationsReadUseCaseContract {}

class _Delete extends Mock implements DeleteNotificationUseCaseContract {}

void main() {
  late _Get get;
  late _Read read;
  late _ReadAll readAll;
  late _Delete delete;

  setUp(() {
    get = _Get();
    read = _Read();
    readAll = _ReadAll();
    delete = _Delete();
  });

  NotificationsBloc build() => NotificationsBloc(
    getNotifications: get,
    markRead: read,
    markAllRead: readAll,
    deleteNotification: delete,
  );

  final n1 = notification('n1');
  final n2 = notification('n2', read: true);
  final loaded = NotificationsState(
    status: SocialLoadStatus.loaded,
    items: [n1, n2],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'el filtro de no leídas recarga con unreadOnly',
    setUp: () => when(
      () => get(
        unreadOnly: true,
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Success(page([n1]))),
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(const NotificationsEvent.filterChanged(unreadOnly: true)),
    expect: () => [
      const NotificationsState(unreadOnly: true),
      NotificationsState(
        unreadOnly: true,
        status: SocialLoadStatus.loaded,
        items: [n1],
      ),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'emite failure si falla la carga',
    setUp: () => when(
      () => get(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => const Failure(AppError.server())),
    build: build,
    act: (bloc) => bloc.add(const NotificationsEvent.started()),
    expect: () => const [
      NotificationsState(),
      NotificationsState(
        status: SocialLoadStatus.failure,
        error: AppError.server(),
      ),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'abrir marca como leída de forma optimista',
    setUp: () => when(
      () => read(notificationId: 'n1'),
    ).thenAnswer((_) async => Success(n1.copyWith(read: true))),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const NotificationsEvent.opened('n1')),
    expect: () => [
      loaded.copyWith(items: [n1.copyWith(read: true), n2]),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'marcar todas deja la lista leída',
    setUp: () =>
        when(() => readAll()).thenAnswer((_) async => const Success(1)),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const NotificationsEvent.allMarkedRead()),
    expect: () => [
      loaded.copyWith(markingAll: true),
      loaded.copyWith(
        items: [n1.copyWith(read: true), n2],
        feedback: const SocialFeedback.message(
          SocialMessage.allNotificationsRead,
        ),
      ),
      loaded.copyWith(items: [n1.copyWith(read: true), n2]),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'borrar con error repone la notificación',
    setUp: () => when(() => delete(notificationId: 'n1')).thenAnswer(
      (_) async => const Failure(AppError.business('NOTIFICATION_NOT_FOUND')),
    ),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const NotificationsEvent.deleted('n1')),
    expect: () => [
      loaded.copyWith(items: [n2]),
      loaded.copyWith(
        feedback: const SocialFeedback.error(
          AppError.business('NOTIFICATION_NOT_FOUND'),
        ),
      ),
      loaded,
    ],
  );
}
