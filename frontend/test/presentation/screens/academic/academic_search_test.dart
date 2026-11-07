import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/models/academic/academic_search.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/search_academic_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/academic_search/bloc/academic_search_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/academic_search/page/academic_search_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// Responde con [results] según el texto; [slow] tarda más que el resto para
/// simular una respuesta que llega tarde.
class _FakeSearch implements SearchAcademicUseCaseContract {
  final calls = <String>[];
  final pending = <String, Completer<AppResult<AcademicSearchResult>>>{};

  @override
  Future<AppResult<AcademicSearchResult>> call(String query) {
    calls.add(query);
    return (pending[query] = Completer()).future;
  }

  void answer(String query, List<AcademicSearchGroup> groups) =>
      pending[query]!.complete(
        Result.success(AcademicSearchResult(query: query, groups: groups)),
      );
}

const _subjects = AcademicSearchGroup(
  kind: AcademicSearchKind.subject,
  hits: [AcademicSearchHit(id: 's1', title: 'Física Cuántica', context: 'FQ')],
);

void main() {
  group('AcademicSearchBloc', () {
    blocTest<AcademicSearchBloc, AcademicSearchState>(
      'con menos de dos letras no busca',
      build: () => AcademicSearchBloc(search: _FakeSearch()),
      act: (bloc) => bloc.add(const AcademicSearchEvent.queryChanged(' f ')),
      expect: () => [const AcademicSearchState(query: 'f')],
    );

    test('descarta la respuesta de un texto anterior', () async {
      final search = _FakeSearch();
      final bloc = AcademicSearchBloc(search: search);
      bloc.add(const AcademicSearchEvent.queryChanged('fis'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AcademicSearchEvent.queryChanged('fisica'));
      await Future<void>.delayed(Duration.zero);
      search.answer('fisica', [_subjects]);
      await Future<void>.delayed(Duration.zero);
      search.answer('fis', const []);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.query, 'fisica');
      expect(bloc.state.status, AcademicSearchStatus.ready);
      expect(bloc.state.result!.groups, [_subjects]);
      await bloc.close();
    });
  });

  group('AcademicSearchBody', () {
    Future<AcademicSearchBloc> pump(
      WidgetTester tester,
      AcademicSearchState state,
    ) async {
      final bloc = AcademicSearchBloc(search: _FakeSearch());
      bloc.emit(state);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const AcademicSearchBody(searchField: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pump();
      addTearDown(bloc.close);
      return bloc;
    }

    testWidgets('agrupa por tipo y resalta lo buscado sin tildes', (
      tester,
    ) async {
      await pump(
        tester,
        const AcademicSearchState(
          query: 'fisica',
          status: AcademicSearchStatus.ready,
          result: AcademicSearchResult(query: 'fisica', groups: [_subjects]),
        ),
      );
      expect(find.text('Asignaturas'), findsOneWidget);
      final rich = tester.widgetList<RichText>(find.byType(RichText)).where(
        (r) => r.text.toPlainText() == 'Física Cuántica',
      );
      expect(rich, isNotEmpty);
      final spans = (rich.first.text as TextSpan).children!;
      expect((spans.first as TextSpan).children![1].toPlainText(), 'Física');
    });

    testWidgets('sin resultados propone crear el apunte', (tester) async {
      await pump(
        tester,
        const AcademicSearchState(
          query: 'termodinámica',
          status: AcademicSearchStatus.ready,
          result: AcademicSearchResult(query: 'termodinámica', groups: []),
        ),
      );
      expect(find.byType(AppSearchEmpty), findsOneWidget);
      expect(
        find.text('No hay resultados para «termodinámica»'),
        findsOneWidget,
      );
      expect(find.text('Crear apunte «termodinámica»'), findsOneWidget);
    });
  });
}
