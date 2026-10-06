import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../config.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _error;
  int _wait = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _wait > 0) return;
    if (_id.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.app.login(_id.text.trim(), _password.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = errorMessage(context, e));
      if (e.status == 429 && e.retryAfter != null) _countdown(e.retryAfter!);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _countdown(int seconds) {
    _timer?.cancel();
    setState(() => _wait = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait--);
      if (_wait <= 0) {
        t.cancel();
        setState(() => _error = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(actions: const [LangButton(), ThemeButton(), SizedBox(width: 8)]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(dark ? 'assets/brand/logo-dark.png' : 'assets/brand/logo.png', height: 48),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(s.signInTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(s.signInIntro, style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13.5)),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _id,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(labelText: s.identifier),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              obscureText: !_show,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: s.password,
                                suffixIcon: IconButton(
                                  tooltip: _show ? s.hidePassword : s.showPassword,
                                  icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _show = !_show),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_wait > 0 ? s.tooMany(_wait) : _error!, style: TextStyle(color: context.colors.error, fontSize: 13.5)),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _busy || _wait > 0 ? null : _submit,
                              child: Text(_busy ? s.signingIn : s.signIn),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Signed in, but the account belongs to no mess (e.g. a super admin).
class NoMessScreen extends StatelessWidget {
  const NoMessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final web = kApiBase.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return Scaffold(
      appBar: AppBar(title: const BrandTitle(), actions: const [LangButton(), ThemeButton(), SizedBox(width: 8)]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(title: s.noMessTitle, hint: s.noMessIntro, icon: Icons.home_work_outlined),
              SelectableText(web, style: TextStyle(color: context.colors.primary)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.app.logout(),
                icon: const Icon(Icons.logout),
                label: Text(s.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
