import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabkhata/screens/login_screen.dart';
import 'package:hisabkhata/state/app_state.dart';
import 'package:hisabkhata/theme.dart';
import 'package:provider/provider.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('login screen renders with its background ($brightness)', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(theme: buildTheme(brightness), home: const LoginScreen()),
      ));
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
