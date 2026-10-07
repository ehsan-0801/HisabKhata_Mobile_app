import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';
import 'bills_screen.dart';
import 'items_screen.dart';
import 'members_screen.dart';
import 'monthly/monthly_screen.dart';
import 'settings_screen.dart';

/// The signed-in app: header (logo + mess name, language, theme) and the bottom menu.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final ValueNotifier<int> _tab = context.read<AppState>().tab;
  int get _index => _tab.value;

  @override
  void initState() {
    super.initState();
    _tab.addListener(_onTab);
  }

  @override
  void dispose() {
    _tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() {});

  // Built lazily, then kept alive so switching tabs doesn't reload them.
  final _pages = <int, Widget>{};

  Widget _page(int i) => _pages.putIfAbsent(
        i,
        () => switch (i) {
          0 => const MonthlyScreen(),
          1 => const MembersScreen(),
          2 => const BillsScreen(),
          3 => const ItemsScreen(),
          _ => const SettingsScreen(),
        },
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandTitle(),
        actions: const [LangButton(), ThemeButton(), SizedBox(width: 4)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.colors.outline),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [for (var i = 0; i < 5; i++) _pages.containsKey(i) || i == _index ? _page(i) : const SizedBox.shrink()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => _tab.value = i,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: s.monthly),
          NavigationDestination(icon: const Icon(Icons.group_outlined), selectedIcon: const Icon(Icons.group), label: s.members),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: s.bills),
          NavigationDestination(icon: const Icon(Icons.shopping_basket_outlined), selectedIcon: const Icon(Icons.shopping_basket), label: s.itemsShort),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: s.settings),
        ],
      ),
    );
  }
}
