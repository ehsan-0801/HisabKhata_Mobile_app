import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Food items: the catalog behind the Expense tab's item picker.
class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _nameBn = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _nameBn.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final app = context.read<AppState>();
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    final ok = await runAndRefresh(
      context,
      () => app.api.post('/items', {'name': name, if (_nameBn.text.trim().isNotEmpty) 'nameBn': _nameBn.text.trim()}),
      app.s.saved,
    );
    if (ok) {
      _name.clear();
      _nameBn.clear();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Loader<List<Item>>(
      cacheKey: 'items',
      load: () async => ((await app.api.get('/items'))['items'] as List).map((e) => Item.fromJson(e as Map)).toList(),
      builder: (context, items, reload) {
        final s = context.s;
        final bn = context.bn;
        final c = context.colors;
        final canWrite = context.watch<AppState>().canWrite;
        final q = _search.text.trim().toLowerCase();
        final shown = q.isEmpty
            ? items
            : items.where((i) => i.name.toLowerCase().contains(q) || (i.nameBn ?? '').toLowerCase().contains(q)).toList();

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              PageHeader(s.items, intro: s.itemsIntro),
              if (!canWrite) const ReadOnlyBanner(),
              if (canWrite) ...[
                SectionCard(
                  title: s.newItem,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _name, decoration: InputDecoration(labelText: s.name, hintText: s.itemPlaceholderEn))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _nameBn,
                              onSubmitted: (_) => _add(),
                              decoration: InputDecoration(labelText: s.nameBn, hintText: s.itemPlaceholderBn),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(onPressed: _busy ? null : _add, icon: const Icon(Icons.add), label: Text(s.add)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '${s.search(s.itemNouns)} (${items.length})',
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _search.clear())),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: shown.isEmpty
                    ? EmptyState(title: q.isEmpty ? s.none(s.itemNouns) : s.noMatch(s.itemNouns, _search.text.trim()), icon: Icons.shopping_basket_outlined)
                    : Column(
                        children: [
                          for (var i = 0; i < shown.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _itemTile(context, shown[i], bn, c, canWrite),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _itemTile(BuildContext context, Item it, bool bn, ColorScheme c, bool canWrite) {
    final s = context.s;
    final app = context.read<AppState>();
    final other = bn ? it.name : it.nameBn;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(it.display(bn), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
      subtitle: Text(
        [if (other != null && other.isNotEmpty && other != it.display(bn)) other, it.usage > 0 ? s.usedTimes(it.usage) : s.notUsed].join(' · '),
        style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
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
                    final r = await renameDialog(context, title: s.rename, name: it.name, nameBn: it.nameBn, withBn: true);
                    if (r == null || !context.mounted) return;
                    await runAndRefresh(context, () => app.api.patch('/items/${it.id}', {'name': r.$1, 'nameBn': r.$2}), s.saved);
                  },
                ),
                IconButton(
                  tooltip: it.usage > 0 ? s.itemLocked : s.delete,
                  icon: Icon(Icons.delete_outline, size: 20, color: it.usage > 0 ? c.outline : c.error),
                  onPressed: it.usage > 0
                      ? () => toast(context, s.itemLocked)
                      : () async {
                          if (!await confirm(context, title: s.deleteConfirm(it.display(bn))) || !context.mounted) return;
                          await runAndRefresh(context, () => app.api.delete('/items/${it.id}'), s.deleted);
                        },
                ),
              ],
            ),
    );
  }
}
