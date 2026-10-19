import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

/// Normalizes legacy and relative asset paths to their current standard location in `assets/presets/`.
String normalizeAssetPath(String rawPath) {
  if (rawPath.isEmpty) return '';
  String clean = rawPath.replaceAll('\\', '/').trim();

  // If data URI, HTTP/HTTPS, or file URI, return as-is
  if (clean.startsWith('data:') ||
      clean.startsWith('http://') ||
      clean.startsWith('https://') ||
      clean.startsWith('file://')) {
    return clean;
  }

  // Remove leading './' or '/'
  while (clean.startsWith('./') || clean.startsWith('/')) {
    if (clean.startsWith('./')) clean = clean.substring(2);
    if (clean.startsWith('/')) clean = clean.substring(1);
  }

  // Preset subfolders
  const presetFolders = [
    'logo_presets',
    'metric_cards',
    'comparison_ecosystem_presets',
    'mobile_mockup',
    'multi_feature_showcase',
    'dynamic_presets',
    'architecture_flow_presets',
    'consumer_experience',
    'platform_showcase',
    'enterprise_brain',
    'patient_journey_steps',
    'intelligence_dashboards',
    'modular_ui_mockups',
    'core_capabilities',
  ];

  for (final folder in presetFolders) {
    if (clean.startsWith('assets/$folder/')) {
      return clean.replaceFirst('assets/$folder/', 'assets/presets/$folder/');
    }
    if (clean.startsWith('$folder/')) {
      return 'assets/presets/$clean';
    }
  }

  // Handle paths starting with 'presets/'
  if (clean.startsWith('presets/')) {
    return 'assets/$clean';
  }

  // Ensure standard 'assets/' prefix
  if (clean.startsWith('assets/')) {
    return clean;
  }

  // Known root assets
  if (clean == 'india_network_map.png' ||
      clean.startsWith('hero/') ||
      clean.startsWith('prompts/')) {
    return 'assets/$clean';
  }

  return clean;
}

Widget buildUniversalImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  Alignment alignment = Alignment.center,
  String presentationId = '',
  Widget? fallback,
}) {
  if (path.isEmpty) {
    return fallback ?? const SizedBox.shrink();
  }

  final normalizedPath = normalizeAssetPath(path);

  // 1. Data URL (base64)
  if (normalizedPath.startsWith('data:image/')) {
    try {
      final base64Data = normalizedPath.split(',').last;
      final bytes = base64Decode(base64Data);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
      );
    } catch (_) {
      return fallback ?? const SizedBox.shrink();
    }
  }

  // 2. Direct HTTP/HTTPS URL
  if (normalizedPath.startsWith('http://') || normalizedPath.startsWith('https://')) {
    return Image.network(
      normalizedPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
    );
  }

  // 3. Local disk file path (non-web)
  if (!kIsWeb) {
    try {
      final filePath = normalizedPath.startsWith('file://') ? Uri.parse(normalizedPath).toFilePath() : normalizedPath;
      final file = File(filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
        );
      }
    } catch (_) {}
  }

  // 4. Bundled Flutter assets (e.g., presets, hero icons)
  if (normalizedPath.startsWith('assets/prompts/') ||
      normalizedPath.startsWith('assets/india_network_map.png') ||
      normalizedPath.startsWith('assets/presets/') ||
      normalizedPath.startsWith('assets/hero/')) {
    return Image.asset(
      normalizedPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
    );
  }

  // 5. Server-hosted assets resolved via ApiService
  final resolvedUrl = ApiService.resolveAssetUrl(normalizedPath, presentationId);
  if (resolvedUrl.startsWith('assets/')) {
    return Image.asset(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
    );
  }

  return Image.network(
    resolvedUrl,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
  );
}
