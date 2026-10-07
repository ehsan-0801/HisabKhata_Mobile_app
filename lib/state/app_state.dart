import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../i18n/strings.dart';
import '../models.dart';
import '../widgets/common.dart' show loaderCache;

enum Phase { booting, signedOut, noMess, ready, offline }

/// Session (token, user, mess) plus the app's language and theme.
class AppState extends ChangeNotifier {
  AppState() {
    api = Api(token: () => _token, onUnauthorized: _dropSession);
  }

  static const _tokenKey = 'hk_token';
  static const _langKey = 'hk_lang';
  static const _themeKey = 'hk_theme';

  final _secure = const FlutterSecureStorage();
  late final Api api;

  String? _token;
  Phase phase = Phase.booting;
  User? user;
  Mess? mess;

  bool bn = true; // Bangla is the default, like the website.
  ThemeMode themeMode = ThemeMode.system;

  /// The bottom-menu tab on screen (0 Monthly, 1 Members, 2 Bills, 3 Items, 4 Settings);
  /// set it to jump there, e.g. from the Rent tab's "Members page" link.
  final tab = ValueNotifier<int>(0);

  /// Bumped after every change so all open screens reload their data.
  int revision = 0;
  void changed() {
    revision++;
    notifyListeners();
  }

  S get s => S(bn);
  bool get canWrite => mess?.canWrite ?? false;

  Future<void> boot() async {
    final prefs = await SharedPreferences.getInstance();
    bn = (prefs.getString(_langKey) ?? 'bn') == 'bn';
    themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    try {
      _token = await _secure.read(key: _tokenKey);
    } catch (_) {
      _token = null;
    }
    if (_token == null) {
      _go(Phase.signedOut);
      return;
    }
    try {
      await _loadSession();
    } on ApiException catch (e) {
      if (e.isUnauthorized) return; // _dropSession already ran
      // Offline (or the server is down) at start-up: keep the token and offer a retry.
      _go(Phase.offline);
    } catch (_) {
      _go(Phase.offline);
    }
  }

  /// Retry from the "can't connect" screen.
  Future<void> retryBoot() async {
    _go(Phase.booting);
    await boot();
  }

  Future<void> _loadSession() async {
    final me = await api.get('/auth/me');
    user = User.fromJson((me is Map && me['user'] is Map ? me['user'] : me) as Map);
    try {
      final r = await api.get('/mess');
      mess = Mess.fromJson(r['mess'] as Map);
      _go(Phase.ready);
    } on ApiException catch (e) {
      if (!e.isNoMess) rethrow;
      mess = null;
      _go(Phase.noMess);
    }
  }

  Future<void> login(String identifier, String password) async {
    final r = await api.post('/auth/login', {'identifier': identifier, 'password': password});
    await _setToken(r['token'] as String);
    await _loadSession();
  }

  /// After a password change the server hands out a new token; all old ones stop working.
  Future<void> replaceToken(String token) => _setToken(token);

  Future<void> refreshMess() async {
    final r = await api.get('/mess');
    mess = Mess.fromJson(r['mess'] as Map);
    notifyListeners();
  }

  void setUser(User u) {
    user = u;
    notifyListeners();
  }

  void setMess(Mess m) {
    mess = m;
    notifyListeners();
  }

  /// Signs out this device only (forgets the token).
  Future<void> logout() async {
    loaderCache.clear();
    tab.value = 0;
    await _clearToken();
    user = null;
    mess = null;
    _go(Phase.signedOut);
  }

  /// Revokes every token and web session for this account.
  Future<void> logoutEverywhere() async {
    try {
      await api.post('/auth/logout-all');
    } finally {
      await logout();
    }
  }

  Future<void> toggleLang() async {
    bn = !bn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, bn ? 'bn' : 'en');
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  /// Light → dark → system, like the web header button.
  Future<void> cycleTheme() => setTheme(switch (themeMode) {
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
        ThemeMode.system => ThemeMode.light,
      });

  Future<void> _setToken(String t) async {
    _token = t;
    try {
      await _secure.write(key: _tokenKey, value: t);
    } catch (_) {/* keep it in memory for this run */}
  }

  Future<void> _clearToken() async {
    _token = null;
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {}
  }

  void _dropSession() {
    if (_token == null) return;
    loaderCache.clear();
    _clearToken();
    user = null;
    mess = null;
    _go(Phase.signedOut);
  }

  void _go(Phase p) {
    phase = p;
    notifyListeners();
  }
}
