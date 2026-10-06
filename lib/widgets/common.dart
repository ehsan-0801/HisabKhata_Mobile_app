import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../format.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';

extension AppContext on BuildContext {
  AppState get app => read<AppState>();
  S get s => watch<AppState>().s;
  bool get bn => watch<AppState>().bn;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

/// The message to show for an error, in the app's language where we know better than the server.
String errorMessage(BuildContext context, Object e) {
  final s = context.read<AppState>().s;
  if (e is ApiException) {
    if (e.isOffline) return s.offline;
    if (e.status == 429 && e.retryAfter != null) return s.tooMany(e.retryAfter!);
    if (e.fields.isNotEmpty) return e.fields.values.first.first;
    return e.message;
  }
  return s.somethingWrong;
}

void toast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

void showError(BuildContext context, Object e) => toast(context, errorMessage(context, e), error: true);

Future<bool> confirm(BuildContext context, {required String title, String? body, String? action, bool danger = true}) async {
  final s = context.read<AppState>().s;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.keep)),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(action ?? s.yesDelete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Logo, then the mess name to its right (nothing when the mess has no name).
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = context.watch<AppState>().mess?.name;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(dark ? 'assets/brand/logo-dark.png' : 'assets/brand/logo.png', height: 30, semanticLabel: 'HisabKhata'),
        if (name != null) ...[
          Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 10), color: context.colors.outline),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

/// The "EN" / "বাংলা" button from the web header.
class LangButton extends StatelessWidget {
  const LangButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Tooltip(
      message: s.switchLangLabel,
      child: TextButton(
        onPressed: () => context.app.toggleLang(),
        style: TextButton.styleFrom(minimumSize: const Size(44, 40), foregroundColor: context.colors.onSurface),
        child: Text(s.switchLang, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;
    final (icon, label) = switch (state.themeMode) {
      ThemeMode.light => (Icons.light_mode_outlined, s.light),
      ThemeMode.dark => (Icons.dark_mode_outlined, s.dark),
      ThemeMode.system => (Icons.brightness_auto_outlined, s.system),
    };
    return IconButton(tooltip: '${s.theme}: $label', icon: Icon(icon), onPressed: state.cycleTheme);
  }
}

/// A card with a title, an optional line under it and a body — like the web's Card.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.subtitle, this.trailing, required this.child, this.padding});
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!, style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            if (title != null) const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Page heading with an intro line.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.intro});
  final String title;
  final String? intro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
          if (intro != null) ...[
            const SizedBox(height: 4),
            Text(intro!, style: TextStyle(fontSize: 13.5, color: context.colors.onSurfaceVariant, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

/// One headline number (total bazar, total meals, meal rate).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.sub, this.accent = false});
  final String label;
  final String value;
  final String? sub;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent ? c.primary.withValues(alpha: 0.08) : c.surface,
        border: Border.all(color: accent ? c.primary.withValues(alpha: 0.35) : c.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: accent ? c.primary : c.onSurface)),
          ),
          if (sub != null) Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow(this.tiles, {super.key});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: tiles[i]),
          ],
        ],
      );
}

/// ‹ October 2026 › with a "This month" shortcut.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key, required this.month, required this.onChanged});
  final String month;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bn = context.bn;
    final isThis = month == thisMonth();
    return Row(
      children: [
        IconButton.outlined(
          tooltip: s.previousMonth,
          onPressed: () => onChanged(shiftMonth(month, -1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _pick(context),
            child: Text(
              monthName(month, bn),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (!isThis)
          TextButton(onPressed: () => onChanged(thisMonth()), child: Text(s.thisMonth)),
        IconButton.outlined(
          tooltip: s.nextMonth,
          onPressed: () => onChanged(shiftMonth(month, 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: parseIso(month),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (d != null) onChanged(monthKey(d));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.hint, this.icon = Icons.inbox_outlined});
  final String title;
  final String? hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, size: 36, color: context.colors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant)),
            ],
          ],
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: context.colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(s.loadTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(errorMessage(context, error), textAlign: TextAlign.center, style: TextStyle(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(s.retry)),
          ],
        ),
      ),
    );
  }
}

/// Loads data with [load], shows a spinner / error, then [builder]. Pull to refresh.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<Loader<T>> createState() => LoaderState<T>();
}

class LoaderState<T> extends State<Loader<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;
  late int _revision;

  @override
  void initState() {
    super.initState();
    _revision = context.read<AppState>().revision;
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _data == null ? e : null;
        _loading = false;
      });
      if (_data != null) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Something changed somewhere in the app: reload, keeping the current data on screen.
    final rev = context.select<AppState, int>((a) => a.revision);
    if (rev != _revision) {
      _revision = rev;
      Future.microtask(reload);
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(error: _error!, onRetry: reload);
    return widget.builder(context, _data as T, reload);
  }
}

/// A "view only" note for viewers.
class ReadOnlyBanner extends StatelessWidget {
  const ReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(context.s.readOnly, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// Picks a date with the platform picker; returns YYYY-MM-DD.
Future<String?> pickDate(BuildContext context, String initial, {String? first, String? last}) async {
  final d = await showDatePicker(
    context: context,
    initialDate: parseIso(initial),
    firstDate: first != null ? parseIso(first) : DateTime(2020),
    lastDate: last != null ? parseIso(last) : DateTime(2100),
  );
  return d == null ? null : isoDate(d);
}

/// A tappable field showing a date.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onPick, this.onClear, this.helper, this.error});
  final String label;
  final String? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final bn = context.bn;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          errorText: error,
          suffixIcon: value != null && onClear != null
              ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value == null ? '—' : '${formatDate(value!, bn)} ${parseIso(value!).year}'),
      ),
    );
  }
}

/// Small rounded label (e.g. "Pays", "Gets back").
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
      );
}

/// Bottom sheet that resizes with the keyboard.
Future<T?> showFormSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: builder(c),
      ),
    ),
  );
}

/// Runs a change, shows [done] (or the error), and tells every screen to reload.
Future<bool> runAndRefresh(BuildContext context, Future<dynamic> Function() fn, String done) async {
  final app = context.read<AppState>();
  try {
    await fn();
    if (context.mounted) toast(context, done);
    app.changed();
    return true;
  } catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}

/// Asks for a name (and optionally a Bangla name). Returns (name, nameBn).
Future<(String, String?)?> renameDialog(BuildContext context, {required String title, required String name, String? nameBn, bool withBn = false}) {
  final s = context.read<AppState>().s;
  final a = TextEditingController(text: name);
  final b = TextEditingController(text: nameBn ?? '');
  return showDialog<(String, String?)>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: a, autofocus: true, decoration: InputDecoration(labelText: s.name)),
          if (withBn) ...[
            const SizedBox(height: 12),
            TextField(controller: b, decoration: InputDecoration(labelText: '${s.nameBn} (${s.optional})')),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(s.cancel)),
        FilledButton(
          onPressed: () {
            if (a.text.trim().isEmpty) return;
            Navigator.pop(c, (a.text.trim(), b.text.trim().isEmpty ? null : b.text.trim()));
          },
          child: Text(s.save),
        ),
      ],
    ),
  );
}
