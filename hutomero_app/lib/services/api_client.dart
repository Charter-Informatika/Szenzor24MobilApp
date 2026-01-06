import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    } on Exception {
      // The server returned HTML (rendered page). Parse the table and
      // extract rows into MobileAlert objects. Be tolerant of tables that
      // omit a <tbody> and rely on `data-label` attributes where present.
      final body = resp.body;
      final doc = html_parser.parse(body);

      // Try a couple of selectors: rows inside tbody, or any table rows.
      var rows = doc.querySelectorAll('table tbody tr');

      final List<MobileAlert> alerts = [];
      for (final row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue; // not a data row

        // Build a map of data-label -> text when available so parsing
        // doesn't rely strictly on column order.
        final Map<String, String> labelled = {};
        for (final td in cells) {
          final label = td.attributes['data-label']?.trim() ?? '';
          final text = td.text.trim();
          if (label.isNotEmpty) {
            labelled[label] = text;
          }
        }

        try {
          // Prefer labelled values, fall back to index-based parsing.
          final sensorIdStr = labelled['Szenzor ID'] ?? (cells.isNotEmpty ? cells[0].text.trim() : '0');
          final sensorId = int.tryParse(sensorIdStr.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

          final valueRaw = labelled['Értek'] ?? (cells.length > 1 ? cells[1].text.trim() : '0');
          final value = double.tryParse(valueRaw.replaceAll(',', '.')) ?? 0.0;

          final type = labelled['Típus'] ?? (cells.length > 2 ? cells[2].text.trim() : '');
          final status = labelled['Státusz'] ?? (cells.length > 3 ? cells[3].text.trim() : '');
          final comment = labelled['Megjegyzés'] ?? (cells.length > 4 ? cells[4].text.trim() : '');
          final createdAtStr = labelled['Időpont'] ?? (cells.length > 5 ? cells[5].text.trim() : '');
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
          // Skip malformed row
          continue;
        }
      }

      return alerts;
    }
  }
}
