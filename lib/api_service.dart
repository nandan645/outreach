import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const List<String> candidateUrls = [
    'https://ppts.nandanabhi.me',
    'https://api.nandanabhi.me',
  ];

  static String baseUrl = 'https://ppts.nandanabhi.me';

  static String resolveAssetUrl(String rawPath, String presentationId) {
    if (rawPath.isEmpty) return '';
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://') || rawPath.startsWith('data:')) {
      return rawPath;
    }
    if (rawPath.startsWith('assets/prompts/') ||
        rawPath.startsWith('assets/india_network_map.png') ||
        rawPath.startsWith('assets/presets/') ||
        rawPath.startsWith('assets/hero/')) {
      return rawPath;
    }

    String cleanPath = rawPath.replaceAll('\\', '/');
    if (cleanPath.startsWith('/api/assets/')) {
      return '$baseUrl$cleanPath';
    }

    String effectivePresId = presentationId.replaceAll('\\', '/');
    if (effectivePresId.contains('/')) {
      effectivePresId = effectivePresId.split('/').where((s) => s.isNotEmpty).last;
    }

    if (cleanPath.contains('/assets/')) {
      final parts = cleanPath.split('/assets/');
      if (effectivePresId.isEmpty) {
        final folderName = parts.first.split('/').last;
        if (folderName.isNotEmpty && folderName != 'api') {
          effectivePresId = folderName;
        }
      }
      cleanPath = 'assets/${parts.last}';
    }

    if (cleanPath.startsWith('global_assets/')) {
      return '$baseUrl/api/assets/$cleanPath';
    }

    if (cleanPath.startsWith('assets/')) {
      if (effectivePresId.isNotEmpty && effectivePresId != 'global_assets') {
        return '$baseUrl/api/assets/$effectivePresId/$cleanPath';
      }
      return '$baseUrl/api/assets/global_assets/$cleanPath';
    }

    if (effectivePresId.isNotEmpty && effectivePresId != 'global_assets') {
      return '$baseUrl/api/assets/$effectivePresId/assets/$cleanPath';
    }
    return '$baseUrl/api/assets/global_assets/$cleanPath';
  }

  static Future<http.Response?> _request(Future<http.Response> Function(String base) requestFn) async {
    // 1. Try current baseUrl
    try {
      final res = await requestFn(baseUrl);
      if (res.statusCode >= 200 && res.statusCode < 500) {
        return res;
      }
    } catch (_) {}

    // 2. Try candidate fallback URLs
    for (final candidate in candidateUrls) {
      if (candidate == baseUrl) continue;
      try {
        final res = await requestFn(candidate);
        if (res.statusCode >= 200 && res.statusCode < 500) {
          baseUrl = candidate;
          return res;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> checkHealth() async {
    final res = await _request((base) => http.get(Uri.parse('$base/api/health')).timeout(const Duration(seconds: 4)));
    return res != null && res.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final res = await _request((base) => http.get(Uri.parse('$base/api/settings')).timeout(const Duration(seconds: 5)));
      if (res != null && res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.getSettings error: $e');
    }
    return {};
  }

  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final res = await _request((base) => http.post(
        Uri.parse('$base/api/settings'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(settings),
      ).timeout(const Duration(seconds: 5)));
      return res != null && res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.saveSettings error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPresentations() async {
    try {
      final res = await _request((base) => http.get(Uri.parse('$base/api/presentations')).timeout(const Duration(seconds: 10)));
      if (res != null && res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final list = json['presentations'] as List?;
        if (list != null) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getPresentations error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createPresentation({
    required String id,
    required Map<String, dynamic> manifest,
    required Map<String, dynamic> presentation,
    String? sourceId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'id': id,
        'manifest': manifest,
        'presentation': presentation,
      };
      if (sourceId != null && sourceId.isNotEmpty) {
        payload['sourceId'] = sourceId;
      }

      final res = await _request((base) => http.post(
        Uri.parse('$base/api/presentations'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10)));

      if (res != null && res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.createPresentation error: $e');
    }
    return null;
  }

  static Future<bool> savePresentation({
    required String id,
    Map<String, dynamic>? manifest,
    Map<String, dynamic>? presentation,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (manifest != null) payload['manifest'] = manifest;
      if (presentation != null) payload['presentation'] = presentation;

      final res = await _request((base) => http.post(
        Uri.parse('$base/api/presentations/$id/save'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10)));

      return res != null && res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.savePresentation error: $e');
      return false;
    }
  }

  static Future<bool> deletePresentation(String id) async {
    try {
      final res = await _request((base) => http.delete(Uri.parse('$base/api/presentations/$id')).timeout(const Duration(seconds: 5)));
      return res != null && res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deletePresentation error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> uploadFile({
    required String presentationId,
    required String filename,
    required List<int> bytes,
  }) async {
    try {
      final bytesBase64 = base64Encode(bytes);
      final res = await _request((base) => http.post(
        Uri.parse('$base/api/upload'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'presentationId': presentationId,
          'filename': filename,
          'bytesBase64': bytesBase64,
        }),
      ).timeout(const Duration(seconds: 30)));

      if (res != null && res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.uploadFile error: $e');
    }
    return null;
  }
}
