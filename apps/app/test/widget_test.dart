import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder test', (tester) async {
    await tester.pumpWidget(const SizedBox());
  });
}
