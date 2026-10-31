import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:synaptixfit/domain/enums/notification_message_code.dart';
import 'package:synaptixfit/domain/enums/notification_priority.dart';
import 'package:synaptixfit/domain/enums/notification_type.dart';
import 'package:synaptixfit/domain/models/social/app_notification.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/social/notifications/widgets/notification_texts.dart';

void main() {
  final base = AppNotification(
    id: 'n1',
    title: 'Riesgo de sobreentrenamiento',
    description: 'Texto guardado',
    priority: NotificationPriority.recommended,
    type: NotificationType.fatigueAlert,
    actionLabel: 'Ver indicadores',
    read: false,
    createdAt: DateTime(2026, 10, 24),
  );

  test('sin código se muestra el texto guardado', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));
    final texts = notificationTexts(l10n, base);
    expect(texts.title, base.title);
    expect(texts.description, 'Texto guardado');
  });

  test('con código se escribe en el idioma de la app', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));
    Intl.defaultLocale = 'es';
    final texts = notificationTexts(
      l10n,
      base.copyWith(
        messageCode: NotificationMessageCode.overtraining,
        messageParams: const {'ratio': '1.73'},
      ),
    );
    expect(texts.title, 'Riesgo de sobreentrenamiento');
    expect(texts.description, contains('1,73'));
    expect(texts.action, 'Ver indicadores');
  });
}
