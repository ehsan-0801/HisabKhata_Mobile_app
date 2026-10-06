import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Every API error has the shape { error: { code, message, fields? } }.
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, {this.fields = const {}, this.retryAfter});

  final int status;
  final String code;
  final String message;
  final Map<String, List<String>> fields;
  final int? retryAfter;

  /// The first message for a field (shown under the input), or null.
  String? field(String name) => fields[name]?.isNotEmpty == true ? fields[name]!.first : null;

  bool get isUnauthorized => status == 401;
  bool get isNoMess => code == 'no_mess';
  bool get isOffline => code == 'offline';

  @override
  String toString() => message;
}

class Api {
  Api({required this.token, required this.onUnauthorized, http.Client? client}) : _client = client ?? http.Client();

  final String? Function() token;
  final void Function() onUnauthorized;
  final http.Client _client;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body ?? const {});
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body);
  Future<dynamic> put(String path, Object body) => _send('PUT', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final req = http.Request(method, Uri.parse('$kApiBase$path'));
    req.headers['Accept'] = 'application/json';
    final t = token();
    if (t != null) req.headers['Authorization'] = 'Bearer $t';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }

    http.Response res;
    try {
      res = await http.Response.fromStream(await _client.send(req).timeout(const Duration(seconds: 30)));
    } on SocketException {
      throw ApiException(0, 'offline', 'No internet connection.');
    } on TimeoutException {
      throw ApiException(0, 'offline', 'The server took too long to answer.');
    } on http.ClientException {
      throw ApiException(0, 'offline', 'Could not reach the server.');
    }

    final text = utf8.decode(res.bodyBytes);
    final data = text.isEmpty ? null : _tryJson(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final err = data is Map && data['error'] is Map ? data['error'] as Map : const {};
    final fields = <String, List<String>>{};
    if (err['fields'] is Map) {
      (err['fields'] as Map).forEach((k, v) {
        fields[k.toString()] = v is List ? v.map((e) => e.toString()).toList() : [v.toString()];
      });
    }
    final e = ApiException(
      res.statusCode,
      (err['code'] ?? 'http_${res.statusCode}').toString(),
      (err['message'] ?? 'Something went wrong (${res.statusCode}).').toString(),
      fields: fields,
      retryAfter: int.tryParse(res.headers['retry-after'] ?? ''),
    );
    // A wrong password at sign-in is also a 401, but there's no session to drop then.
    if (e.isUnauthorized && t != null) onUnauthorized();
    throw e;
  }

  static dynamic _tryJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }
}
