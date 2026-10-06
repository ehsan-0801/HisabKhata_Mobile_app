import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api.dart';
import '../../format.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'monthly_screen.dart';

/// Expense: who did how much bazar this month, each entry with its items.
class ExpenseTab extends StatelessWidget {
  const ExpenseTab({super.key, required this.bundle});
  final MonthBundle bundle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final data = bundle.data;
    final canWrite = context.watch<AppState>().canWrite;

    final groups = <int?, List<BazarEntry>>{};
    for (final e in data.bazar) {
      groups.putIfAbsent(e.memberId, () => []).add(e);
    }
    final deleted = groups[null] ?? const <BazarEntry>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthStats(bazar: data.totalBazar, meals: data.totalMeals, rate: data.mealRate),
        const SizedBox(height: 12),
        SectionCard(
          title: s.perPerson,
          subtitle: s.inTotal(taka(data.totalBazar), data.bazar.length),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: data.members.isEmpty && data.bazar.isEmpty
              ? EmptyState(title: s.expenseNoMembers, hint: s.expenseNoMembersHint, icon: Icons.group_outlined)
              : Column(
                  children: [
                    for (final m in data.members)
                      _MemberBazar(
                        name: m.display(bn),
                        entries: groups[m.id] ?? const [],
                        bundle: bundle,
                        onAdd: canWrite ? () => openBazarForm(context, bundle, memberId: m.id) : null,
                      ),
                    if (deleted.isNotEmpty) _MemberBazar(name: s.deletedMember, entries: deleted, bundle: bundle),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(s.total, style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text(taka(data.totalBazar), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MemberBazar extends StatefulWidget {
  const _MemberBazar({required this.name, required this.entries, required this.bundle, this.onAdd});
  final String name;
  final List<BazarEntry> entries;
  final MonthBundle bundle;
  final VoidCallback? onAdd;

  @override
  State<_MemberBazar> createState() => _MemberBazarState();
}

class _MemberBazarState extends State<_MemberBazar> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final total = widget.entries.fold<num>(0, (a, e) => a + e.amount);
    final canWrite = context.watch<AppState>().canWrite;

    return Column(
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: widget.entries.isEmpty ? null : () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: c.primary.withValues(alpha: 0.12),
                  child: Text(
                    widget.name.characters.first.toUpperCase(),
                    style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        widget.entries.isEmpty ? s.noBazarYet : s.bazars(widget.entries.length),
                        style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(taka(total), style: const TextStyle(fontWeight: FontWeight.w700)),
                if (widget.entries.isNotEmpty)
                  Icon(_open ? Icons.expand_less : Icons.expand_more, color: c.onSurfaceVariant),
                if (widget.onAdd != null)
                  IconButton(
                    tooltip: s.addFor(widget.name),
                    onPressed: widget.onAdd,
                    icon: Icon(Icons.add_circle_outline, color: c.primary),
                  ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 42, bottom: 8),
            child: Column(
              children: [
                for (final e in widget.entries)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: canWrite && e.memberId != null ? () => openBazarForm(context, widget.bundle, entry: e) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 56,
                            child: Text(formatDate(e.date, bn), style: TextStyle(fontSize: 12.5, color: c.onSurfaceVariant)),
                          ),
                          Expanded(
                            child: Text(
                              e.items.isEmpty ? s.noItems : e.items.map((i) => widget.bundle.itemName(i, bn)).join(', '),
                              style: TextStyle(fontSize: 13.5, color: e.items.isEmpty ? c.onSurfaceVariant : null),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(taka(e.amount), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Add (memberId) or edit (entry) a bazar.
Future<void> openBazarForm(BuildContext context, MonthBundle bundle, {int? memberId, BazarEntry? entry}) {
  return showFormSheet(context, (c) => _BazarForm(bundle: bundle, memberId: memberId ?? entry!.memberId!, entry: entry));
}

class _BazarForm extends StatefulWidget {
  const _BazarForm({required this.bundle, required this.memberId, this.entry});
  final MonthBundle bundle;
  final int memberId;
  final BazarEntry? entry;

  @override
  State<_BazarForm> createState() => _BazarFormState();
}

class _BazarFormState extends State<_BazarForm> {
  late int _memberId = widget.memberId;
  late String _date;
  late final List<String> _items = [...?widget.entry?.items];
  late final _amount = TextEditingController(text: widget.entry == null ? '' : formatNum(widget.entry!.amount).replaceAll(',', ''));
  late final _note = TextEditingController(text: widget.entry?.note ?? '');
  final _itemText = TextEditingController();
  final _itemFocus = FocusNode();
  Map<String, List<String>> _fieldErrors = {};
  bool _busy = false;

  MonthData get data => widget.bundle.data;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _date = widget.entry!.date;
    } else {
      // Today when it's in this month, otherwise the month's last day.
      final today = isoDate(dhakaToday());
      _date = today.startsWith(data.month) ? today : '${data.month}-${daysInMonth(data.month).toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _itemText.dispose();
    _itemFocus.dispose();
    super.dispose();
  }

  void _addItem(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    if (!_items.any((i) => i.toLowerCase() == t.toLowerCase())) setState(() => _items.add(t));
    _itemText.clear();
  }

  Future<void> _save() async {
    final s = context.read<AppState>().s;
    if (_itemText.text.trim().isNotEmpty) _addItem(_itemText.text);
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _fieldErrors = {'amount': [s.enterValidAmount]});
      return;
    }
    setState(() {
      _busy = true;
      _fieldErrors = {};
    });
    final app = context.read<AppState>();
    final body = {
      'memberId': _memberId,
      'date': _date,
      'items': _items,
      'amount': amount,
      'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
    };
    try {
      if (widget.entry == null) {
        await app.api.post('/bazar', body);
      } else {
        await app.api.patch('/bazar/${widget.entry!.id}', body);
      }
      if (!mounted) return;
      final member = data.members.firstWhere((m) => m.id == _memberId);
      Navigator.pop(context);
      toast(context, widget.entry == null ? s.added(member.display(app.bn)) : s.bazarUpdated);
      app.changed();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _fieldErrors = e.fields;
      });
      if (_fieldErrors.isEmpty) showError(context, e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showError(context, e);
    }
  }

  Future<void> _delete() async {
    final app = context.read<AppState>();
    final s = app.s;
    if (!await confirm(context, title: s.deleteBazarConfirm)) return;
    try {
      await app.api.delete('/bazar/${widget.entry!.id}');
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, s.bazarDeleted);
      app.changed();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final members = data.members.where((m) => m.isOn(_date) || m.id == _memberId).toList();
    final member = data.members.where((m) => m.id == _memberId).firstOrNull;
    final last = '${data.month}-${daysInMonth(data.month).toString().padLeft(2, '0')}';
    String? err(String f) => _fieldErrors[f]?.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.entry == null ? s.addFor(member?.display(bn) ?? '') : s.editFor(member?.display(bn) ?? ''),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _memberId,
          decoration: InputDecoration(labelText: s.member, errorText: err('memberId')),
          items: [for (final m in members) DropdownMenuItem(value: m.id, child: Text(m.display(bn)))],
          onChanged: (v) => setState(() => _memberId = v ?? _memberId),
        ),
        const SizedBox(height: 12),
        DateField(
          label: s.date,
          value: _date,
          error: err('date'),
          onPick: () async {
            final d = await pickDate(context, _date, first: '${data.month}-01', last: last);
            if (d != null) setState(() => _date = d);
          },
        ),
        const SizedBox(height: 12),
        _ItemPicker(
          controller: _itemText,
          focusNode: _itemFocus,
          catalog: widget.bundle.items,
          onAdd: _addItem,
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final i in _items)
                InputChip(
                  label: Text(widget.bundle.itemName(i, bn)),
                  onDeleted: () => setState(() => _items.remove(i)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: s.amount, prefixText: '৳ ', errorText: err('amount')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          decoration: InputDecoration(labelText: '${s.note} (${s.optional})', errorText: err('note')),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (widget.entry != null)
              TextButton.icon(
                onPressed: _busy ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: context.colors.error),
                icon: const Icon(Icons.delete_outline),
                label: Text(s.delete),
              ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
            const SizedBox(width: 8),
            FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? s.saving : s.save)),
          ],
        ),
      ],
    );
  }
}

/// Type an item; matching catalog items (English or Bangla) are suggested.
class _ItemPicker extends StatelessWidget {
  const _ItemPicker({required this.controller, required this.focusNode, required this.catalog, required this.onAdd});
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<Item> catalog;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<String>.empty();
        final hits = catalog
            .where((i) => i.name.toLowerCase().contains(q) || (i.nameBn ?? '').toLowerCase().contains(q))
            .map((i) => i.name)
            .take(8)
            .toList();
        final exact = catalog.any((i) => i.name.toLowerCase() == q || (i.nameBn ?? '').toLowerCase() == q);
        return [...hits, if (!exact) '\u0000${v.text.trim()}'];
      },
      displayStringForOption: (o) => '',
      onSelected: (o) => onAdd(o.startsWith('\u0000') ? o.substring(1) : o),
      fieldViewBuilder: (context, ctrl, focus, submit) => TextField(
        controller: ctrl,
        focusNode: focus,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => onAdd(v),
        decoration: InputDecoration(labelText: s.itemsLabel, hintText: s.itemPlaceholder, helperText: s.itemsHint),
      ),
      optionsViewBuilder: (context, select, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    dense: true,
                    leading: o.startsWith('\u0000') ? const Icon(Icons.add, size: 18) : null,
                    title: Text(o.startsWith('\u0000') ? s.addNew(o.substring(1)) : _label(o, bn)),
                    onTap: () => select(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _label(String name, bool bn) {
    final i = catalog.firstWhere((x) => x.name == name);
    return bn && i.nameBn != null && i.nameBn!.isNotEmpty ? '${i.nameBn} · ${i.name}' : i.name;
  }
}
