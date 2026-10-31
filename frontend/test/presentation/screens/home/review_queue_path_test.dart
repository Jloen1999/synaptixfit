import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/screens/home/home_external_paths.dart';

void main() {
  test('«Repasar todos» abre el primero con el resto en la cola', () {
    expect(
      HomeExternalPaths.materialReview('a', queue: ['b', 'c']),
      '/academic/materials/a/review?queue=b,c',
    );
    expect(
      HomeExternalPaths.materialReview('a'),
      '/academic/materials/a/review',
    );
  });
}
