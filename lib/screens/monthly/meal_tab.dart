import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../format.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'monthly_screen.dart';

enum _Save { idle, saving, saved, failed }

/// Meal: a day picker with every member's meals for that day (saved as you go),
/// then the month's sheet split into three parts (1–10, 11–20, 21–end).
class MealTab extends StatefulWidget {
  const MealTab({super.key, required this.data});
  final MonthData data;

  @override
  State<MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<MealTab> {
  late int _day;
  late int _part;

  /// Unsaved or just-saved day values, "memberId|date" → meals (null clears).
  final _edits = <String, num?>{};
  final _queue = <String>{};
  final _sent = <String>{};
  Timer? _debounce;
  bool _inFlight = false;
  _Save _status = _Save.idle;
  late AppState _app;

  MonthData get data => widget.data;
  String _date(int day) => '${data.month}-${day.toString().padLeft(2, '0')}';
  String _key(int memberId, int day) => '$memberId|${_date(day)}';

  @override
  void initState() {
    super.initState();
    final today = dhakaToday();
    _day = monthKey(today) == data.month ? today.day : 1;
    _part = _partOf(_day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = context.read<AppState>();
  }

  @override
  void didUpdateWidget(MealTab old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      // Fresh data from the server already has what we saved.
      for (final k in _sent.toList()) {
        if (!_queue.contains(k)) _edits.remove(k);
      }
      _sent.clear();
      if (_day > data.days) _day = data.days;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_queue.isNotEmpty) _flush(); // don't lose the last taps
    super.dispose();
  }

  int _partOf(int day) => day <= 10 ? 0 : (day <= 20 ? 1 : 2);

  num _value(int memberId, int day) {
    final k = _key(memberId, day);
    return _edits.containsKey(k) ? (_edits[k] ?? 0) : data.cell(memberId, _date(day));
  }

  num _memberTotal(Member m) {
    final typed = data.typedTotal(m.id);
    if (typed != null) return typed;
    num sum = 0;
    for (var d = 1; d <= data.days; d++) {
      sum += _value(m.id, d);
    }
    return sum;
  }

  num get _totalMeals => data.members.fold<num>(0, (s, m) => s + _memberTotal(m)) + data.mealsOf(null);

  num _dayTotal(int day) => data.members.fold<num>(0, (s, m) => s + _value(m.id, day)) +
      data.cells.where((c) => c.memberId == null && c.date == _date(day)).fold<num>(0, (s, c) => s + c.meals);

  void _set(Member m, int day, num value) {
    final v = value.clamp(0, 20);
    final k = _key(m.id, day);
    setState(() {
      _edits[k] = v == 0 ? null : v;
      _queue.add(k);
      _status = _Save.saving;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _flush);
  }

  Future<void> _flush() async {
    if (_inFlight || _queue.isEmpty) return;
    _inFlight = true;
    final keys = _queue.toList();
    _queue.clear();
    final app = _app;
    final cells = [
      for (final k in keys)
        {'memberId': int.parse(k.split('|')[0]), 'date': k.split('|')[1], 'meals': _edits[k]},
    ];
    try {
      final r = await app.api.put('/months/${data.month}/meals', {'cells': cells});
      final failed = ((r['results'] as List?) ?? const []).where((x) => x['ok'] == false).toList();
      for (final x in failed) {
        final k = '${x['memberId']}|${x['date']}';
        _edits.remove(k);
      }
      _sent.addAll(keys);
      app.changed();
      if (!mounted) return;
      setState(() => _status = failed.isEmpty ? _Save.saved : _Save.failed);
      if (failed.isNotEmpty) toast(context, '${app.s.mealsNotSaved} ${failed.first['error'] ?? ''}', error: true);
    } catch (e) {
      // Put them back in the queue so the next tap (or retry) sends them again.
      _queue.addAll(keys);
      if (!mounted) return;
      setState(() => _status = _Save.failed);
      showError(context, e);
    } finally {
      _inFlight = false;
      if (_queue.isNotEmpty && mounted && _status != _Save.failed) _flush();
    }
  }

  Future<void> _editTotal(Member m) async {
    final app = context.read<AppState>();
    final s = app.s;
    final typed = data.typedTotal(m.id);
    final ctrl = TextEditingController(text: typed == null ? '' : formatNum(typed));
    String? error;
    final result = await showDialog<Object?>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(s.totalFor(m.display(app.bn))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.typedTotalHelp, style: TextStyle(fontSize: 13, color: Theme.of(c).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: s.monthTotal, errorText: error),
              ),
            ],
          ),
          actions: [
            if (typed != null) TextButton(onPressed: () => Navigator.pop(c, 'clear'), child: Text(s.clearTotal)),
            TextButton(onPressed: () => Navigator.pop(c), child: Text(s.cancel)),
            FilledButton(
              onPressed: () {
                final v = num.tryParse(ctrl.text.trim());
                if (ctrl.text.trim().isEmpty) return Navigator.pop(c, 'clear');
                if (v == null || v < 0 || v > 999) return set(() => error = s.badTotal);
                Navigator.pop(c, v);
              },
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final meals = result == 'clear' ? null : result as num;
    try {
      final r = await app.api.put('/months/${data.month}/meals', {
        'totals': [
          {'memberId': m.id, 'meals': meals},
        ],
      });
      final bad = ((r['results'] as List?) ?? const []).where((x) => x['ok'] == false).firstOrNull;
      if (!mounted) return;
      if (bad != null) {
        toast(context, '${bad['error']}', error: true);
      } else {
        toast(context, s.mealsSaved);
        app.changed();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (data.members.isEmpty) {
      return Column(children: [
        MonthStats(bazar: data.totalBazar, meals: data.totalMeals, rate: data.mealRate),
        const SizedBox(height: 12),
        Card(child: EmptyState(title: s.mealNoMembers, icon: Icons.restaurant_outlined)),
      ]);
    }
    final total = _totalMeals;
    final deleted = data.mealsOf(null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthStats(
          bazar: data.totalBazar,
          meals: total,
          rate: total > 0 ? data.totalBazar / total : null,
          mealsSub: deleted > 0 ? s.deletedMeals(formatNum(deleted)) : null,
        ),
        const SizedBox(height: 12),
        _dayCard(context),
        const SizedBox(height: 12),
        _sheetCard(context),
      ],
    );
  }

  // ---------------------------------------------------------------- day entry

  Widget _dayCard(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final c = context.colors;
    final canWrite = context.watch<AppState>().canWrite;
    final date = _date(_day);

    return SectionCard(
      title: s.dayEntry,
      trailing: _statusChip(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: s.prevDay,
                onPressed: _day > 1 ? () => setState(() => _part = _partOf(--_day)) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(child: _DayStrip(month: data.month, days: data.days, selected: _day, onSelect: (d) => setState(() {
                _day = d;
                _part = _partOf(d);
              }))),
              IconButton(
                tooltip: s.nextDay,
                onPressed: _day < data.days ? () => setState(() => _part = _partOf(++_day)) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${weekday(date, bn)}, ${formatDate(date, bn)} ${parseIso(date).year}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (final m in data.members) _memberRow(context, m, date, canWrite),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(child: Text(s.dayTotal, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(formatNum(_dayTotal(_day)), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(width: 52),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memberRow(BuildContext context, Member m, String date, bool canWrite) {
    final s = context.s;
    final c = context.colors;
    final active = m.isOn(date);
    final typed = data.typedTotal(m.id) != null;
    final enabled = canWrite && active && !typed;
    final v = _value(m.id, _day);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.display(context.bn), style: const TextStyle(fontWeight: FontWeight.w500)),
                if (!active || typed)
                  Text(
                    !active ? s.notMemberShort : s.totalTypedShort,
                    style: TextStyle(fontSize: 11.5, color: c.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          _RoundButton(icon: Icons.remove, onTap: enabled && v > 0 ? () => _set(m, _day, (v - 1).clamp(0, 20)) : null),
          SizedBox(
            width: 56,
            child: InkWell(
              onTap: enabled ? () => _typeDay(m) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: c.outline),
                  borderRadius: BorderRadius.circular(8),
                  color: enabled ? null : c.surfaceContainerHighest,
                ),
                child: Text(
                  active ? formatNum(v) : '—',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: enabled ? null : c.onSurfaceVariant),
                ),
              ),
            ),
          ),
          _RoundButton(icon: Icons.add, onTap: enabled && v < 20 ? () => _set(m, _day, v + 1) : null),
        ],
      ),
    );
  }

  Future<void> _typeDay(Member m) async {
    final app = context.read<AppState>();
    final s = app.s;
    final ctrl = TextEditingController(text: formatNum(_value(m.id, _day)));
    String? error;
    final v = await showDialog<num>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text('${m.display(app.bn)} · ${formatDate(_date(_day), app.bn)}'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s.meals, errorText: error),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(s.cancel)),
            FilledButton(
              onPressed: () {
                final t = ctrl.text.trim();
                final n = t.isEmpty ? 0 : num.tryParse(t);
                if (n == null || n < 0 || n > 20 || ((n * 100).round() - n * 100).abs() > 1e-6) return set(() => error = s.badDay);
                Navigator.pop(c, n);
              },
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
    if (v != null) _set(m, _day, v);
  }

  Widget _statusChip(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    return switch (_status) {
      _Save.idle => const SizedBox.shrink(),
      _Save.saving => Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 6),
          Text(s.saving, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
        ]),
      _Save.saved => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 14, color: c.primary),
          const SizedBox(width: 4),
          Text(s.mealsSaved, style: TextStyle(fontSize: 12, color: c.primary)),
        ]),
      _Save.failed => TextButton.icon(
          onPressed: () {
            setState(() => _status = _Save.saving);
            _flush();
          },
          icon: Icon(Icons.refresh, size: 16, color: c.error),
          label: Text(s.retry, style: TextStyle(fontSize: 12, color: c.error)),
        ),
    };
  }

  // ---------------------------------------------------------------- sheet

  Widget _sheetCard(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final canWrite = context.watch<AppState>().canWrite;
    final ranges = [(1, 10), (11, 20), (21, data.days)];
    final (from, to) = ranges[_part];

    return SectionCard(
      title: s.mealSheet,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [for (var i = 0; i < 3; i++) ButtonSegment(value: i, label: Text(s.daysRange(ranges[i].$1, ranges[i].$2), style: const TextStyle(fontSize: 12.5)))],
            selected: {_part},
            onSelectionChanged: (v) => setState(() => _part = v.first),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, box) {
            const totalW = 46.0;
            final nameW = (box.maxWidth * 0.24).clamp(64.0, 120.0);
            final n = to - from + 1;
            final cellW = ((box.maxWidth - nameW - totalW) / n).clamp(26.0, 48.0);
            final width = nameW + totalW + cellW * n;
            final table = SizedBox(
              width: width,
              child: Column(
                children: [
                  _sheetRow(
                    nameW: nameW,
                    cellW: cellW,
                    totalW: totalW,
                    name: Text(s.member, style: _head(c)),
                    cells: [
                      for (var d = from; d <= to; d++)
                        InkWell(
                          onTap: () => setState(() => _day = d),
                          child: Container(
                            alignment: Alignment.center,
                            height: 30,
                            decoration: d == _day ? BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(6)) : null,
                            child: Text('$d', style: _head(c).copyWith(color: d == _day ? c.onPrimary : null)),
                          ),
                        ),
                    ],
                    total: Text(s.total, style: _head(c)),
                  ),
                  for (final m in data.members) _memberSheetRow(context, m, from, to, nameW, cellW, totalW, canWrite),
                  Divider(height: 1, color: c.outline),
                  _sheetRow(
                    nameW: nameW,
                    cellW: cellW,
                    totalW: totalW,
                    name: Text(s.total, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    cells: [
                      for (var d = from; d <= to; d++)
                        Center(child: Text(_blank(_dayTotal(d)), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    ],
                    total: Text(formatNum(_totalMeals), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
            return width > box.maxWidth ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: table) : table;
          }),
          if (canWrite) ...[
            const SizedBox(height: 10),
            Text('✎ ${s.typedTotalHelp}', style: TextStyle(fontSize: 11.5, color: c.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _memberSheetRow(BuildContext context, Member m, int from, int to, double nameW, double cellW, double totalW, bool canWrite) {
    final c = context.colors;
    final typed = data.typedTotal(m.id);
    return _sheetRow(
      nameW: nameW,
      cellW: cellW,
      totalW: totalW,
      name: Text(m.display(context.bn), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
      cells: [
        for (var d = from; d <= to; d++)
          InkWell(
            onTap: () => setState(() => _day = d),
            child: Container(
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: !m.isOn(_date(d))
                    ? c.surfaceContainerHighest
                    : d == _day
                        ? c.primary.withValues(alpha: 0.10)
                        : null,
                border: Border(left: BorderSide(color: c.outline.withValues(alpha: 0.6), width: 0.5)),
              ),
              child: Text(
                _blank(_value(m.id, d)),
                style: TextStyle(fontSize: 12, color: typed != null ? c.onSurfaceVariant : null, decoration: typed != null ? TextDecoration.lineThrough : null),
              ),
            ),
          ),
      ],
      total: InkWell(
        onTap: canWrite ? () => _editTotal(m) : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 28,
          alignment: Alignment.center,
          decoration: typed != null ? BoxDecoration(color: Brand.amber.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(6)) : null,
          child: Text(
            '${formatNum(_memberTotal(m))}${typed != null ? '✎' : ''}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _sheetRow({required double nameW, required double cellW, required double totalW, required Widget name, required List<Widget> cells, required Widget total}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(width: nameW, child: Padding(padding: const EdgeInsets.only(right: 4), child: name)),
          for (final cell in cells) SizedBox(width: cellW, child: cell),
          SizedBox(width: totalW, child: Center(child: total)),
        ],
      ),
    );
  }

  TextStyle _head(ColorScheme c) => TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.onSurfaceVariant);
  String _blank(num v) => v == 0 ? '' : formatNum(v);
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton.outlined(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(minimumSize: const Size(40, 40), shape: const CircleBorder()),
      );
}

/// Horizontal strip of days (number + weekday); keeps the selected day in view.
class _DayStrip extends StatefulWidget {
  const _DayStrip({required this.month, required this.days, required this.selected, required this.onSelect});
  final String month;
  final int days;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  static const _w = 44.0;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(jump: true));
  }

  @override
  void didUpdateWidget(_DayStrip old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final target = ((widget.selected - 1) * _w - (_scroll.position.viewportDimension - _w) / 2)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    jump ? _scroll.jumpTo(target) : _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bn = context.bn;
    final today = isoDate(dhakaToday());
    return SizedBox(
      height: 54,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemCount: widget.days,
        itemExtent: _w,
        itemBuilder: (context, i) {
          final d = i + 1;
          final iso = '${widget.month}-${d.toString().padLeft(2, '0')}';
          final sel = d == widget.selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => widget.onSelect(d),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: sel ? c.primary : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iso == today && !sel ? Brand.amber : (sel ? c.primary : c.outline)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$d', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: sel ? c.onPrimary : null)),
                    Text(weekday(iso, bn), maxLines: 1, style: TextStyle(fontSize: 9.5, color: sel ? c.onPrimary : c.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
