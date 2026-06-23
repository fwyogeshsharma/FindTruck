// Local CORS proxy for web development.
//
// The FreightDesk API (http://34.31.185.19:8090) sends no CORS headers and
// returns 405 for OPTIONS preflight, so a browser blocks every call. This
// tiny proxy adds permissive CORS headers, answers preflight, and forwards
// everything else to the API unchanged.
//
// Run it before `flutter run -d chrome`:
//   dart run tool/cors_proxy.dart
//
// The web build points ApiClient at http://localhost:8091 automatically.
// Mobile builds talk to the API directly and do not need this.

import 'dart:io';

const target = 'http://34.31.185.19:8090';
const port = 8091;

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('CORS proxy listening on http://localhost:$port -> $target');
  final client = HttpClient();

  await for (final req in server) {
    final res = req.response;
    res.headers.set('Access-Control-Allow-Origin', '*');
    res.headers.set(
        'Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT, DELETE, OPTIONS');
    res.headers.set('Access-Control-Allow-Headers',
        'Content-Type, Authorization, Accept');
    res.headers.set('Access-Control-Max-Age', '86400');

    if (req.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      continue;
    }

    try {
      final body = await req.fold<List<int>>([], (b, d) => b..addAll(d));
      final uri = Uri.parse('$target${req.uri}');
      final pReq = await client.openUrl(req.method, uri);
      req.headers.forEach((name, values) {
        if (name.toLowerCase() == 'host') return;
        for (final v in values) {
          pReq.headers.add(name, v);
        }
      });
      if (body.isNotEmpty) pReq.add(body);
      final pRes = await pReq.close();

      res.statusCode = pRes.statusCode;
      final ct = pRes.headers.contentType;
      if (ct != null) res.headers.contentType = ct;
      await pRes.forEach(res.add);
      await res.close();
    } catch (e) {
      res.statusCode = HttpStatus.badGateway;
      res.write('proxy error: $e');
      await res.close();
    }
  }
}
