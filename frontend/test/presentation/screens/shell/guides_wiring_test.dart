import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Cada pantalla con guía (ADR 0049) la monta con su `GuideId`: así sale una
/// vez en cada una (el mecanismo se prueba en `first_time_guide_test.dart`).
/// Y lo que abre un aviso o la sala en marcha no la enseña esa vez.
void main() {
  const pages = {
    'liveSession':
        'lib/presentation/screens/training/live_session/page/live_session_page.dart',
    'home':
        'lib/presentation/screens/home/dashboard/page/home_dashboard_page.dart',
    'calendar':
        'lib/presentation/screens/planner/calendar/page/calendar_page.dart',
    'gym':
        'lib/presentation/screens/training/training_home/page/training_home_page.dart',
    'focus':
        'lib/presentation/screens/planner/pomodoro/page/pomodoro_page.dart',
    'academic':
        'lib/presentation/screens/academic/academic_home/page/academic_home_page.dart',
    'subject':
        'lib/presentation/screens/academic/subject_detail/page/subject_detail_page.dart',
  };

  for (final MapEntry(key: guide, value: path) in pages.entries) {
    test('$guide monta su guía la primera vez', () {
      final source = File(path).readAsStringSync();
      expect(source, contains('FirstTimeGuide('));
      expect(source, contains('guide: GuideId.$guide,'));
    });
  }

  for (final path in [
    'lib/presentation/screens/shell/widgets/reminders_host.dart',
    'lib/presentation/screens/shell/widgets/together_live_host.dart',
  ]) {
    test('$path avisa de que se llega desde fuera', () {
      expect(File(path).readAsStringSync(), contains('markExternalArrival()'));
    });
  }
}
