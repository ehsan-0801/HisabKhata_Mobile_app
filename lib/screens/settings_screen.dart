import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Settings: the mess name, the account (profile, password, sign out) and the app's look.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;
    final user = state.user;
    final mess = state.mess;
    if (user == null || mess == null) return const SizedBox.shrink(); // signing out
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        PageHeader(s.settings, intro: s.settingsIntro),
        SectionCard(
          title: s.messName,
          subtitle: s.messNameIntro,
          trailing: Pill(s.role(mess.role), color: context.colors.primary),
          child: _MessNameForm(mess: mess),
        ),
        const SizedBox(height: 12),
        SectionCard(title: s.appearance, child: const _Appearance()),
        const SizedBox(height: 12),
        SectionCard(title: s.profile, subtitle: s.profileIntro, child: _ProfileForm(user: user)),
        const SizedBox(height: 12),
        SectionCard(title: s.password, subtitle: s.passwordIntro, child: const _PasswordForm()),
        const SizedBox(height: 12),
        SectionCard(
          title: s.signOut,
          subtitle: s.signedInAs(user.username, user.email),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(onPressed: state.logout, icon: const Icon(Icons.logout), label: Text(s.signOutDevice)),
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: context.colors.error),
                onPressed: () async {
                  if (!await confirm(context, title: s.signOutEverywhere, body: s.signOutEverywhereConfirm, action: s.signOutEverywhere)) return;
                  try {
                    await state.logoutEverywhere();
                  } catch (_) {/* signed out locally anyway */}
                },
                icon: const Icon(Icons.devices_other_outlined),
                label: Text(s.signOutEverywhere),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Appearance extends StatelessWidget {
  const _Appearance();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.language, style: TextStyle(fontSize: 12.5, color: context.colors.onSurfaceVariant)),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: const [ButtonSegment(value: true, label: Text('বাংলা')), ButtonSegment(value: false, label: Text('English'))],
          selected: {state.bn},
          onSelectionChanged: (v) {
            if (v.first != state.bn) state.toggleLang();
          },
        ),
        const SizedBox(height: 14),
        Text(s.theme, style: TextStyle(fontSize: 12.5, color: context.colors.onSurfaceVariant)),
        const SizedBox(height: 6),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(s.light)),
            ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(s.dark)),
            ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(s.system)),
          ],
          selected: {state.themeMode},
          onSelectionChanged: (v) => state.setTheme(v.first),
        ),
      ],
    );
  }
}

class _MessNameForm extends StatefulWidget {
  const _MessNameForm({required this.mess});
  final Mess mess;

  @override
  State<_MessNameForm> createState() => _MessNameFormState();
}

class _MessNameFormState extends State<_MessNameForm> {
  late final _ctrl = TextEditingController(text: widget.mess.name ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await app.api.patch('/mess', {'name': _ctrl.text.trim()});
      app.setMess(Mess.fromJson(r['mess'] as Map));
      if (mounted) toast(context, app.s.saved);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.field('name') ?? errorMessage(context, e));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final canWrite = context.watch<AppState>().canWrite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          readOnly: !canWrite,
          decoration: InputDecoration(labelText: s.name, helperText: s.messNameHint, errorText: _error),
        ),
        if (canWrite) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? s.saving : s.save)),
          ),
        ],
      ],
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.user});
  final User user;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final _username = TextEditingController(text: widget.user.username);
  late final _email = TextEditingController(text: widget.user.email);
  Map<String, List<String>> _errors = {};
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      final r = await app.api.patch('/account', {'username': _username.text.trim(), 'email': _email.text.trim()});
      app.setUser(User.fromJson(r['user'] as Map));
      if (mounted) toast(context, app.s.profileSaved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fields);
      if (e.fields.isEmpty) showError(context, e);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _username,
          autocorrect: false,
          decoration: InputDecoration(labelText: s.username, errorText: _errors['username']?.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(labelText: s.email, errorText: _errors['email']?.first),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? s.saving : s.saveProfile)),
        ),
      ],
    );
  }
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm();

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  Map<String, List<String>> _errors = {};
  bool _show = false;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final s = app.s;
    if (_next.text != _confirm.text) {
      setState(() => _errors = {'confirmPassword': [s.passwordsDiffer]});
      return;
    }
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      final r = await app.api.post('/account/password', {
        'currentPassword': _current.text,
        'newPassword': _next.text,
        'confirmPassword': _confirm.text,
      });
      // Every old token is revoked; keep using the new one.
      await app.replaceToken(r['token'] as String);
      _current.clear();
      _next.clear();
      _confirm.clear();
      if (mounted) toast(context, s.passwordChanged);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fields);
      if (e.fields.isEmpty) showError(context, e);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    InputDecoration deco(String label, String field, {String? helper}) => InputDecoration(
          labelText: label,
          helperText: helper,
          errorText: _errors[field]?.first,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(controller: _current, obscureText: !_show, decoration: deco(s.currentPassword, 'currentPassword')),
        const SizedBox(height: 12),
        TextField(controller: _next, obscureText: !_show, decoration: deco(s.newPassword, 'newPassword', helper: s.passwordHint)),
        const SizedBox(height: 12),
        TextField(controller: _confirm, obscureText: !_show, decoration: deco(s.confirmNewPassword, 'confirmPassword')),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _show,
          onChanged: (v) => setState(() => _show = v ?? false),
          title: Text(s.showPassword, style: const TextStyle(fontSize: 13.5)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? s.saving : s.changePassword)),
        ),
      ],
    );
  }
}
