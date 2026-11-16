import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/guide_id.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/guide_progress_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/guides/mark_guide_seen_use_case.dart';
import 'package:synaptixfit/domain/use_cases/guides/reset_guides_use_case.dart';
import 'package:synaptixfit/domain/use_cases/guides/should_show_guide_use_case.dart';

/// Guías vistas en memoria, por cuenta.
class _MemoryGuides implements GuideProgressRepositoryContract {
  final seenBy = <String, Set<GuideId>>{};
  bool failing = false;
  int calls = 0;

  @override
  Future<AppResult<Set<GuideId>>> seen(String accountId) async {
    calls++;
    if (failing) return const Failure(AppError.unknown());
    return Success({...?seenBy[accountId]});
  }

  @override
  Future<AppResult<Unit>> markSeen(String accountId, GuideId guide) async {
    calls++;
    (seenBy[accountId] ??= {}).add(guide);
    return const Success(unit);
  }

  @override
  Future<AppResult<Unit>> reset(String accountId) async {
    calls++;
    seenBy.remove(accountId);
    return const Success(unit);
  }
}

/// Guías la primera vez (ADR 0049): una vez por cuenta y teléfono, y «Ver las
/// guías otra vez» las devuelve.
void main() {
  late _MemoryGuides repository;
  late ShouldShowGuideUseCase shouldShow;
  late MarkGuideSeenUseCase markSeen;
  late ResetGuidesUseCase reset;

  setUp(() {
    repository = _MemoryGuides();
    shouldShow = ShouldShowGuideUseCase(repository);
    markSeen = MarkGuideSeenUseCase(repository);
    reset = ResetGuidesUseCase(repository);
  });

  test('sale la primera vez y, vista, ya no', () async {
    expect(
      (await shouldShow(accountId: 'a', guide: GuideId.home)).valueOrNull,
      isTrue,
    );
    await markSeen(accountId: 'a', guide: GuideId.home);
    expect(
      (await shouldShow(accountId: 'a', guide: GuideId.home)).valueOrNull,
      isFalse,
    );
    // Las demás pantallas siguen teniendo la suya.
    expect(
      (await shouldShow(accountId: 'a', guide: GuideId.calendar)).valueOrNull,
      isTrue,
    );
  });

  test('cada cuenta del teléfono tiene sus guías', () async {
    await markSeen(accountId: 'a', guide: GuideId.gym);
    expect(
      (await shouldShow(accountId: 'b', guide: GuideId.gym)).valueOrNull,
      isTrue,
    );
  });

  test('«Ver las guías otra vez» las vuelve a enseñar', () async {
    await markSeen(accountId: 'a', guide: GuideId.focus);
    await reset(accountId: 'a');
    expect(
      (await shouldShow(accountId: 'a', guide: GuideId.focus)).valueOrNull,
      isTrue,
    );
  });

  test('sin cuenta no sale ni se guarda nada', () async {
    expect(
      (await shouldShow(accountId: '', guide: GuideId.home)).valueOrNull,
      isFalse,
    );
    await markSeen(accountId: '', guide: GuideId.home);
    await reset(accountId: '');
    expect(repository.calls, 0);
  });

  test('si no se puede leer, devuelve el error', () async {
    repository.failing = true;
    final result = await shouldShow(accountId: 'a', guide: GuideId.subject);
    expect(result.isSuccess, isFalse);
    expect(result.fold((_) => null, (e) => e), const AppError.unknown());
  });
}
