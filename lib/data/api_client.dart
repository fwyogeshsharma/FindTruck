import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Thin wrapper over the FreightDesk REST API
/// (http://34.31.185.19:8090 — "Truck intelligence & dispatch platform").
///
/// Works on mobile and web (uses package:http). A bearer token, once set by
/// [AuthService], is attached to every request.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  /// Direct API origin (used on mobile, where there is no CORS).
  static const apiOrigin = 'http://34.31.185.19:8090';

  /// On web the server's missing CORS support blocks direct calls, so we route
  /// through the local proxy (`dart run tool/cors_proxy.dart`).
  static String get defaultBaseUrl =>
      kIsWeb ? 'http://localhost:8091' : apiOrigin;

  final String baseUrl;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> _headers({bool json = false}) => {
        'accept': 'application/json',
        if (json) 'content-type': 'application/json',
        if (_token != null) 'authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$baseUrl$path').replace(queryParameters: q?.isEmpty ?? true ? null : q);
  }

  Future<dynamic> getJson(String path, [Map<String, dynamic>? query]) async {
    final res = await http
        .get(_uri(path, query), headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _decode(res, 'GET $path');
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(_uri(path), headers: _headers(json: true), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _decode(res, 'POST $path');
  }

  dynamic _decode(http.Response res, String label) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        data = res.body;
      }
    }
    if (!ok) {
      throw ApiException(res.statusCode, _message(data) ?? '$label failed');
    }
    return data;
  }

  String? _message(dynamic data) {
    if (data is Map && data['detail'] != null) {
      final d = data['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty && d.first is Map) {
        return '${d.first['msg']}';
      }
    }
    return null;
  }
}

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => message;
}
