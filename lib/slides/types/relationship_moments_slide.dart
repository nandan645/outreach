import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "Moments Where Redcliffe Can Move from Transaction to Relationship"
class RelationshipMomentsSlide extends BaseSlide {
  @override
  String get type => 'relationship_moments';

  @override
  String get displayName => 'Transaction to Relationship Moments';

  @override
  Widget build(SlideRenderContext context) {
    return _RelationshipMomentsWidget(renderContext: context);
  }
}

class _RelationshipMomentsWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _RelationshipMomentsWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Color definitions per card theme
    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);

    final defaultAccentColors = [
      const Color(0xFF2563EB),
      const Color(0xFFEF4444),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];

    final defaultSoftBgs = [
      isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E293B),
      isLight ? const Color(0xFFFEF2F2) : const Color(0xFF3B1D1D),
      isLight ? const Color(0xFFECFDF5) : const Color(0xFF132A22),
      isLight ? const Color(0xFFFFFBEB) : const Color(0xFF332A15),
    ];

    final defaultTopIcons = [
      Icons.description_outlined,
      Icons.alarm_rounded,
      Icons.home_outlined,
      Icons.access_time_rounded,
    ];

    final rawCards = (slide.rawContent['cards'] as List?) ?? [];
    final cardThemes = rawCards.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      final numStr = (idx + 1).toString().padLeft(2, '0');
      return {
        "num": numStr,
        "title": item['title']?.toString() ?? '',
        "today_text": item['today_text']?.toString() ?? '',
        "opp_text": item['opp_text']?.toString() ?? '',
        "color": defaultAccentColors[idx % defaultAccentColors.length],
        "bg_soft": defaultSoftBgs[idx % defaultSoftBgs.length],
        "top_icon": defaultTopIcons[idx % defaultTopIcons.length],
        "key_prefix": "card_${idx + 1}",
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Title & Subtitle Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 20),

        // 1. MAIN 4 VERTICAL CARDS GRID
        Expanded(
          flex: 78,
          child: Row(
            children: cardThemes.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final prefix = item['key_prefix'] as String;
              final accentColor = item['color'] as Color;
              final softBg = item['bg_soft'] as Color;
              final topIconData = item['top_icon'] as IconData;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: idx == cardThemes.length - 1 ? 0 : 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Dark Indicator Pill Bar
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
                      const SizedBox(height: 18),

                      // Top Row (Number Circle Badge + Icon Circle Badge)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Number Circle Badge
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: softBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item['num'] as String,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          // Top Icon Circle Badge
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: softBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              topIconData,
                              size: 32,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Card Header Title
                      SelectableTextElement(
                        elementKey: '${prefix}_title',
                        label: 'Card ${idx + 1} Title',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText('${prefix}_title', item['title'] as String),
                          style: TextStyle(
                            color: textDark,
                            fontSize: slide.getFontSize('${prefix}_title', 26.0),
                            fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w700),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // UPPER SECTION: TODAY
                      SelectableTextElement(
                        elementKey: '${prefix}_today_label',
                        label: 'Today Label',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText('${prefix}_today_label', 'TODAY'),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: slide.getFontSize('${prefix}_today_label', 19.0),
                            fontWeight: slide.getFontWeight('${prefix}_today_label', FontWeight.w600),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableTextElement(
                        elementKey: '${prefix}_today_text',
                        label: 'Today Text',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText('${prefix}_today_text', item['today_text'] as String),
                          style: TextStyle(
                            color: textMuted,
                            fontSize: slide.getFontSize('${prefix}_today_text', 21.0),
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Dashed Divider Line
                      CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: _DashedLinePainter(
                          color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF444444),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // LOWER SECTION: OPPORTUNITY
                      SelectableTextElement(
                        elementKey: '${prefix}_opp_label',
                        label: 'Opportunity Label',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText('${prefix}_opp_label', 'OPPORTUNITY'),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: slide.getFontSize('${prefix}_opp_label', 19.0),
                            fontWeight: slide.getFontWeight('${prefix}_opp_label', FontWeight.w600),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: SelectableTextElement(
                          elementKey: '${prefix}_opp_text',
                          label: 'Opportunity Text',
                          selectedElementKey: renderContext.selectedElementKey,
                          onSelectElement: renderContext.onSelectElement,
                          child: Text(
                            slide.getElementText('${prefix}_opp_text', item['opp_text'] as String),
                            style: TextStyle(
                              color: textDark,
                              fontSize: slide.getFontSize('${prefix}_opp_text', 21.0),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),

                      // Bottom Arrow Circle Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: softBg,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 25,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 18),

        // 2. BOTTOM BANNER (2 Side-by-Side Soft Cards)
        Expanded(
          flex: 22,
          child: Row(
            children: [
              // Left Bottom Card: "These are not isolated issues..."
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF5F3FF) : const Color(0xFF261E38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLight ? const Color(0xFFDDD6FE) : const Color(0xFF4C1D95),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Sparkle Circle Icon
                      Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableTextElement(
                              elementKey: 'bot_left_title',
                              label: 'Bottom Left Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText('bot_left_title', 'These are not isolated issues.'),
                                style: TextStyle(
                                  color: const Color(0xFF6D28D9),
                                  fontSize: slide.getFontSize('bot_left_title', 26.0),
                                  fontWeight: slide.getFontWeight('bot_left_title', FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableTextElement(
                              elementKey: 'bot_left_desc',
                              label: 'Bottom Left Subtitle',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText('bot_left_desc', 'They are four expressions of the same missing capability:'),
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                                  fontSize: slide.getFontSize('bot_left_desc', 21.0),
                                  fontWeight: FontWeight.w400,
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

              const SizedBox(width: 16),

              // Right Bottom Card: "INTELLIGENT ENGAGEMENT..."
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFEEF2FF) : const Color(0xFF1E2338),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLight ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Sparkle Outline Icon
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_outlined,
                          size: 32,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableTextElement(
                              elementKey: 'bot_right_title',
                              label: 'Bottom Right Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText('bot_right_title', 'INTELLIGENT ENGAGEMENT'),
                                style: TextStyle(
                                  color: const Color(0xFF4F46E5),
                                  fontSize: slide.getFontSize('bot_right_title', 26.0),
                                  fontWeight: slide.getFontWeight('bot_right_title', FontWeight.w700),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableTextElement(
                              elementKey: 'bot_right_desc',
                              label: 'Bottom Right Subtitle',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText('bot_right_desc', 'Understand. Decide. Act. Follow up. Remember.'),
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                                  fontSize: slide.getFontSize('bot_right_desc', 21.0),
                                  fontWeight: FontWeight.w500,
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

/// Helper custom painter to draw soft horizontal dashed separator line
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final dashWidth = 4.0;
    final dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
