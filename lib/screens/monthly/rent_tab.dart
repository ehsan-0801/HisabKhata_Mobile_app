import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../format.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'monthly_screen.dart';

enum _Col { mealCost, charges, shared, bazar }

/// Rent: the month's settlement (last month's meals + this month's bills) with the
/// full bill breakdown per member, and the shared bills split equally.
class RentTab extends StatefulWidget {
  const RentTab({super.key, required this.bundle});
  final MonthBundle bundle;

  @override
  State<RentTab> createState() => _RentTabState();
}

class _RentTabState extends State<RentTab> {
  /// Columns counted in the total and balance (untick to leave one out, like the web table).
  final _on = {..._Col.values};

  Summary get sum => widget.bundle.data.summary;
  MonthData get data => widget.bundle.data;

  String _name(SummaryRow r, bool bn) {
    if (r.memberId == 0) return context.read<AppState>().s.deletedMember;
    final m = data.members.where((m) => m.id == r.memberId).firstOrNull;
    return m?.display(bn) ?? r.name;
  }

  num _total(SummaryRow r) =>
      (_on.contains(_Col.mealCost) ? r.mealCost : 0) + (_on.contains(_Col.charges) ? r.charges : 0) + (_on.contains(_Col.shared) ? r.billShare : 0);

  num _balance(SummaryRow r) => _total(r) - (_on.contains(_Col.bazar) ? r.bazarPaid : 0);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final month = monthName(sum.month, bn);
    final mealMonth = monthName(sum.mealMonth, bn);
    final rate = sum.mealRate;
    final labels = {
      _Col.mealCost: s.mealCostOf(monthName(sum.mealMonth, bn, short: true)),
      _Col.charges: s.personalBills,
      _Col.shared: s.sharedBills,
      _Col.bazar: s.bazarPaidOf(monthName(sum.mealMonth, bn, short: true)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatRow([
          StatTile(label: s.mealRate, value: rate == null ? '—' : taka(rate), sub: mealMonth, accent: true),
          StatTile(label: s.personalBills, value: taka(sum.totalCharges), sub: month),
          StatTile(label: s.sharedBills, value: taka(sum.totalBills), sub: '${taka(sum.billPerMember)} × ${sum.memberCount}'),
        ]),
        const SizedBox(height: 12),
        SectionCard(
          title: s.settlementTitle(month),
          subtitle: s.settlementIntro(mealMonth, month),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.includeInTotal, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final col in _Col.values)
                    FilterChip(
                      label: Text(labels[col]!, style: const TextStyle(fontSize: 12.5)),
                      selected: _on.contains(col),
                      onSelected: (v) => setState(() => v ? _on.add(col) : _on.remove(col)),
                    ),
                ],
              ),
              if (_on.length < _Col.values.length) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.leftOut + _Col.values.where((x) => !_on.contains(x)).map((x) => labels[x]).join(', '),
                        style: TextStyle(fontSize: 12, color: c.error),
                      ),
                    ),
                    TextButton(onPressed: () => setState(() => _on.addAll(_Col.values)), child: Text(s.includeAll)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              if (sum.rows.isEmpty)
                EmptyState(title: s.rentNoMembers(month), icon: Icons.group_outlined)
              else ...[
                for (final r in sum.rows) _memberCard(context, r, labels),
                const SizedBox(height: 4),
                _grandTotal(context),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SharedBills(data: data),
      ],
    );
  }

  Widget _memberCard(BuildContext context, SummaryRow r, Map<_Col, String> labels) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final bal = _balance(r);
    final charges = sum.charges[r.memberId] ?? const <Charge>[];
    final rate = sum.mealRate;

    Widget line(String label, num amount, {bool on = true, bool minus = false, bool strong = false, double indent = 0}) => Padding(
          padding: EdgeInsets.only(left: indent, top: 3, bottom: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: strong ? 13.5 : 13,
                      fontWeight: strong ? FontWeight.w600 : null,
                      color: on ? (indent > 0 ? c.onSurfaceVariant : null) : c.onSurfaceVariant,
                      decoration: on ? null : TextDecoration.lineThrough,
                    )),
              ),
              Text(
                '${minus ? '− ' : ''}${taka(amount)}',
                style: TextStyle(
                  fontSize: strong ? 13.5 : 13,
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                  color: on ? (indent > 0 ? c.onSurfaceVariant : null) : c.onSurfaceVariant,
                  decoration: on ? null : TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: c.outline), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(_name(r, bn), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
              _balancePill(context, bal),
            ],
          ),
          const SizedBox(height: 8),
          line(labels[_Col.mealCost]!, r.mealCost, on: _on.contains(_Col.mealCost)),
          if (r.meals > 0 && rate != null)
            line(s.mealLine(monthName(sum.mealMonth, bn, short: true), formatNum(r.meals), taka(rate)), r.mealCost,
                on: _on.contains(_Col.mealCost), indent: 12),
          line(s.personalBills, r.charges, on: _on.contains(_Col.charges)),
          for (final ch in charges) line(ch.name, ch.amount, on: _on.contains(_Col.charges), indent: 12),
          if (sum.totalBills > 0) line(s.sharedBills, r.billShare, on: _on.contains(_Col.shared)),
          if (sum.totalBills > 0)
            for (final b in data.bills)
              line(b.name, sum.memberCount > 0 ? b.amount / sum.memberCount : 0, on: _on.contains(_Col.shared), indent: 12),
          const Divider(height: 14),
          line(s.total, _total(r), strong: true),
          line(labels[_Col.bazar]!, r.bazarPaid, on: _on.contains(_Col.bazar), minus: true),
          const Divider(height: 14),
          Row(
            children: [
              Expanded(child: Text(s.balance, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(
                taka(bal.abs()),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: bal > 0.004 ? Brand.pays(context) : (bal < -0.004 ? Brand.getsBack(context) : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balancePill(BuildContext context, num bal) {
    final s = context.s;
    if (bal > 0.004) return Pill(s.pays, color: Brand.pays(context));
    if (bal < -0.004) return Pill(s.getsBack, color: Brand.getsBack(context));
    return Pill(s.settled, color: context.colors.onSurfaceVariant);
  }

  Widget _grandTotal(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final total = sum.rows.fold<num>(0, (a, r) => a + _total(r));
    final bazar = _on.contains(_Col.bazar) ? sum.rows.fold<num>(0, (a, r) => a + r.bazarPaid) : 0;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: Text(s.total, style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(taka(total), style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          if (bazar > 0) ...[
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(s.bazarPaidOf(monthName(sum.mealMonth, context.bn, short: true)), style: TextStyle(fontSize: 13, color: c.onSurfaceVariant))),
              Text('− ${taka(bazar)}', style: TextStyle(fontSize: 13, color: c.onSurfaceVariant)),
            ]),
          ],
        ],
      ),
    );
  }
}

/// Bills everyone splits equally this month.
class _SharedBills extends StatefulWidget {
  const _SharedBills({required this.data});
  final MonthData data;

  @override
  State<_SharedBills> createState() => _SharedBillsState();
}

class _SharedBillsState extends State<_SharedBills> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  bool _busy = false;
  String? _nameError, _amountError;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AppState app) fn, String done) async {
    final app = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await fn(app);
      if (!mounted) return;
      toast(context, done);
      app.changed();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final s = context.read<AppState>().s;
    final amount = parseAmount(_amount.text);
    setState(() {
      _nameError = _name.text.trim().isEmpty ? s.billPlaceholder : null;
      _amountError = amount == null || amount <= 0 ? s.enterValidAmount : null;
    });
    if (_nameError != null || _amountError != null) return;
    final name = _name.text.trim();
    await _run((app) async {
      await app.api.post('/months/${widget.data.month}/bills', {'name': name, 'amount': amount});
      _name.clear();
      _amount.clear();
    }, s.billUpdated(name));
  }

  Future<void> _edit(SharedBill b) async {
    final s = context.read<AppState>().s;
    final ctrl = TextEditingController(text: formatNum(b.amount).replaceAll(',', ''));
    final v = await showDialog<num>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(b.name),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: s.amount, prefixText: '৳ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              final n = parseAmount(ctrl.text);
              if (n != null && n > 0) Navigator.pop(c, n);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (v == null) return;
    await _run((app) => app.api.patch('/bills/${b.id}', {'amount': v}), s.billUpdated(b.name));
  }

  Future<void> _delete(SharedBill b) async {
    final s = context.read<AppState>().s;
    if (!await confirm(context, title: s.deleteConfirm(b.name))) return;
    await _run((app) => app.api.delete('/bills/${b.id}'), s.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final canWrite = context.watch<AppState>().canWrite;
    final data = widget.data;
    final total = data.bills.fold<num>(0, (a, b) => a + b.amount);
    final n = data.summary.memberCount;
    final prev = shiftMonth(data.month, -1);

    return SectionCard(
      title: s.sharedTitle(monthName(data.month, bn)),
      subtitle: s.sharedIntro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.bills.isEmpty) ...[
            Text(s.noBills(monthName(data.month, bn)), style: TextStyle(color: c.onSurfaceVariant, fontSize: 13)),
            if (canWrite)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run((app) => app.api.post('/months/${data.month}/bills/copy', {'fromMonth': prev}), s.saved),
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  label: Text(s.copyBills(monthName(prev, bn))),
                ),
              ),
          ] else ...[
            for (final b in data.bills)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(b.name, style: const TextStyle(fontSize: 14)),
                subtitle: n > 0 ? Text('${taka(b.amount / n)} × $n', style: TextStyle(color: c.onSurfaceVariant)) : null,
                onTap: canWrite ? () => _edit(b) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(taka(b.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (canWrite)
                      IconButton(
                        tooltip: s.delete,
                        icon: Icon(Icons.close, size: 18, color: c.onSurfaceVariant),
                        onPressed: _busy ? null : () => _delete(b),
                      ),
                  ],
                ),
              ),
            const Divider(),
            Row(children: [
              Expanded(child: Text(s.totalBills, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(taka(total), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(s.eachMember(n), style: TextStyle(color: c.onSurfaceVariant, fontSize: 13))),
              Text(n > 0 ? taka(total / n) : '—', style: TextStyle(color: c.onSurfaceVariant, fontSize: 13)),
            ]),
          ],
          if (canWrite) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in s.presets)
                  ActionChip(label: Text(p, style: const TextStyle(fontSize: 12.5)), onPressed: () => setState(() => _name.text = p)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: s.bill, hintText: s.billPlaceholder, errorText: _nameError),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: s.amount, prefixText: '৳ ', errorText: _amountError),
                    onSubmitted: (_) => _add(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: _busy ? null : _add, icon: const Icon(Icons.add), label: Text(s.addBill)),
          ],
        ],
      ),
    );
  }
}
