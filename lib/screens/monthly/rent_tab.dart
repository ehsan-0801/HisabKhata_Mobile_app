import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api.dart';
import '../../format.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'monthly_screen.dart';

/// A money column that can be left out of the total; `deduct` = subtracted (bazar paid).
class _Col {
  const _Col(this.key, this.label, this.value, {this.deduct = false});
  final String key;
  final String label;
  final num? Function(SummaryRow r) value;
  final bool deduct;
}

/// Sum money in paisa so totals never drift by floating point.
num _sumTaka(Iterable<num> values) => values.fold<int>(0, (s, v) => s + (v * 100).round()) / 100;

/// Rent — the same as the web's Rent tab on a phone: four stats, the settlement
/// (tick boxes per bill, one card per member with every bill) and the shared bills.
class RentTab extends StatefulWidget {
  const RentTab({super.key, required this.bundle});
  final MonthBundle bundle;

  @override
  State<RentTab> createState() => _RentTabState();
}

class _RentTabState extends State<RentTab> {
  /// Columns left out of Total and Balance (view only — nothing is saved).
  final _off = <String>{};

  MonthData get data => widget.bundle.data;
  Summary get sum => data.summary;

  String _name(SummaryRow r, bool bn) {
    if (r.memberId == 0) return context.read<AppState>().s.deletedMember;
    final m = data.members.where((m) => m.id == r.memberId).firstOrNull;
    return m?.display(bn) ?? r.name;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final month = monthName(sum.month, bn);
    final mealMonth = monthName(sum.mealMonth, bn);
    final mm = monthName(sum.mealMonth, bn, short: true);
    final rate = sum.mealRate == null ? '—' : taka(sum.mealRate!);

    // Bill columns = every bill type charged to someone this month, in Bills-page order.
    final billNames = <int, String>{};
    final amountOf = <String, num>{};
    sum.charges.forEach((memberId, items) {
      for (final i in items) {
        billNames[i.billTypeId] = i.name;
        amountOf['$memberId:${i.billTypeId}'] = i.amount;
      }
    });
    final billIds = billNames.keys.toList()..sort();
    final chargeCols = <_Col>[
      _Col('meal', s.mealCostOf(mm), (r) => r.mealCost),
      for (final id in billIds) _Col('bill:$id', billNames[id]!, (r) => amountOf['${r.memberId}:$id']),
      if (sum.totalBills > 0) _Col('shared', s.sharedBills, (r) => r.billShare),
    ];
    final bazarCol = _Col('bazar', s.bazarPaidOf(mm), (r) => r.bazarPaid, deduct: true);
    bool isOn(_Col col) => !_off.contains(col.key);
    final excluded = [...chargeCols, bazarCol].where((x) => !isOn(x)).toList();
    num totalOf(SummaryRow r) => _sumTaka(chargeCols.where(isOn).map((x) => x.value(r) ?? 0));
    num balanceOf(SummaryRow r) => _sumTaka([totalOf(r), if (isOn(bazarCol)) -r.bazarPaid]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stats: 2 × 2, like the web on a phone.
        StatRow([
          StatTile(label: s.bazarOf(mm), value: taka(sum.totalBazar)),
          StatTile(label: s.mealsOf(mm), value: formatNum(sum.totalMeals)),
        ]),
        const SizedBox(height: 8),
        StatRow([
          StatTile(label: s.mealRateOf(mm), value: rate),
          StatTile(label: s.billsOf(monthName(sum.month, bn, short: true)), value: taka(sum.totalCharges + sum.totalBills)),
        ]),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.settlementTitle(month), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 14, height: 1.45, color: c.onSurfaceVariant),
                    children: [
                      TextSpan(text: s.settlementIntro(mealMonth, month, sum.totalBills > 0)),
                      TextSpan(
                        text: s.membersPage,
                        style: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
                        recognizer: TapGestureRecognizer()..onTap = () => context.read<AppState>().tab.value = 1,
                      ),
                      TextSpan(text: s.fullStop),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (sum.rows.isEmpty)
                  Text(s.rentNoMembers(month), style: TextStyle(fontSize: 14, color: c.onSurfaceVariant))
                else ...[
                  Text(s.includeInTotal, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: c.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final col in [...chargeCols, bazarCol]) _toggle(context, col, isOn(col))],
                  ),
                  if (excluded.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Brand.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text.rich(TextSpan(style: const TextStyle(fontSize: 13.5), children: [
                            TextSpan(text: s.leftOut),
                            TextSpan(text: excluded.map((x) => x.label).join(', '), style: const TextStyle(fontWeight: FontWeight.w600)),
                            TextSpan(text: s.fullStop),
                          ])),
                          GestureDetector(
                            onTap: () => setState(_off.clear),
                            child: Text(s.includeAll, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.primary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  for (final r in sum.rows) ...[
                    const SizedBox(height: 12),
                    _memberCard(context, r, chargeCols, bazarCol, isOn, totalOf(r), balanceOf(r), mm, rate),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SharedBills(data: data),
      ],
    );
  }

  /// [✓] label — a bordered box, tinted when ticked.
  Widget _toggle(BuildContext context, _Col col, bool on) {
    final c = context.colors;
    return Material(
      color: on ? c.primary.withValues(alpha: 0.10) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: c.outline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => on ? _off.add(col.key) : _off.remove(col.key)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Checkbox(
                  value: on,
                  onChanged: (v) => setState(() => v == true ? _off.remove(col.key) : _off.add(col.key)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Flexible(child: Text(col.label, style: const TextStyle(fontSize: 14))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberCard(BuildContext context, SummaryRow r, List<_Col> chargeCols, _Col bazarCol, bool Function(_Col) isOn,
      num total, num balance, String mm, String rate) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;

    Widget line(String label, String value, {required bool on, bool strong = false}) {
      final style = TextStyle(
        fontSize: 14,
        fontWeight: strong ? FontWeight.w600 : null,
        color: !on ? c.onSurfaceVariant.withValues(alpha: 0.5) : (strong ? c.onSurface : c.onSurfaceVariant),
        decoration: on ? null : TextDecoration.lineThrough,
        decorationColor: c.onSurfaceVariant.withValues(alpha: 0.4),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: style)),
            const SizedBox(width: 16),
            Text(value, style: style.copyWith(color: !on ? style.color : c.onSurface)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: c.outline), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(_name(r, bn), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              _Balance(value: balance),
            ],
          ),
          const SizedBox(height: 8),
          for (final col in chargeCols)
            if (col.value(r) != null)
              line(
                col.key == 'meal' ? s.mealLine(mm, formatNum(r.meals), rate) : col.label,
                taka(col.value(r)!),
                on: isOn(col),
              ),
          Padding(padding: const EdgeInsets.only(top: 4, bottom: 2), child: Divider(height: 1, color: c.outline)),
          line(s.total, taka(total), on: true, strong: true),
          line(bazarCol.label, '− ${taka(r.bazarPaid)}', on: isOn(bazarCol)),
        ],
      ),
    );
  }
}

/// "Pays ৳1,100" / "Gets back ৳450" / "Settled" (Bangla: "৳1,100 দেবে" / "৳450 পাবে").
class _Balance extends StatelessWidget {
  const _Balance({required this.value});
  final num value;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    if (value.abs() < 0.005) return Text(s.settled, style: TextStyle(fontSize: 14, color: c.onSurfaceVariant));
    final pays = value > 0;
    final word = TextSpan(text: pays ? s.pays : s.getsBack, style: TextStyle(color: pays ? c.onSurfaceVariant : c.primary));
    final amount = TextSpan(text: taka(value.abs()), style: TextStyle(fontWeight: FontWeight.w700, color: pays ? c.onSurface : c.primary));
    return Text.rich(
      TextSpan(style: const TextStyle(fontSize: 14), children: bn ? [amount, const TextSpan(text: ' '), word] : [word, const TextSpan(text: ' '), amount]),
    );
  }
}

/// Bills everyone splits equally this month — like the web's bills editor.
class _SharedBills extends StatefulWidget {
  const _SharedBills({required this.data});
  final MonthData data;

