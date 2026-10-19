import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// A highly customizable, responsive slide supporting 1 to 6 images with dynamic
/// multi-image layouts (Auto, Columns, Grid, Hero Split, and Stacked Rows).
class CustomSlide extends BaseSlide {
  @override
  String get type => 'custom_slide';

  @override
  String get displayName => 'Custom Slide';

  @override
  Widget build(SlideRenderContext renderContext) {
    return _CustomSlideWidget(renderContext: renderContext);
  }
}

class _CustomSlideWidget extends StatefulWidget {
  final SlideRenderContext renderContext;

  const _CustomSlideWidget({required this.renderContext});

  @override
  State<_CustomSlideWidget> createState() => _CustomSlideWidgetState();
}

class _CustomSlideWidgetState extends State<_CustomSlideWidget> {
  int _getEffectiveCount(SlideData slide) {
    final rawVal = slide.rawContent['custom_images_count'];
    if (rawVal is int) return rawVal.clamp(1, 6);
    if (rawVal is String) {
      final parsed = int.tryParse(rawVal);
      if (parsed != null) return parsed.clamp(1, 6);
    }
    // Infer count from existing non-empty slots if any
    int detected = 1;
    for (int i = 1; i < 6; i++) {
      if (slide.getImagePath('custom_image_$i').isNotEmpty) {
        detected = i + 1;
      }
    }
    return detected;
  }

  String _getEffectiveLayoutMode(SlideData slide) {
    final mode = slide.rawContent['custom_layout_mode']?.toString();
    const validModes = ['auto', 'columns', 'grid', 'hero', 'rows'];
    if (mode != null && validModes.contains(mode)) {
      return mode;
    }
    return 'auto';
  }

  String _getImagePathForSlot(SlideData slide, int index) {
    if (index == 0) {
      final p0 = slide.getImagePath('custom_image_0');
      if (p0.isNotEmpty) return p0;
      return slide.getImagePath('custom_image');
    }
    return slide.getImagePath('custom_image_$index');
  }

  void _setImagePathForSlot(int index, String path) {
    final callback = widget.renderContext.onImageChanged;
    if (callback == null) return;
    if (index == 0) {
      callback('custom_image_0', path);
      callback('custom_image', path);
    } else {
      callback('custom_image_$index', path);
    }
  }

  void _removeImageSlot(int removeIndex, int currentCount) {
    final callback = widget.renderContext.onImageChanged;
    if (callback == null) return;

    if (currentCount <= 1) {
      _setImagePathForSlot(0, '');
      return;
    }

    // Shift remaining images forward
    final slide = widget.renderContext.slide;
    for (int i = removeIndex; i < currentCount - 1; i++) {
      final nextPath = _getImagePathForSlot(slide, i + 1);
      _setImagePathForSlot(i, nextPath);
    }
    // Clear last slot
    _setImagePathForSlot(currentCount - 1, '');
    callback('custom_images_count', '${currentCount - 1}');
  }

  @override
  Widget build(BuildContext context) {
    final renderContext = widget.renderContext;
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accentColor = renderContext.accentColor;
    final canEdit = renderContext.onImageChanged != null;

    final imageCount = _getEffectiveCount(slide);
    final layoutMode = _getEffectiveLayoutMode(slide);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Standard Slide Header (Title & Subtitle / Description)
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 10),

        // Responsive Multi-Image Canvas Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveLayout(
                context,
                constraints: constraints,
                slide: slide,
                isLight: isLight,
                accentColor: accentColor,
                imageCount: imageCount,
                layoutMode: layoutMode,
                canEdit: canEdit,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Master responsive layout switcher
  Widget _buildResponsiveLayout(
    BuildContext context, {
    required BoxConstraints constraints,
    required SlideData slide,
    required bool isLight,
    required Color accentColor,
    required int imageCount,
    required String layoutMode,
    required bool canEdit,
  }) {
    if (imageCount <= 1) {
      return _buildSingleSlot(context, 0, slide, isLight, accentColor, canEdit, imageCount);
    }

    String effectiveMode = layoutMode;
    if (layoutMode == 'auto') {
      effectiveMode = _resolveAutoLayout(imageCount, constraints.maxWidth);
    }

    switch (effectiveMode) {
      case 'columns':
        return _buildColumnsLayout(context, constraints, slide, isLight, accentColor, canEdit, imageCount);
      case 'rows':
        return _buildRowsLayout(context, slide, isLight, accentColor, canEdit, imageCount);
      case 'hero':
        return _buildHeroSplitLayout(context, constraints, slide, isLight, accentColor, canEdit, imageCount);
      case 'grid':
      default:
        return _buildGridLayout(context, constraints, slide, isLight, accentColor, canEdit, imageCount);
    }
  }

  String _resolveAutoLayout(int count, double width) {
    if (count == 2) {
      return width > 500 ? 'columns' : 'rows';
    }
    if (count == 3) {
      if (width > 750) return 'columns';
      if (width > 480) return 'hero';
      return 'rows';
    }
    if (count == 4) {
      return 'grid';
    }
    // 5 or 6 items
    return 'grid';
  }

  /// 1 Image: Full Expansive Slot
  Widget _buildSingleSlot(
    BuildContext context,
    int index,
    SlideData slide,
    bool isLight,
    Color accentColor,
    bool canEdit,
    int totalCount,
  ) {
    return _buildSlotContainer(
      context,
      index: index,
      slide: slide,
      isLight: isLight,
      accentColor: accentColor,
      canEdit: canEdit,
      totalCount: totalCount,
    );
  }

