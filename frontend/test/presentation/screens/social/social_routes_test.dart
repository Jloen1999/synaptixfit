import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/screens/social/social_routes.dart';

void main() {
  test(
    'los enlaces a raíces de pestaña cambian de pestaña; el resto se apila',
    () {
      expect(SocialExternalPaths.isTabRoot('/training'), isTrue);
      expect(SocialExternalPaths.isTabRoot('/progress'), isTrue);
      expect(SocialExternalPaths.isTabRoot('/challenges'), isTrue);
      expect(
        SocialExternalPaths.isTabRoot('/challenges?tab=community'),
        isTrue,
      );

      expect(SocialExternalPaths.isTabRoot('/challenges/c1'), isFalse);
      expect(SocialExternalPaths.isTabRoot('/profile'), isFalse);
      expect(SocialExternalPaths.isTabRoot('/social/posts/p1'), isFalse);
    },
  );

  test(
    'las rutinas enlazadas viven en la pestaña Entreno: se abren con go',
    () {
      expect(SocialExternalPaths.opensInTab('/training/routines/r1'), isTrue);
      expect(SocialExternalPaths.opensInTab('/training/exercises/e1'), isTrue);
      expect(SocialExternalPaths.opensInTab('/challenges/c1'), isFalse);
      expect(SocialExternalPaths.opensInTab('/progress/badges'), isFalse);
    },
  );
}
