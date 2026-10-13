import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/theme.dart';
import 'package:flutter_app/screens/login/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({Brightness brightness = Brightness.light}) {
    return ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(brightness),
        home: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen layout tests at various resolutions', () {
    testWidgets('renders cleanly at 360x800 with no overflow (light theme)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(brightness: Brightness.light));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Sign in to your store'), findsOneWidget);
      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 360x800 with no overflow (dark theme)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(brightness: Brightness.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Sign in to your store'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 768x1024 with no overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Sign in to your store'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1280x800 with split screen and brand panel',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Brand panel features
      expect(find.text('Faster checkout'), findsOneWidget);
      expect(find.text('Smarter inventory'), findsOneWidget);
      expect(find.text('Clear insights'), findsOneWidget);
      expect(find.text('Built for growing local businesses'), findsOneWidget);
      expect(find.text('Sign in to your store'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1920x1080 with split screen and brand panel',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Faster checkout'), findsOneWidget);
      expect(find.text('Smarter inventory'), findsOneWidget);
      expect(find.text('Clear insights'), findsOneWidget);
      expect(find.text('Sign in to your store'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggles show/hide password text', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Show'), findsOneWidget);
      await tester.tap(find.text('Show'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Hide'), findsOneWidget);
    });

    testWidgets('validates required fields inline', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Sign in'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });
  });
}
