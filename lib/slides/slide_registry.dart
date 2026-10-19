import 'package:flutter/foundation.dart';
import 'base_slide.dart';

/// Central registry holding all registered slide types.
class SlideRegistry {
  static final Map<String, BaseSlide> _registeredSlides = {};

  /// Registers a slide type definition
  static void register(BaseSlide slide) {
    _registeredSlides[slide.type] = slide;
  }

  /// Retrieves a slide handler by type ID, falling back to first registered slide if unknown
  static BaseSlide get(String type) {
    final slide = _registeredSlides[type];
    if (slide != null) {
      return slide;
    }
    debugPrint('SlideRegistry: Unknown slide type "$type", falling back to default registered slide.');
    return _registeredSlides.values.first;
  }

  /// Returns all registered slide types
  static List<BaseSlide> get all => _registeredSlides.values.toList();

  /// Returns all registered slide type keys
  static List<String> get registeredTypes => _registeredSlides.keys.toList();
}
