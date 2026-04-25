import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/main.dart';

void main() {
  testWidgets('La app inicia y renderiza MaterialApp.router', (WidgetTester tester) async {
    await tester.pumpWidget(const SynaptixFitApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
