import 'package:flutter/material.dart';
import 'slide_context.dart';

/// Abstract base class that all modular slide types must implement.
abstract class BaseSlide {
  /// Unique identifier key for this slide type (e.g. 'standard', 'metric_cards', 'hero_diagram')
  String get type;

  /// User-friendly display name for this slide type
  String get displayName;

  /// Builds the Flutter widget layout for this slide given the render context
  Widget build(SlideRenderContext context);
}
