import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../format.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'expense_tab.dart';
import 'meal_tab.dart';
import 'rent_tab.dart';

/// A month and the food-item catalog (for item names in Bangla and the item picker).
class MonthBundle {
  MonthBundle(this.data, this.items);
  final MonthData data;
  final List<Item> items;

  String itemName(String name, bool bn) {
    if (!bn) return name;
    final lower = name.toLowerCase();
    for (final i in items) {
      if (i.name.toLowerCase() == lower) return i.display(true);
    }
    return name;
  }
}

/// Monthly: month switcher, then the Expense / Meal / Rent tabs.
class MonthlyScreen extends StatefulWidget {
  const MonthlyScreen({super.key});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> with SingleTickerProviderStateMixin {
  String _month = thisMonth();
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<MonthBundle> _load(String month) async {
    final api = context.read<AppState>().api;
    final r = await Future.wait([api.get('/months/$month'), api.get('/items')]);
    return MonthBundle(
      MonthData.fromJson(r[0] as Map),
      ((r[1] as Map)['items'] as List).map((e) => Item.fromJson(e as Map)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final canWrite = context.watch<AppState>().canWrite;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabs,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [Tab(height: 36, text: s.tabExpense), Tab(height: 36, text: s.tabMeal), Tab(height: 36, text: s.tabRent)],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Loader<MonthBundle>(
            key: ValueKey(_month),
            cacheKey: 'month:$_month',
            load: () => _load(_month),
            builder: (context, bundle, reload) => TabBarView(
              controller: _tabs,
              children: [
                _Scroll(reload: reload, canWrite: canWrite, child: ExpenseTab(bundle: bundle)),
                _Scroll(reload: reload, canWrite: canWrite, child: MealTab(data: bundle.data)),
                _Scroll(reload: reload, canWrite: canWrite, child: RentTab(bundle: bundle)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({required this.reload, required this.canWrite, required this.child});
  final Future<void> Function() reload;
  final bool canWrite;
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [if (!canWrite) const ReadOnlyBanner(), child],
        ),
      );
}

/// Total bazar · total meals · meal rate for the month's own data.
class MonthStats extends StatelessWidget {
  const MonthStats({super.key, required this.bazar, required this.meals, required this.rate, this.mealsSub});
  final num bazar;
  final num meals;
  final num? rate;
  final String? mealsSub;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return StatRow([
      StatTile(label: s.totalBazar, value: taka(bazar)),
      StatTile(label: s.totalMeals, value: formatNum(meals), sub: mealsSub),
      StatTile(label: s.mealRate, value: rate == null ? '—' : taka(rate!), accent: true),
    ]);
  }
}
