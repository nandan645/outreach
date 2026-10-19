import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// A highly customizable, responsive slide supporting 1 to 6 slots.
/// Each slot can independently be configured as an Image, a Text card,
/// or a combined Image + Text block across multiple responsive layouts
/// (Auto, Columns, Grid, Hero Split, and Stacked Rows).
///
/// When "Both" is selected, users can drag and drop to swap the positions
/// of the Image and Text sections, or tap the interactive Swap button.
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
    // Infer count from existing non-empty slots or slot types
    int detected = 1;
    for (int i = 1; i < 6; i++) {
      if (slide.getImagePath('custom_image_$i').isNotEmpty ||
          slide.rawContent['custom_slot_${i}_type'] != null ||
          slide.rawContent['text_overrides']?['card_${i + 1}_title'] != null) {
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

  String _getSlotType(SlideData slide, int index) {
    final explicitType = slide.rawContent['custom_slot_${index}_type']?.toString();
    if (explicitType != null && ['image', 'text', 'both'].contains(explicitType)) {
      return explicitType;
    }
    return 'image';
  }

  bool _isTextFirstInSlot(SlideData slide, int index) {
    return slide.rawContent['custom_slot_${index}_order'] == 'text_first';
  }

  void _toggleSlotOrder(int index) {
    final callback = widget.renderContext.onImageChanged;
    if (callback == null) return;
    final isTextFirst = _isTextFirstInSlot(widget.renderContext.slide, index);
    callback('custom_slot_${index}_order', isTextFirst ? 'image_first' : 'text_first');
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
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    final slide = widget.renderContext.slide;
    slide.deleteCustomSlot(removeIndex);

    final callback = widget.renderContext.onImageChanged;
    if (callback != null) {
      final newCount = slide.rawContent['custom_images_count']?.toString() ?? '1';
      callback('custom_images_count', newCount);
    }
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

        // Responsive Multi-Slot Canvas Area
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
      return _buildSlotContainer(
        context,
        index: 0,
        slide: slide,
        isLight: isLight,
        accentColor: accentColor,
        canEdit: canEdit,
        totalCount: imageCount,
      );
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

  /// Hero Split Layout (Main prominent slot on left, secondary slots stacked on right)
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

    // 5 or 6 items
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

  /// Individual Slot Container supporting Image, Text, or Both (with drag & drop swap)
  Widget _buildSlotContainer(
    BuildContext context, {
    required int index,
    required SlideData slide,
    required bool isLight,
    required Color accentColor,
    required bool canEdit,
    required int totalCount,
  }) {
    final slotType = _getSlotType(slide, index);
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
          // Slot Main Body
          Positioned.fill(
            child: _buildSlotBody(
              context,
              index: index,
              slotType: slotType,
              slide: slide,
              isLight: isLight,
              accentColor: accentColor,
              canEdit: canEdit,
            ),
          ),

          // Remove / Clear Slot Button (when editing)
          if (canEdit)
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: totalCount > 1 ? 'Remove slot' : 'Clear slot',
                child: InkWell(
                  onTap: () => _removeImageSlot(index, totalCount),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xCCEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds slot content depending on slotType: 'image', 'text', or 'both'
  Widget _buildSlotBody(
    BuildContext context, {
    required int index,
    required String slotType,
    required SlideData slide,
    required bool isLight,
    required Color accentColor,
    required bool canEdit,
  }) {
    if (slotType == 'text') {
      return _buildTextCardContent(context, index, slide, isLight, accentColor);
    }

    if (slotType == 'both') {
      return _buildBothSlotWithDragSwap(
        context,
        index: index,
        slide: slide,
        isLight: isLight,
        accentColor: accentColor,
        canEdit: canEdit,
      );
    }

    // Default: Image only
    return _buildImageContent(index, slide);
  }

  /// Combined "Both" Slot with Interactive Drag & Drop + Clickable Swapping
  Widget _buildBothSlotWithDragSwap(
    BuildContext context, {
    required int index,
    required SlideData slide,
    required bool isLight,
    required Color accentColor,
    required bool canEdit,
  }) {
    final isTextFirst = _isTextFirstInSlot(slide, index);

    final imageWidget = _buildDraggableSection(
      context: context,
      slotIndex: index,
      sectionType: 'image',
      canEdit: canEdit,
      accentColor: accentColor,
      isLight: isLight,
      child: _buildImageContent(index, slide),
    );

    final textWidget = _buildDraggableSection(
      context: context,
      slotIndex: index,
      sectionType: 'text',
      canEdit: canEdit,
      accentColor: accentColor,
      isLight: isLight,
      child: _buildTextCardContent(context, index, slide, isLight, accentColor, isCompact: true),
    );

    final dividerWidget = Container(
      height: 1,
      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: isTextFirst
          ? [
              Expanded(flex: 48, child: textWidget),
              dividerWidget,
              Expanded(flex: 52, child: imageWidget),
            ]
          : [
              Expanded(flex: 52, child: imageWidget),
              dividerWidget,
              Expanded(flex: 48, child: textWidget),
            ],
    );
  }

  /// Wraps Image or Text section with DragTarget & Draggable handle for intuitive drag-and-swap
  Widget _buildDraggableSection({
    required BuildContext context,
    required int slotIndex,
    required String sectionType, // 'image' or 'text'
    required Widget child,
    required bool canEdit,
    required Color accentColor,
    required bool isLight,
  }) {
    if (!canEdit) {
      return child;
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != sectionType,
      onAcceptWithDetails: (details) {
        _toggleSlotOrder(slotIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isHovered
                ? Border.all(color: accentColor, width: 2.2)
                : Border.all(color: Colors.transparent, width: 1.0),
            color: isHovered ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
          ),
          child: Stack(
            children: [
              Positioned.fill(child: child),

              // Drop preview banner when dragging other block over this target
              if (isHovered)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.white : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_vert_rounded, size: 16, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            'Release to Swap Position',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Drag Handle Chip on top-left of the section
              Positioned(
                top: 6,
                left: 6,
                child: Draggable<String>(
                  data: sectionType,
                  feedback: Material(
                    color: Colors.transparent,
                    elevation: 10,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.white : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.drag_indicator_rounded, size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            sectionType == 'image' ? 'Image Section' : 'Text Section',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.25,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.drag_indicator_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                  child: Tooltip(
                    message: 'Drag over other section to swap positions',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.drag_indicator_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              sectionType == 'image' ? 'Image' : 'Text',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  /// Image Content Area (ImageDropzoneWidget)
  Widget _buildImageContent(int index, SlideData slide) {
    final imageKey = index == 0 ? 'custom_image' : 'custom_image_$index';
    final initialPath = _getImagePathForSlot(slide, index);

    return ImageDropzoneWidget(
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
    );
  }

  /// Text Card Area (Editable Title and Body / Paragraph)
  Widget _buildTextCardContent(
    BuildContext context,
    int index,
    SlideData slide,
    bool isLight,
    Color accentColor, {
    bool isCompact = false,
  }) {
    final titleKey = 'card_${index + 1}_title';
    final subtitleKey = 'card_${index + 1}_subtitle';

    final defaultTitle = 'Point ${index + 1}';
    final defaultSubtitle =
        'Add your key insight, clinical workflow step, metric breakdown, or strategic initiative description here.';

    final textDark = isLight ? const Color(0xFF0F172A) : Colors.white;
    final textMuted = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Padding(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title with colored accent line
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: isCompact ? 16 : 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SelectableTextElement(
                  elementKey: titleKey,
                  label: 'Card ${index + 1} Title',
                  selectedElementKey: widget.renderContext.selectedElementKey,
                  onSelectElement: widget.renderContext.onSelectElement,
                  child: Text(
                    slide.getElementText(titleKey, defaultTitle),
                    style: TextStyle(
                      fontSize: slide.getFontSize(titleKey, isCompact ? 16.0 : 20.0),
                      fontWeight: slide.getFontWeight(titleKey, FontWeight.bold),
                      color: textDark,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 10),

          // Subtitle / Body Description
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SelectableTextElement(
                elementKey: subtitleKey,
                label: 'Card ${index + 1} Description',
                selectedElementKey: widget.renderContext.selectedElementKey,
                onSelectElement: widget.renderContext.onSelectElement,
                child: Text(
                  slide.getElementText(subtitleKey, defaultSubtitle),
                  style: TextStyle(
                    fontSize: slide.getFontSize(subtitleKey, isCompact ? 12.5 : 14.5),
                    fontWeight: slide.getFontWeight(subtitleKey, FontWeight.normal),
                    color: textMuted,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