  @override
  State<_SharedBills> createState() => _SharedBillsState();
}

class _SharedBillsState extends State<_SharedBills> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _nameFocus = FocusNode();
  bool _busy = false;
  Map<String, List<String>> _errors = {};
  /// How many bills last month had (for "Copy N bills from …"); loaded when this month has none.
  int? _previousCount;

  String get _prev => shiftMonth(widget.data.month, -1);

  @override
  void initState() {
    super.initState();
    _loadPreviousCount();
  }

  @override
  void didUpdateWidget(_SharedBills old) {
    super.didUpdateWidget(old);
    if (old.data.month != widget.data.month || old.data.bills.length != widget.data.bills.length) _loadPreviousCount();
  }

  Future<void> _loadPreviousCount() async {
    if (widget.data.bills.isNotEmpty) return;
    try {
      final r = await context.read<AppState>().api.get('/months/$_prev/bills');
      if (mounted) setState(() => _previousCount = ((r['bills'] as List?) ?? const []).length);
    } catch (_) {/* the copy button just stays hidden */}
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<bool> _run(Future<dynamic> Function(AppState app) fn, String done) async {
    final app = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await fn(app);
      if (mounted) toast(context, done);
      app.changed();
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errors = e.fields);
        if (e.fields.isEmpty) showError(context, e);
      }
      return false;
    } catch (e) {
      if (mounted) showError(context, e);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final s = context.read<AppState>().s;
    final name = _name.text.trim();
    setState(() => _errors = {});
    final ok = await _run(
      (app) => app.api.post('/months/${widget.data.month}/bills', {'name': name, 'amount': _amount.text.trim()}),
      s.billUpdated(name),
    );
    if (ok) {
      _name.clear();
      _amount.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final canWrite = context.watch<AppState>().canWrite;
    final data = widget.data;
    final total = _sumTaka(data.bills.map((b) => b.amount));
    final n = data.members.length; // members in this month, as on the web
    final taken = data.bills.map((b) => b.name.toLowerCase()).toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.sharedTitle(monthName(data.month, bn)), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(s.sharedIntro, style: TextStyle(fontSize: 14, height: 1.45, color: c.onSurfaceVariant)),
            const SizedBox(height: 16),
            if (data.bills.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.noBills(monthName(data.month, bn)), style: TextStyle(fontSize: 14, color: c.onSurfaceVariant)),
                    if (canWrite && (_previousCount ?? 0) > 0) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run((app) => app.api.post('/months/${data.month}/bills/copy', {'fromMonth': _prev}), s.saved),
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: Text(s.copyBills(_previousCount!, monthName(_prev, bn))),
                      ),
                    ],
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(border: Border.all(color: c.outline), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    for (var i = 0; i < data.bills.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.outline),
                      _BillRow(key: ValueKey(data.bills[i].id), bill: data.bills[i], canWrite: canWrite, onRun: _run, busy: _busy),
                    ],
                  ],
                ),
              ),
            if (canWrite) ...[
              const SizedBox(height: 16),
              RawAutocomplete<String>(
                textEditingController: _name,
                focusNode: _nameFocus,
                optionsBuilder: (v) {
                  final q = v.text.trim().toLowerCase();
                  return s.presets.where((p) => !taken.contains(p.toLowerCase()) && (q.isEmpty || p.toLowerCase().contains(q)));
                },
                onSelected: (p) => _name.text = p,
                fieldViewBuilder: (context, ctrl, focus, submit) => TextField(
                  controller: ctrl,
                  focusNode: focus,
                  maxLength: 40,
                  decoration: InputDecoration(labelText: s.bill, hintText: s.billPlaceholder, counterText: '', errorText: _errors['name']?.first),
                ),
                optionsViewBuilder: (context, select, options) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [for (final o in options) ListTile(dense: true, title: Text(o), onTap: () => select(o))],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(labelText: s.amount, hintText: '0', errorText: _errors['amount']?.first),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _add,
                icon: const Icon(Icons.add),
                label: Text(_busy ? s.saving : s.addBill),
              ),
            ],
            const SizedBox(height: 16),
            Divider(height: 1, color: c.outline),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 24,
              runSpacing: 4,
              children: [
                _pair(context, s.totalBills, taka(total)),
                _pair(context, s.eachMember(n), n > 0 ? taka(((total * 100) / n).round() / 100) : '—'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pair(BuildContext context, String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: context.colors.onSurfaceVariant)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      );
}

