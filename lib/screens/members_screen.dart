import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../format.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class _MembersData {
  _MembersData(this.members, this.billTypes);
  final List<Member> members;
  final List<BillType> billTypes;
}

/// Members: everyone in the mess, plus each person's monthly bills.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  Future<_MembersData> _load(AppState app) async {
    final r = await Future.wait([app.api.get('/members'), app.api.get('/bill-types')]);
    return _MembersData(
      ((r[0] as Map)['members'] as List).map((e) => Member.fromJson(e as Map)).toList(),
      ((r[1] as Map)['billTypes'] as List).map((e) => BillType.fromJson(e as Map)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Loader<_MembersData>(
      cacheKey: 'members',
      load: () => _load(app),
      builder: (context, d, reload) {
        final s = context.s;
        final canWrite = context.watch<AppState>().canWrite;
        final today = isoDate(dhakaToday());
        final current = d.members.where((m) => m.leftOn == null || m.leftOn!.compareTo(today) >= 0).toList();
        final gone = d.members.where((m) => !current.contains(m)).toList();

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              PageHeader(s.members, intro: s.membersIntro),
              if (!canWrite) const ReadOnlyBanner(),
              if (canWrite) ...[
                FilledButton.icon(
                  onPressed: () => showFormSheet(context, (_) => _MemberForm()),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(s.addMember),
                ),
                const SizedBox(height: 16),
              ],
              SectionCard(
                title: s.current,
                subtitle: s.sharing(current.length),
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: current.isEmpty
                    ? EmptyState(title: s.noMembers, hint: s.noMembersHint, icon: Icons.group_outlined)
                    : Column(children: [for (final m in current) _MemberTile(member: m, billTypes: d.billTypes, canWrite: canWrite)]),
              ),
              if (canWrite && current.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: s.everyoneTitle,
                  subtitle: s.everyoneIntro,
                  child: OutlinedButton.icon(
                    onPressed: d.billTypes.isEmpty
                        ? () => toast(context, s.addBillTypesFirst)
                        : () => showFormSheet(context, (_) => _EveryoneBillsForm(billTypes: d.billTypes, count: current.length)),
                    icon: const Icon(Icons.groups_outlined),
                    label: Text(s.everyoneTitle),
                  ),
                ),
              ],
              if (gone.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: s.movedOut,
                  subtitle: s.movedOutIntro,
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Column(children: [for (final m in gone) _MemberTile(member: m, billTypes: d.billTypes, canWrite: canWrite)]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.billTypes, required this.canWrite});
  final Member member;
  final List<BillType> billTypes;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final m = member;
    final other = bn ? (m.nameBn != null && m.nameBn!.isNotEmpty && m.nameBn != m.name ? m.name : null) : m.nameBn;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 0, right: 0),
      leading: CircleAvatar(
        backgroundColor: c.primary.withValues(alpha: 0.12),
        child: Text(m.display(bn).characters.first.toUpperCase(), style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
      ),
      title: Text(m.display(bn) + (other != null && other.isNotEmpty ? '  ·  $other' : ''), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        s.joined('${formatDate(m.joinedOn, bn)} ${parseIso(m.joinedOn).year}') +
            (m.leftOn != null ? s.left('${formatDate(m.leftOn!, bn)} ${parseIso(m.leftOn!).year}') : ''),
        style: TextStyle(fontSize: 12.5, color: c.onSurfaceVariant),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: s.edit,
        onSelected: (v) {
          switch (v) {
            case 'edit':
              showFormSheet(context, (_) => _MemberForm(member: m));
            case 'bills':
              if (billTypes.isEmpty) {
                toast(context, s.addBillTypesFirst);
              } else {
                showFormSheet(context, (_) => _MemberBillsForm(member: m, billTypes: billTypes, readOnly: !canWrite));
              }
            case 'delete':
              _delete(context);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'bills', child: ListTile(leading: const Icon(Icons.receipt_long_outlined), title: Text(s.setBills))),
          if (canWrite) PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(s.editMember))),
          if (canWrite)
            PopupMenuItem(
              value: 'delete',
              child: ListTile(leading: Icon(Icons.delete_outline, color: c.error), title: Text(s.removeMember, style: TextStyle(color: c.error))),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final app = context.read<AppState>();
    final s = app.s;
    final name = member.display(app.bn);
    final ok = await confirm(
      context,
      title: s.removeTitle(name),
      body: member.records > 0 ? s.removeWithRecords(member.records) : s.removeIntro,
      action: s.removeMember,
    );
    if (!ok) return;
    try {
      await app.api.delete('/members/${member.id}${member.records > 0 ? '?force=true' : ''}');
      if (!context.mounted) return;
      toast(context, s.memberDeleted);
      app.changed();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _MemberForm extends StatefulWidget {
  const _MemberForm({this.member});
  final Member? member;

  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  late final _name = TextEditingController(text: widget.member?.name ?? '');
  late final _nameBn = TextEditingController(text: widget.member?.nameBn ?? '');
  late String _joined = widget.member?.joinedOn ?? isoDate(dhakaToday());
  late String? _left = widget.member?.leftOn;
  Map<String, List<String>> _errors = {};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _nameBn.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final s = app.s;
    setState(() {
      _busy = true;
      _errors = {};
    });
    final body = {
      'name': _name.text.trim(),
      'nameBn': _nameBn.text.trim().isEmpty ? null : _nameBn.text.trim(),
      'joinedOn': _joined,
      if (widget.member != null) 'leftOn': _left,
    };
    try {
      if (widget.member == null) {
        await app.api.post('/members', body);
      } else {
        await app.api.patch('/members/${widget.member!.id}', body);
      }
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, widget.member == null ? s.memberAdded : s.memberSaved);
      app.changed();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = e.fields;
      });
      if (e.fields.isEmpty) showError(context, e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    String? err(String f) => _errors[f]?.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.member == null ? s.addMember : s.editMember, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          autofocus: widget.member == null,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: s.name, errorText: err('name')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameBn,
          decoration: InputDecoration(labelText: '${s.nameBn} (${s.optional})', helperText: s.nameBnHint, errorText: err('nameBn')),
        ),
        const SizedBox(height: 12),
        DateField(
          label: s.joinedOn,
          value: _joined,
          helper: s.joinedHint,
          error: err('joinedOn'),
          onPick: () async {
            final d = await pickDate(context, _joined);
            if (d != null) setState(() => _joined = d);
          },
        ),
        if (widget.member != null) ...[
          const SizedBox(height: 12),
          DateField(
            label: s.leftOn,
            value: _left,
            helper: s.leftHint,
            error: err('leftOn'),
            onClear: () => setState(() => _left = null),
            onPick: () async {
              final d = await pickDate(context, _left ?? isoDate(dhakaToday()), first: _joined);
              if (d != null) setState(() => _left = d);
            },
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? s.saving : (widget.member == null ? s.addMember : s.save)),
            ),
          ],
        ),
      ],
    );
  }
}