  /// Columns Layout (Side-by-side)
  Widget _buildColumnsLayout(
    BuildContext context,
    BoxConstraints constraints,
    SlideData slide,
    bool isLight,
    Color accentColor,
    bool canEdit,
    int count,
  ) {
    if (constraints.maxWidth < 420) {
      // Responsive fallback for very narrow viewports
      return _buildRowsLayout(context, slide, isLight, accentColor, canEdit, count);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(count, (idx) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx == count - 1 ? 0 : 12),
            child: _buildSlotContainer(
              context,
              index: idx,
              slide: slide,
              isLight: isLight,
              accentColor: accentColor,
              canEdit: canEdit,
              totalCount: count,
            ),
          ),
        );
      }),
    );
  }

  /// Rows Layout (Stacked vertically)
  Widget _buildRowsLayout(
    BuildContext context,
    SlideData slide,
    bool isLight,
    Color accentColor,
    bool canEdit,
    int count,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(count, (idx) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: idx == count - 1 ? 0 : 12),
            child: _buildSlotContainer(
              context,
              index: idx,
              slide: slide,
              isLight: isLight,
              accentColor: accentColor,
              canEdit: canEdit,
              totalCount: count,
            ),
          ),
        );
      }),
    );
  }

  /// Hero Split Layout (Main prominent image on left, secondary images stacked on right)
  Widget _buildHeroSplitLayout(
    BuildContext context,
    BoxConstraints constraints,
    SlideData slide,
    bool isLight,
    Color accentColor,
    bool canEdit,
    int count,
  ) {
    final isWide = constraints.maxWidth >= 550;

    if (!isWide) {
      // Stack hero on top, secondary side-by-side below
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 55,
            child: _buildSlotContainer(
              context,
              index: 0,
              slide: slide,
              isLight: isLight,
              accentColor: accentColor,
              canEdit: canEdit,
              totalCount: count,
              badgeLabel: 'Hero Image',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 45,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(count - 1, (i) {
                final idx = i + 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == count - 2 ? 0 : 12),
                    child: _buildSlotContainer(
                      context,
                      index: idx,
                      slide: slide,
                      isLight: isLight,
                      accentColor: accentColor,
                      canEdit: canEdit,
                      totalCount: count,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    }

    // Wide: Hero on left (60%), Stacked column on right (40%)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 60,
          child: _buildSlotContainer(
            context,
            index: 0,
            slide: slide,
            isLight: isLight,
            accentColor: accentColor,
            canEdit: canEdit,
            totalCount: count,
            badgeLabel: 'Hero Image',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(count - 1, (i) {
              final idx = i + 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i == count - 2 ? 0 : 12),
                  child: _buildSlotContainer(
                    context,
                    index: idx,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Balanced Grid Layout (2x2, 3x2, or 1+2)
  Widget _buildGridLayout(
    BuildContext context,
    BoxConstraints constraints,
    SlideData slide,
    bool isLight,
    Color accentColor,
    bool canEdit,
    int count,
  ) {
    if (count == 2) {
      return _buildColumnsLayout(context, constraints, slide, isLight, accentColor, canEdit, count);
    }

    if (count == 3) {
      // 1 Top, 2 Bottom
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 50,
            child: _buildSlotContainer(
              context,
              index: 0,
              slide: slide,
              isLight: isLight,
              accentColor: accentColor,
              canEdit: canEdit,
              totalCount: count,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildSlotContainer(
                    context,
                    index: 1,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSlotContainer(
                    context,
                    index: 2,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (count == 4) {
      // 2x2 Grid
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildSlotContainer(
                    context,
                    index: 0,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSlotContainer(
                    context,
                    index: 1,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildSlotContainer(
                    context,
                    index: 2,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSlotContainer(
                    context,
                    index: 3,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 5 or 6 items: 2 rows (3 on top, 2 or 3 below)
    final topCount = 3;
    final bottomCount = count - topCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(topCount, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == topCount - 1 ? 0 : 12),
                  child: _buildSlotContainer(
                    context,
                    index: i,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(bottomCount, (i) {
              final idx = topCount + i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == bottomCount - 1 ? 0 : 12),
                  child: _buildSlotContainer(
                    context,
                    index: idx,
                    slide: slide,
                    isLight: isLight,
                    accentColor: accentColor,
                    canEdit: canEdit,
                    totalCount: count,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Individual Image Card Container with ImageDropzone & Slot Badge/Remove Button
  Widget _buildSlotContainer(
    BuildContext context, {
    required int index,
    required SlideData slide,
    required bool isLight,
    required Color accentColor,
    required bool canEdit,
    required int totalCount,
    String? badgeLabel,
  }) {
    final imageKey = index == 0 ? 'custom_image' : 'custom_image_$index';
    final initialPath = _getImagePathForSlot(slide, index);
    final cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.025 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Main Image Dropzone / Picker filling full slot
          Positioned.fill(
            child: ImageDropzoneWidget(
              slideId: slide.id,
              imageKey: imageKey,
              companyName: widget.renderContext.companyName,
              label: 'Slot ${index + 1} Image',
              formatHint: 'Presets or Upload',
              height: double.infinity,
              initialImagePath: initialPath,
              folderPath: widget.renderContext.folderPath,
              onImageSelected: (path) {
                _setImagePathForSlot(index, path);
              },
            ),
          ),

          // Slot Badge & Delete Slot Button (when canEdit and totalCount > 1)
          if (canEdit && totalCount > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeLabel ?? 'Slot ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _removeImageSlot(index, totalCount),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Color(0xCCEF4444), // Crimson badge
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
