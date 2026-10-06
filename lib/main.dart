import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/api.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..boot(),
      child: const HisabKhataApp(),
    ),
  );
}

class HisabKhataApp extends StatelessWidget {
  const HisabKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'HisabKhata',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: state.themeMode,
      home: switch (state.phase) {
        Phase.booting => const _Splash(),
        Phase.signedOut => const LoginScreen(),
        Phase.noMess => const NoMessScreen(),
        Phase.offline => const _Offline(),
        Phase.ready => const HomeShell(),
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Image.asset('assets/brand/mark.png', width: 72, height: 72)),
      );
}

class _Offline extends StatelessWidget {
  const _Offline();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ErrorView(
            error: ApiException(0, 'offline', ''),
            onRetry: () => context.read<AppState>().retryBoot(),
          ),
        ),
      );
}
