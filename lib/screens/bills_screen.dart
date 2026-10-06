import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Bills: the bill types (house rent, maid, WiFi…) and who pays what in a month.
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String _month = thisMonth();

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Loader<List<BillType>>(
      load: () async => ((await app.api.get('/bill-types'))['billTypes'] as List).map((e) => BillType.fromJson(e as Map)).toList(),
      builder: (context, types, reload) {
        final s = context.s;
        final canWrite = context.watch<AppState>().canWrite;
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              PageHeader(s.bills, intro: s.billsIntro),
              if (!canWrite) const ReadOnlyBanner(),
              if (canWrite) ...[
                _AddNameField(
                  hint: s.billPlaceholder,
                  label: s.newBill,
                  onAdd: (name) => app.api.post('/bill-types', {'name': name}),
                ),
                const SizedBox(height: 12),
              ],
              SectionCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: types.isEmpty
                    ? EmptyState(title: s.none(s.billNouns), icon: Icons.receipt_long_outlined)
                    : Column(
                        children: [
                          for (var i = 0; i < types.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _BillTypeTile(type: types[i], canWrite: canWrite),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              _WhoPays(month: _month, onMonth: (m) => setState(() => _month = m)),
            ],
          ),
        );
      },
    );
  }
}

class _BillTypeTile extends StatelessWidget {
  const _BillTypeTile({required this.type, required this.canWrite});
  final BillType type;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final t = type;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        t.members > 0 ? s.chargedTo(t.members) : (t.used ? s.notChargedNow : s.notUsed),
        style: TextStyle(fontSize: 12.5, color: c.onSurfaceVariant),
      ),
      trailing: !canWrite
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: s.rename,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () async {
                    final app = context.read<AppState>();
                    final names = await renameDialog(context, title: s.rename, name: t.name);
                    if (names == null || !context.mounted) return;
                    await runAndRefresh(context, () => app.api.patch('/bill-types/${t.id}', {'name': names.$1}), s.saved);
                  },
                ),
                IconButton(
                  tooltip: t.used ? s.billLocked : s.delete,
                  icon: Icon(Icons.delete_outline, size: 20, color: t.used ? c.outline : c.error),
                  onPressed: t.used
                      ? () => toast(context, s.billLocked)
                      : () async {
                          final app = context.read<AppState>();
                          if (!await confirm(context, title: s.deleteConfirm(t.name)) || !context.mounted) return;
                          await runAndRefresh(context, () => app.api.delete('/bill-types/${t.id}'), s.deleted);
                        },
                ),
              ],
            ),
    );
  }
}

/// Who pays which bill in a month.
class _WhoPays extends StatelessWidget {
  const _WhoPays({required this.month, required this.onMonth});
  final String month;
  final ValueChanged<String> onMonth;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final app = context.read<AppState>();
    return SectionCard(
      title: s.whoPays(monthName(month, bn)),
      subtitle: s.whoPaysIntro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthSwitcher(month: month, onChanged: onMonth),
          const SizedBox(height: 8),
          Loader<List<MemberCharges>>(
              key: ValueKey(month),
              load: () async => (((await app.api.get('/months/$month/charges'))['members'] as List?) ?? const [])
                  .map((e) => MemberCharges.fromJson(e as Map))
                  .toList(),
              builder: (context, rows, _) {
                if (rows.isEmpty) return EmptyState(title: s.whoPaysEmpty, icon: Icons.receipt_long_outlined);
                final grand = rows.fold<num>(0, (a, r) => a + r.total);
                return Column(
                  children: [
                    for (final r in rows)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: c.outline), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Row(children: [
                              Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                              Text(taka(r.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ]),
                            for (final ch in r.charges)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 12),
                                child: Row(children: [
                                  Expanded(child: Text(ch.name, style: TextStyle(fontSize: 13, color: c.onSurfaceVariant))),
                                  Text(taka(ch.amount), style: TextStyle(fontSize: 13, color: c.onSurfaceVariant)),
                                ]),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Text(s.total, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(taka(grand), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ]),
                  ],
                );
              },
          ),
        ],
      ),
    );
  }
}

/// A one-line "name + Add" form for catalogs.
class _AddNameField extends StatefulWidget {
  const _AddNameField({required this.label, required this.hint, required this.onAdd});
  final String label;
  final String hint;
  final Future<dynamic> Function(String name) onAdd;

  @override
  State<_AddNameField> createState() => _AddNameFieldState();
}

class _AddNameFieldState extends State<_AddNameField> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    final ok = await runAndRefresh(context, () => widget.onAdd(name), context.read<AppState>().s.saved);
    if (ok) _ctrl.clear();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _busy ? null : _add, icon: const Icon(Icons.add), label: Text(context.s.add)),
        ],
      );
}
