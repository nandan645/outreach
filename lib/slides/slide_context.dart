import 'package:flutter/material.dart';
import '../presentation_editor_screen.dart';

/// Context object containing runtime properties and UI callbacks passed to slide renderers.
class SlideRenderContext {
  final SlideData slide;
  final Color accentColor;
  final bool isEditing;
  final String? folderPath;
  final String? companyLogoPath;
  final String? companyName;
  final TextEditingController? titleController;
  final TextEditingController? subtitleController;
  final Function(String)? onTitleChanged;
  final Function(String)? onSubtitleChanged;
  final String? selectedElementKey;
  final Function(String key)? onSelectElement;
  final Function(String imageKey, String path)? onImageChanged;
  final Widget Function(BuildContext context)? buildTitleHeaderCallback;

  SlideRenderContext({
    required this.slide,
    required this.accentColor,
    this.isEditing = false,
    this.folderPath,
    this.companyLogoPath,
    this.companyName,
    this.titleController,
    this.subtitleController,
    this.onTitleChanged,
    this.onSubtitleChanged,
    this.selectedElementKey,
    this.onSelectElement,
    this.onImageChanged,
    this.buildTitleHeaderCallback,
  });


  /// Builds standard editable/selectable title header
  Widget buildTitleHeader(BuildContext context) {
    final builder = buildTitleHeaderCallback;
    if (builder != null) {
      return builder(context);
    }
    return const SizedBox.shrink();
  }
}
