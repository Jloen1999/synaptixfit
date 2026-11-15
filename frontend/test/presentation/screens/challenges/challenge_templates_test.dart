import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/challenges/dto/challenge_dto.dart';
import 'package:synaptixfit/domain/enums/challenge_difficulty.dart';
import 'package:synaptixfit/domain/enums/challenge_rule_kind.dart';
import 'package:synaptixfit/domain/enums/challenge_status.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/enums/visibility.dart' as vis;
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/challenges/challenge.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_rule.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_template.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_challenge_templates_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/start_challenge_template_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenge_templates/bloc/challenge_templates_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/widgets/challenge_labels.dart';

const _rule = ChallengeRule(
  metric: ChallengeRuleMetric.reviews,
  unit: ChallengeRuleUnit.day,
  perUnit: 1,
  target: 12,
);

const _template = ChallengeTemplate(
  id: 'tp1',
  code: 'repasa_cada_dia',
  title: 'Repasa cada día',
  goal: 'Un repaso al día',
  type: ChallengeType.academic,
  difficulty: ChallengeDifficulty.medium,
  days: 14,
  rule: _rule,
);

final _challenge = Challenge(
  id: 'c1',
  ownerId: 'u1',
  owned: true,
  title: 'Repasa cada día',
  type: ChallengeType.academic,
  visibility: vis.Visibility.private,
  difficulty: ChallengeDifficulty.medium,
  xpReward: 40,
  xpAwarded: 0,
  completed: false,
  status: ChallengeStatus.active,
  progress: 0,
  startAt: DateTime(2026, 11, 15),
  endAt: DateTime(2026, 11, 28),
  currentStreak: 0,
  bestStreak: 0,
  hasDependencies: false,
  milestoneCount: 0,
  completedMilestoneCount: 0,
  rule: _rule.copyWith(met: 5),
  tracksRule: true,
  templateCode: 'repasa_cada_dia',
);

class _List implements ListChallengeTemplatesUseCaseContract {
  @override
  Future<AppResult<List<ChallengeTemplate>>> call() async =>
      const Success([_template]);
}

class _Start implements StartChallengeTemplateUseCaseContract {
  _Start({this.fail = false});

  final bool fail;

  @override
  Future<AppResult<Challenge>> call(String templateId) async => fail
      ? const Failure(AppError.business('CHALLENGE_TEMPLATE_ALREADY_ACTIVE'))
      : Success(_challenge);
}

void main() {
  group('Plantillas de retos (ADR 0043)', () {
    blocTest<ChallengeTemplatesBloc, ChallengeTemplatesState>(
      'empezar crea el reto una vez y marca la plantilla en marcha',
      build: () => ChallengeTemplatesBloc(list: _List(), start: _Start()),
      seed: () => const ChallengeTemplatesState(
        status: ChallengeTemplatesStatus.ready,
        templates: [_template],
      ),
      act: (bloc) => bloc.add(
        const ChallengeTemplatesEvent.startRequested('tp1'),
      ),
      expect: () => [
        isA<ChallengeTemplatesState>().having(
          (s) => s.startingId,
          'ocupado',
          'tp1',
        ),
        isA<ChallengeTemplatesState>()
            .having((s) => s.started, 'empezado', _challenge)
            .having((s) => s.templates.single.running, 'en marcha', isTrue),
        isA<ChallengeTemplatesState>().having(
          (s) => s.started,
          'consumido',
          null,
        ),
      ],
    );

    blocTest<ChallengeTemplatesBloc, ChallengeTemplatesState>(
      'si ya hay uno en marcha avisa del error y no cambia la lista',
      build: () => ChallengeTemplatesBloc(
        list: _List(),
        start: _Start(fail: true),
      ),
      seed: () => const ChallengeTemplatesState(
        status: ChallengeTemplatesStatus.ready,
        templates: [_template],
      ),
      act: (bloc) => bloc.add(
        const ChallengeTemplatesEvent.startRequested('tp1'),
      ),
      verify: (bloc) {
        expect(bloc.state.startingId, isNull);
        expect(bloc.state.templates.single.running, isFalse);
      },
    );

    test('el reto de plantilla se cuenta solo y lee su regla', () {
      final dto = ChallengeDto.fromJson({
        'id': 'c1',
        'ownerId': 'u1',
        'title': 'Un Pomodoro al día',
        'startAt': '2026-11-15T08:00:00Z',
        'endAt': '2026-11-21T22:59:59Z',
        'tracksRule': true,
        'templateCode': 'pomodoro_diario',
        'rule': {
          'metric': 'FOCUS_MINUTES',
          'unit': 'DAY',
          'perUnit': 25,
          'target': 5,
          'met': 2,
        },
      }).toDomain();
      expect(dto.countsItself, isTrue);
      expect(dto.rule!.metric, ChallengeRuleMetric.focusMinutes);
      expect(dto.rule!.met, 2);
      expect(
        ChallengeRuleMetric.fromApi('NUEVA_METRICA'),
        ChallengeRuleMetric.unknown,
      );
    });

    testWidgets('la regla se lee en palabras: días, horas y carreras', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(_rule.copyWith(met: 5).progressText(ctx), '5 de 12 días');
      expect(
        const ChallengeRule(
          metric: ChallengeRuleMetric.focusMinutes,
          unit: ChallengeRuleUnit.total,
          perUnit: 1,
          target: 600,
        ).goalText(ctx),
        '10 h',
      );
      const focus = ChallengeRule(
        metric: ChallengeRuleMetric.focusMinutes,
        unit: ChallengeRuleUnit.total,
        perUnit: 1,
        target: 600,
      );
      // La misma unidad a los dos lados: horas solo si las dos son exactas.
      expect(focus.copyWith(met: 300).progressText(ctx), '5 de 10 h');
      expect(focus.copyWith(met: 290).progressText(ctx), '290 de 600 min');
      expect(focus.copyWith(met: 290).leftText(ctx), 'Te faltan 310 min');
      expect(_rule.copyWith(met: 5).leftText(ctx), 'Te faltan 7 días');
      expect(
        const ChallengeRule(
          metric: ChallengeRuleMetric.runs,
          unit: ChallengeRuleUnit.total,
          perUnit: 1,
          target: 18,
          met: 30,
        ).progressText(ctx),
        '18 de 18 carreras',
      );
      expect(
        const ChallengeRule(
          metric: ChallengeRuleMetric.earlyFocus,
          unit: ChallengeRuleUnit.day,
          perUnit: 1,
          target: 8,
          weekdaysOnly: true,
        ).goalText(ctx),
        '8 días laborables',
      );
    });
  });
}