/// One member's monthly bills, from a chosen month onward.
class _MemberBillsForm extends StatefulWidget {
  const _MemberBillsForm({required this.member, required this.billTypes, required this.readOnly});
  final Member member;
  final List<BillType> billTypes;
  final bool readOnly;

  @override
  State<_MemberBillsForm> createState() => _MemberBillsFormState();
}

class _MemberBillsFormState extends State<_MemberBillsForm> {
  late String _from;
  final _ctrls = <int, TextEditingController>{};
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final joined = widget.member.joinedOn.substring(0, 7);
    final now = thisMonth();
    _from = joined.compareTo(now) > 0 ? joined : now;
    for (final b in widget.billTypes) {
      _ctrls[b.id] = TextEditingController();
    }
    _fetch();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await context.read<AppState>().api.get('/members/${widget.member.id}/charges?month=$_from');
      final charges = ((r['charges'] as List?) ?? const []).map((e) => Charge.fromJson(e as Map));
      for (final c in _ctrls.values) {
        c.text = '';
      }
      for (final ch in charges) {
        _ctrls[ch.billTypeId]?.text = formatNum(ch.amount).replaceAll(',', '');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  num get _total => _ctrls.values.fold<num>(0, (a, c) => a + (parseAmount(c.text) ?? 0));

  Future<void> _save() async {
    final app = context.read<AppState>();
    final s = app.s;
    for (final c in _ctrls.values) {
      final v = parseAmount(c.text);
      if (c.text.trim().isNotEmpty && (v == null || v < 0)) return toast(context, s.enterValidAmount, error: true);
    }
    setState(() => _busy = true);
    try {
      await app.api.put('/members/${widget.member.id}/charges', {
        'fromMonth': _from,
        'charges': [
          for (final e in _ctrls.entries) {'billTypeId': e.key, 'amount': parseAmount(e.value.text)},
        ],
      });
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, s.billsSavedFor(widget.member.display(app.bn)));
      app.changed();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.billsFormFor(widget.member.display(bn)), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(s.appliesFrom, style: TextStyle(fontSize: 12.5, color: c.onSurfaceVariant)),
        MonthSwitcher(
          month: _from,
          onChanged: (m) {
            setState(() => _from = m);
            _fetch();
          },
        ),
        Text(s.earlierKeep(monthName(_from, bn)), style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else ...[
          for (final b in widget.billTypes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _ctrls[b.id],
                readOnly: widget.readOnly,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: b.name, prefixText: '৳ '),
              ),
            ),
          Text(s.leaveEmpty, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(s.perMonth(taka(_total)), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
            if (!widget.readOnly) ...[
              const SizedBox(width: 8),
              FilledButton(onPressed: _busy || _loading ? null : _save, child: Text(_busy ? s.saving : s.saveBills)),
            ],
          ],
        ),
      ],
    );
  }
}

