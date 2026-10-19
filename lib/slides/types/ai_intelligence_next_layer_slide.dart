import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "Redcliffe Already Has Intelligence. The Opportunity Is the Next Layer."
class AiIntelligenceNextLayerSlide extends BaseSlide {
  @override
  String get type => 'ai_intelligence_next_layer';

  @override
  String get displayName => 'AI Intelligence Next Layer';

  @override
  Widget build(SlideRenderContext context) {
    return _AiIntelligenceNextLayerWidget(renderContext: context);
  }
}

class _AiIntelligenceNextLayerWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _AiIntelligenceNextLayerWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Theme colors
    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);

    final defaultExistIcons = [
      Icons.science_rounded,
      Icons.coronavirus_rounded,
      Icons.bar_chart_rounded,
      Icons.face_retouching_natural_rounded,
    ];

    final defaultStepIcons = [
      Icons.chat_bubble_rounded,
      Icons.adjust_rounded,
      Icons.play_arrow_rounded,
      Icons.touch_app_rounded,
      Icons.notifications_active_rounded,
      Icons.psychology_rounded,
      Icons.sync_rounded,
    ];

    // Left Card Data from JSON (Existing AI Features)
    final rawExistFeatures = (slide.rawContent['existing_ai_features'] as List?) ?? [];
    final existingAiFeatures = rawExistFeatures.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "sub": item['sub']?.toString() ?? '',
        "desc": item['desc']?.toString() ?? '',
        "icon": defaultExistIcons[idx % defaultExistIcons.length],
        "prefix": "exist_${idx + 1}",
      };
    }).toList();

    // Right Card Data from JSON (Journey Steps)
    final rawJourneySteps = (slide.rawContent['journey_steps'] as List?) ?? [];
    final journeySteps = rawJourneySteps.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['desc']?.toString() ?? '',
        "icon": defaultStepIcons[idx % defaultStepIcons.length],
        "prefix": "step_${idx + 1}",
      };
    }).toList();

    final blueAccent = const Color(0xFF2563EB);
    final blueBgSoft = isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E293B);
    final redAccent = const Color(0xFFEF4444);
    final redBgSoft = isLight ? const Color(0xFFFEF2F2) : const Color(0xFF3B1D1D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Title Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 18),

        // 2 LARGE EQUAL-WIDTH SIDE-BY-SIDE CARDS
        Expanded(
          child: Row(
            children: [
              // ==================== LEFT CARD: REDCLIFFE'S EXISTING AI ====================
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cardBorder, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Indicator Pill Bar
                      Center(
                        child: Container(
                          width: 56,
                          height: 5.5,
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFF1F2937) : Colors.white70,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Top Blue Header Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: blueBgSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: SelectableTextElement(
                          elementKey: 'left_header_title',
                          label: 'Left Header Title',
                          selectedElementKey: renderContext.selectedElementKey,
                          onSelectElement: renderContext.onSelectElement,
                          child: Text(
                            slide.getElementText('left_header_title', "REDCLIFFE'S EXISTING AI"),
                            style: TextStyle(
                              color: blueAccent,
                              fontSize: slide.getFontSize('left_header_title', 21.0),
                              fontWeight: slide.getFontWeight('left_header_title', FontWeight.w800),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4 Feature Rows
                      Expanded(
                        child: Column(
                          children: [
                            for (int idx = 0; idx < existingAiFeatures.length; idx++) ...[
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Col 1: Icon Circle Box
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: blueBgSoft,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        existingAiFeatures[idx]['icon'] as IconData,
                                        size: 32,
                                        color: blueAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Col 2: Feature Title + Subtitle
                                    SizedBox(
                                      width: 185,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SelectableTextElement(
                                            elementKey: '${existingAiFeatures[idx]['prefix']}_title',
                                            label: 'Feature Title',
                                            selectedElementKey: renderContext.selectedElementKey,
                                            onSelectElement: renderContext.onSelectElement,
                                            child: Text(
                                              slide.getElementText('${existingAiFeatures[idx]['prefix']}_title', existingAiFeatures[idx]['title'] as String),
                                              style: TextStyle(
                                                color: blueAccent,
                                                fontSize: slide.getFontSize('${existingAiFeatures[idx]['prefix']}_title', 23.0),
                                                fontWeight: slide.getFontWeight('${existingAiFeatures[idx]['prefix']}_title', FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          SelectableTextElement(
                                            elementKey: '${existingAiFeatures[idx]['prefix']}_sub',
                                            label: 'Feature Subtitle',
                                            selectedElementKey: renderContext.selectedElementKey,
                                            onSelectElement: renderContext.onSelectElement,
                                            child: Text(
                                              slide.getElementText('${existingAiFeatures[idx]['prefix']}_sub', existingAiFeatures[idx]['sub'] as String),
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: slide.getFontSize('${existingAiFeatures[idx]['prefix']}_sub', 17.5),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Col 2.5: Vertical Separator Line
                                    Container(
                                      height: 54,
                                      width: 1.2,
                                      color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333),
                                    ),
                                    const SizedBox(width: 16),

                                    // Col 3: Detailed Description
                                    Expanded(
                                      child: SelectableTextElement(
                                        elementKey: '${existingAiFeatures[idx]['prefix']}_desc',
                                        label: 'Feature Description',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('${existingAiFeatures[idx]['prefix']}_desc', existingAiFeatures[idx]['desc'] as String),
                                          style: TextStyle(
                                            color: textDark,
                                            fontSize: slide.getFontSize('${existingAiFeatures[idx]['prefix']}_desc', 19.0),
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Perfectly centered Horizontal Divider Line between rows
                              if (idx < existingAiFeatures.length - 1)
                                Container(
                                  width: double.infinity,
                                  height: 1.2,
                                  color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // ==================== RIGHT CARD: WHAT HAPPENS ACROSS THE JOURNEY? ====================
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cardBorder, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Indicator Pill Bar
                      Center(
                        child: Container(
                          width: 56,
                          height: 5.5,
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFF1F2937) : Colors.white70,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Top Red Header Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: redBgSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: SelectableTextElement(
                          elementKey: 'right_header_title',
                          label: 'Right Header Title',
                          selectedElementKey: renderContext.selectedElementKey,
                          onSelectElement: renderContext.onSelectElement,
                          child: Text(
                            slide.getElementText('right_header_title', "WHAT HAPPENS ACROSS THE JOURNEY?"),
                            style: TextStyle(
                              color: redAccent,
                              fontSize: slide.getFontSize('right_header_title', 21.0),
                              fontWeight: slide.getFontWeight('right_header_title', FontWeight.w800),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Main Content (2 Horizontal Sections: 7 Timeline Steps on left + THE GAP Box on right)
                      Expanded(
                        child: Row(
                          children: [
                            // Left Section: 7 Vertical Timeline Steps
                            Expanded(
                              flex: 62,
                              child: Stack(
                                children: [
                                  // Vertical Dashed Timeline Line connecting the circle nodes
                                  Positioned(
                                    left: 23,
                                    top: 20,
                                    bottom: 20,
                                    child: CustomPaint(
                                      size: const Size(2, double.infinity),
                                      painter: _VerticalDashedLinePainter(
                                        color: redAccent.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),

                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: journeySteps.asMap().entries.map((entry) {
                                      final item = entry.value;
                                      final prefix = item['prefix'] as String;
                                      final iconData = item['icon'] as IconData;

                                      return Row(
                                        children: [
                                          // Circle Icon Node
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: redBgSoft,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: redAccent.withValues(alpha: 0.3),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Icon(
                                              iconData,
                                              size: 24,
                                              color: redAccent,
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Title & Subtitle Column
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_title',
                                                  label: 'Step Title',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                                    style: TextStyle(
                                                      color: textDark,
                                                      fontSize: slide.getFontSize('${prefix}_title', 18.5),
                                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.bold),
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_desc',
                                                  label: 'Step Description',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_desc', item['desc'] as String),
                                                    style: TextStyle(
                                                      color: textMuted,
                                                      fontSize: slide.getFontSize('${prefix}_desc', 16.0),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Right Section: THE GAP Box
                            Expanded(
                              flex: 38,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                decoration: BoxDecoration(
                                  color: isLight ? const Color(0xFFFFF5F5) : const Color(0xFF2C1919),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isLight ? const Color(0xFFFED7D7) : const Color(0xFF5A2323),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Sparkle Circle Badge
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: redAccent.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome,
                                        size: 32,
                                        color: redAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Header Title
                                    SelectableTextElement(
                                      elementKey: 'gap_title',
                                      label: 'Gap Box Title',
                                      selectedElementKey: renderContext.selectedElementKey,
                                      onSelectElement: renderContext.onSelectElement,
                                      child: Text(
                                        slide.getElementText('gap_title', 'THE GAP'),
                                        style: TextStyle(
                                          color: redAccent,
                                          fontSize: slide.getFontSize('gap_title', 24.0),
                                          fontWeight: slide.getFontWeight('gap_title', FontWeight.w900),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Body Text Line 1
                                    SelectableTextElement(
                                      elementKey: 'gap_text_1',
                                      label: 'Gap Body Line 1',
                                      selectedElementKey: renderContext.selectedElementKey,
                                      onSelectElement: renderContext.onSelectElement,
                                      child: Text(
                                        slide.getElementText('gap_text_1', 'AI can generate intelligence.'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textDark,
                                          fontSize: slide.getFontSize('gap_text_1', 18.5),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Body Text Line 2
                                    SelectableTextElement(
                                      elementKey: 'gap_text_2',
                                      label: 'Gap Body Line 2',
                                      selectedElementKey: renderContext.selectedElementKey,
                                      onSelectElement: renderContext.onSelectElement,
                                      child: Text(
                                        slide.getElementText('gap_text_2', 'The next opportunity is turning intelligence into action.'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: slide.getFontSize('gap_text_2', 18.0),
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
      ],
    );
  }
}

/// Helper custom painter to draw vertical dashed line connecting timeline nodes
class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;

  _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final dashHeight = 4.0;
    final dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) => oldDelegate.color != color;
}
