import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/mobile_alert.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  /// Call the server login endpoint and capture the Set-Cookie header.
  /// Optionally provide a JSON body (e.g. credentials). The method stores
  /// the cookie for subsequent requests.
  Future<String?> login([Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl/login');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );

    final redirectLocation = resp.headers['location'] ?? '';
    if ((resp.statusCode != 200 || resp.statusCode != 302) && redirectLocation.contains('login')) {
      throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
    }

    final setCookie = resp.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      // Extract the first "name=value" segment before any ;
      return setCookie.split(';').first.trim();
    }
    return null;
  }

  Future<List<MobileAlert>> getAlerts(String? cookie) async {
    final uri = Uri.parse('$baseUrl/warnings');

    final headers = <String, String>{};
    if (cookie != null) {
      headers['Cookie'] = cookie;
    } else {
      throw Exception('Nincs érvényes munkamenet süti a riasztások lekéréséhez.');
    }

    final resp = await http.get(uri, headers: headers);

    // Try parsing JSON first. The server may return a rendered HTML page
    // (302/HTML) containing the warnings; in that case we attempt to
    // extract a JSON array embedded in the HTML. Do not fail immediately
    // on non-200 status codes — parse the body instead.
    try {
      final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;
      return jsonList
          .map((e) => MobileAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      // The server returned HTML (rendered page). Parse the table and
      // extract rows into MobileAlert objects.
      final body = resp.body;
      final doc = html_parser.parse(body);

      // Look for the table rows inside a tbody
      final rows = doc.querySelectorAll('table tbody tr');
      if (rows.isNotEmpty) {
        final List<MobileAlert> alerts = [];
        for (final row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length < 6) continue; // unexpected row

          try {
            final sensorId = int.tryParse(cells[0].text.trim()) ?? 0;
            final valueRaw = cells[1].text.trim().replaceAll(',', '.');
            final value = double.tryParse(valueRaw) ?? 0.0;
            final type = cells[2].text.trim();
            final status = cells[3].text.trim();
            final comment = cells[4].text.trim();
            final createdAtStr = cells[5].text.trim();
            final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

            alerts.add(MobileAlert(
              id: 0,
              value: value,
              type: type,
              status: status,
              comment: comment.isEmpty ? null : comment,
              createdAt: createdAt,
              sensorId: sensorId,
              sensorName: '',
              deviceId: 0,
              deviceName: '',
              min: null,
              max: null,
            ));
          } catch (_) {
            // skip malformed row
            continue;
          }
        }

        if (alerts.isNotEmpty) return alerts;
      }

      // No parsable rows found — provide a helpful error including a short
      // HTML snippet so the server-rendered output can be inspected.
      final snippet = body.length > 300 ? body.substring(0, 300) + '...' : body;
      throw Exception('Expected JSON but server returned HTML/other. Snippet: $snippet');
    }
  }
}