/// The same amounts for every current member, from a chosen month.
class _EveryoneBillsForm extends StatefulWidget {
  const _EveryoneBillsForm({required this.billTypes, required this.count});
  final List<BillType> billTypes;
  final int count;

  @override
  State<_EveryoneBillsForm> createState() => _EveryoneBillsFormState();
}

class _EveryoneBillsFormState extends State<_EveryoneBillsForm> {
  String _from = thisMonth();
  late final _ctrls = {for (final b in widget.billTypes) b.id: TextEditingController()};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final s = app.s;
    final charges = [
      for (final e in _ctrls.entries)
        if (e.value.text.trim().isNotEmpty) {'billTypeId': e.key, 'amount': parseAmount(e.value.text)},
    ];
    if (charges.isEmpty || charges.any((c) => c['amount'] == null)) return toast(context, s.enterValidAmount, error: true);
    setState(() => _busy = true);
    try {
      await app.api.put('/months/$_from/charges', {'charges': charges});
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, s.billsSaved);
      app.changed();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.everyoneTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(s.everyoneIntro, style: TextStyle(fontSize: 12.5, color: c.onSurfaceVariant)),
        const SizedBox(height: 12),
        Text(s.appliesFrom, style: TextStyle(fontSize: 12.5, color: c.onSurfaceVariant)),
        MonthSwitcher(month: _from, onChanged: (m) => setState(() => _from = m)),
        Text(s.earlierKeep(monthName(_from, bn)), style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
        const SizedBox(height: 12),
        for (final b in widget.billTypes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _ctrls[b.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: b.name, prefixText: '৳ '),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
            const SizedBox(width: 8),
            FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? s.saving : s.applyEveryone)),
          ],
        ),
      ],
    );
  }
}
