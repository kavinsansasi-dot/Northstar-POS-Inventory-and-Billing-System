import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PosApp()));
}

class PosApp extends ConsumerStatefulWidget {
  const PosApp({super.key});

  @override
  ConsumerState<PosApp> createState() => _PosAppState();
}

class _PosAppState extends ConsumerState<PosApp> {
  late final ThemeModeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeModeController()..addListener(_updateTheme);
  }

  void _updateTheme() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeController
      ..removeListener(_updateTheme)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return ThemeModeScope(
      controller: _themeController,
      child: MaterialApp.router(
        title: 'POS Inventory',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: _themeController.mode,
        routerConfig: router,
      ),
    );
  }
}
