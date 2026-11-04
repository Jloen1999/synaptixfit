import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/social/dto/public_profile_dto.dart';
import 'package:synaptixfit/domain/enums/badge_rarity.dart';
import 'package:synaptixfit/domain/enums/friendship_relation.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/social/public_profile.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/social/user_profile/page/public_badges_section.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

PublicProfile _profile(int badges) => PublicProfile(
  id: 'u1',
  fullName: 'Ana',
  privacy: Visibility.public,
  restricted: false,
  relation: FriendshipRelation.none,
  badges: [
    for (var i = 0; i < badges; i++)
      PublicBadge(
        id: 'b$i',
        name: 'Insignia $i',
        description: 'Completa $i sesiones',
        icon: '🔥',
        rarity: i == 0 ? BadgeRarity.epic : BadgeRarity.common,
        earnedAt: DateTime(2026, 10, 1),
      ),
  ],
);

Widget _app(PublicProfile profile) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(child: PublicBadgesSection(profile: profile)),
  ),
);

void main() {
  testWidgets('enseña las insignias y al tocar una explica qué es', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_profile(3)));
    await tester.pumpAndSettle();
    expect(find.text('3 insignias'), findsOneWidget);
    expect(find.text('Insignia 0'), findsOneWidget);

    await tester.tap(find.text('Insignia 0'));
    await tester.pumpAndSettle();
    expect(find.text('Completa 0 sesiones'), findsOneWidget);
    expect(find.textContaining('La consiguió el'), findsOneWidget);
  });

  testWidgets('con muchas se ven las primeras y «Ver las N»', (tester) async {
    await tester.pumpWidget(_app(_profile(PublicBadgesSection.visible + 2)));
    await tester.pumpAndSettle();
    expect(
      find.text('Insignia ${PublicBadgesSection.visible + 1}'),
      findsNothing,
    );
    expect(
      find.text('Ver las ${PublicBadgesSection.visible + 2}'),
      findsOneWidget,
    );
  });

  testWidgets('sin insignias no ocupa sitio', (tester) async {
    await tester.pumpWidget(_app(_profile(0)));
    expect(find.byType(Text), findsNothing);
  });

  test('un perfil restringido nunca trae insignias aunque lleguen', () {
    final dto = PublicProfileDto.fromJson({
      'id': 'u1',
      'fullName': 'Ana',
      'restricted': true,
      'badges': [
        {'id': 'b1', 'name': 'X', 'rarity': 'EPIC'},
      ],
    });
    expect(dto.toDomain().badges, isEmpty);
    final open = PublicProfileDto.fromJson({
      'id': 'u1',
      'badges': [
        {'id': 'b1', 'name': 'X', 'rarity': 'EPIC'},
      ],
    });
    expect(open.toDomain().badges.single.rarity, BadgeRarity.epic);
  });
}