/// Name · [৳ amount] · delete. The amount saves when you leave the box or press done.
class _BillRow extends StatefulWidget {
  const _BillRow({super.key, required this.bill, required this.canWrite, required this.onRun, required this.busy});
  final SharedBill bill;
  final bool canWrite;
  final Future<bool> Function(Future<dynamic> Function(AppState app) fn, String done) onRun;
  final bool busy;

  @override
  State<_BillRow> createState() => _BillRowState();
}

class _BillRowState extends State<_BillRow> {
  late final _ctrl = TextEditingController(text: _plain(widget.bill.amount));
  late String _saved = _ctrl.text;
  final _focus = FocusNode();
  bool _invalid = false;

  static String _plain(num n) => formatNum(n).replaceAll(',', '');

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.read<AppState>().s;
    final v = _ctrl.text.trim();
    if (v == _saved) return;
    final amount = parseAmount(v);
    if (amount == null || amount <= 0) {
      setState(() => _invalid = true);
      toast(context, s.enterValidAmount, error: true);
      return;
    }
    final ok = await widget.onRun((app) => app.api.patch('/bills/${widget.bill.id}', {'amount': amount}), s.billUpdated(widget.bill.name));
    if (mounted) {
      setState(() {
        _invalid = !ok;
        if (ok) _saved = v;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final b = widget.bill;
    if (!widget.canWrite) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(children: [
          Expanded(child: Text(b.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Text(taka(b.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        children: [
          Expanded(child: Text(b.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                prefixText: '৳ ',
                errorText: _invalid ? '' : null,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
            ),
          ),
          IconButton(
            tooltip: s.delete,
            onPressed: widget.busy
                ? null
                : () async {
                    if (!await confirm(context, title: s.deleteConfirm(b.name))) return;
                    await widget.onRun((app) => app.api.delete('/bills/${b.id}'), s.deleted);
                  },
            icon: Icon(Icons.delete_outline, color: c.error),
          ),
        ],
      ),
    );
  }
}
