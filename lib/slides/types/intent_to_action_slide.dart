import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "From Intent to Action."
class IntentToActionSlide extends BaseSlide {
  @override
  String get type => 'intent_to_action';

  @override
  String get displayName => 'From Intent to Action';

  @override
  Widget build(SlideRenderContext context) {
    return _IntentToActionWidget(renderContext: context);
  }
}

class _IntentToActionWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _IntentToActionWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final textDark = isLight ? const Color(0xFF111827) : Colors.white;

    final purpleAccent = const Color(0xFF6D28D9);

    final defaultStepIcons = [
      Icons.chat_bubble_outline_rounded,
      Icons.track_changes_rounded,
      Icons.event_available_outlined,
      Icons.insights_rounded,
    ];

    final flowStepIcons = [
      Icons.lightbulb_outline_rounded,
      Icons.psychology_outlined,
      Icons.track_changes_rounded,
      Icons.calendar_today_rounded,
      Icons.sports_rounded,
      Icons.trending_up_rounded,
      Icons.arrow_forward_rounded,
    ];

    // Mockups list (4 mockups)
    final rawMockups = (slide.rawContent['mockups'] as List?) ?? [];
    final mockups = (rawMockups.isNotEmpty)
        ? rawMockups.asMap().entries.map((entry) {
            final idx = entry.key;
            final Map item = entry.value is Map ? entry.value as Map : {};
            return {
              "image_key": item['image_key']?.toString() ?? 'mobile_image_$idx',
              "label": item['label']?.toString() ?? 'Mockup ${idx + 1}',
            };
          }).toList()
        : List.generate(4, (idx) => {
            "image_key": 'mobile_image_$idx',
            "label": 'Mockup ${idx + 1}',
          });

    // Guided Journey data from JSON
    final rawGuided = (slide.rawContent['guided_journey'] as Map?) ?? {};
    final guidedTitle = rawGuided['title']?.toString() ?? '';
    final rawGuidedSteps = (rawGuided['steps'] as List?) ?? [];
    final guidedSteps = rawGuidedSteps.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "step": item['step']?.toString() ?? '',
        "title": item['title']?.toString() ?? '',
        "subtitle": item['subtitle']?.toString() ?? '',
        "icon": defaultStepIcons[idx % defaultStepIcons.length],
        "prefix": "gj_${idx + 1}",
      };
    }).toList();

    // Bottom Banner data from JSON
    final rawBanner = (slide.rawContent['bottom_banner'] as Map?) ?? {};
    final bannerTitle = rawBanner['title']?.toString() ?? '';
    final rawFlowSteps = (rawBanner['flow_steps'] as List?) ?? [];
    final flowSteps = rawFlowSteps.map((s) => s.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Title Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 14),

        // 1. MAIN SECTION: 4 MOCKUPS (LEFT 72%) + GUIDED JOURNEY CARD (RIGHT 28%)
        Expanded(
          flex: 80,
          child: Row(
            children: [
              // LEFT SIDE: 4 MOBILE MOCKUPS
              Expanded(
                flex: 72,
                child: Row(
                  children: mockups.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final imageKey = item['image_key'] as String;

                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                            right: idx == mockups.length - 1 ? 0 : 10),
                        child: ImageDropzoneWidget(
                          slideId: slide.id,
                          imageKey: imageKey,
                          companyName: renderContext.companyName,
                          label: 'Mockup ${idx + 1}',
                          formatHint: '9:18',
                          height: double.infinity,
                          isMobileFrame: true,
                          initialImagePath: slide.getImagePath(imageKey),
                          folderPath: renderContext.folderPath,
                          onImageSelected: (path) {
                            if (renderContext.onImageChanged != null) {
                              renderContext.onImageChanged!(imageKey, path);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 14),

              // RIGHT SIDE: GUIDED JOURNEY CARD
              Expanded(
                flex: 28,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFEFF2FD)
                        : const Color(0xFF1E1B2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFE2E7FA)
                          : const Color(0xFF352F4E),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Card Title Header
                      SelectableTextElement(
                        elementKey: 'guided_journey_header',
                        label: 'Guided Journey Header',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText(
                              'guided_journey_header', guidedTitle),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            fontSize: slide.getFontSize(
                                'guided_journey_header', 21.0),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Steps Stack with continuous dashed line connecting all cards
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Continuous vertical dashed line from top card to bottom card
                            Positioned(
                              top: 38,
                              bottom: 38,
                              width: 4,
                              child: CustomPaint(
                                painter: _VerticalDashedLinePainter(
                                  color: const Color(0xFF4338CA),
                                  dashHeight: 4.5,
                                  dashSpace: 4.5,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),

                            // 2. Foreground 4 step cards
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: guidedSteps.asMap().entries.map((gEntry) {
                                final gIdx = gEntry.key;
                                final gItem = gEntry.value;
                                final prefix = gItem['prefix'] as String;
                                final iconData = gItem['icon'] as IconData;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 22),
                                  decoration: BoxDecoration(
                                    color: isLight
                                        ? Colors.white
                                        : const Color(0xFF28233C),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isLight
                                          ? const Color(0xFFE2E8F0)
                                          : const Color(0xFF3B3556),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isLight ? 0.06 : 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // 1. Number Circle Badge
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: isLight
                                              ? const Color(0xFFEDEFFF)
                                              : const Color(0xFF322C4D),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          gItem['step'] as String,
                                          style: const TextStyle(
                                            color: Color(0xFF4338CA),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // 2. Title & Subtitle Column
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SelectableTextElement(
                                              elementKey: '${prefix}_title',
                                              label: 'Step ${gIdx + 1} Title',
                                              selectedElementKey:
                                                  renderContext.selectedElementKey,
                                              onSelectElement:
                                                  renderContext.onSelectElement,
                                              child: Text(
                                                slide.getElementText(
                                                    '${prefix}_title',
                                                    gItem['title'] as String),
                                                style: TextStyle(
                                                  color: isLight
                                                      ? const Color(0xFF0F172A)
                                                      : Colors.white,
                                                  fontSize: slide.getFontSize(
                                                      '${prefix}_title', 18.0),
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            SelectableTextElement(
                                              elementKey: '${prefix}_sub',
                                              label: 'Step ${gIdx + 1} Subtitle',
                                              selectedElementKey:
                                                  renderContext.selectedElementKey,
                                              onSelectElement:
                                                  renderContext.onSelectElement,
                                              child: Text(
                                                slide.getElementText(
                                                    '${prefix}_sub',
                                                    gItem['subtitle'] as String),
                                                style: TextStyle(
                                                  color: isLight
                                                      ? const Color(0xFF475569)
                                                      : const Color(0xFF94A3B8),
                                                  fontSize: slide.getFontSize(
                                                      '${prefix}_sub', 14.5),
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.25,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // 3. Right Icon
                                      Icon(
                                        iconData,
                                        size: 42,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. BOTTOM CONNECTIVITY BANNER
        Expanded(
          flex: 20,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFAFAFA) : const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF2E333D),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Left Part: Sparkle Icon + Title
                Expanded(
                  flex: 36,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: purpleAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 28,
                          color: purpleAccent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SelectableTextElement(
                          elementKey: 'bottom_banner_text',
                          label: 'Bottom Banner Text',
                          selectedElementKey: renderContext.selectedElementKey,
                          onSelectElement: renderContext.onSelectElement,
                          child: Text(
                            slide.getElementText(
                                'bottom_banner_text', bannerTitle),
                            style: TextStyle(
                              color: textDark,
                              fontSize: slide.getFontSize(
                                  'bottom_banner_text', 19.0),
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Separator Line
                Container(
                  width: 1.5,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: isLight
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFF333333),
                ),

                // Right Part: 7 Flow Steps with Arrows
                Expanded(
                  flex: 64,
                  child: Row(
                    children: flowSteps.asMap().entries.map((fEntry) {
                      final fIdx = fEntry.key;
                      final stepName = fEntry.value;
                      final isLast = fIdx == flowSteps.length - 1;
                      final iconData =
                          flowStepIcons[fIdx % flowStepIcons.length];

                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isLast
                                          ? const Color(0xFF2563EB)
                                          : (isLight
                                              ? const Color(0xFFEFF6FF)
                                              : const Color(0xFF1E293B)),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      iconData,
                                      size: 22,
                                      color: isLast
                                          ? Colors.white
                                          : const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  SelectableTextElement(
                                    elementKey: 'bottom_step_${fIdx + 1}',
                                    label: 'Step ${fIdx + 1}',
                                    selectedElementKey:
                                        renderContext.selectedElementKey,
                                    onSelectElement:
                                        renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText(
                                          'bottom_step_${fIdx + 1}', stepName),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isLast ? const Color(0xFF2563EB) : textDark,
                                        fontSize: slide.getFontSize(
                                            'bottom_step_${fIdx + 1}', 15.0),
                                        fontWeight: isLast
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: isLight
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper painter for drawing dashed vertical connector lines
class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashSpace;
  final double strokeWidth;

  _VerticalDashedLinePainter({
    required this.color,
    this.dashHeight = 3.5,
    this.dashSpace = 3.5,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startY = 0;
    final x = size.width / 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashHeight != dashHeight ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.strokeWidth != strokeWidth;
}
