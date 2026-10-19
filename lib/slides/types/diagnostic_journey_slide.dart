import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "The Diagnostic Journey Still Breaks After the Report" breakdown
class DiagnosticJourneySlide extends BaseSlide {
  @override
  String get type => 'diagnostic_journey';

  @override
  String get displayName => 'Diagnostic Journey Breakdown';

  @override
  Widget build(SlideRenderContext context) {
    return _DiagnosticJourneyWidget(renderContext: context);
  }
}

class _DiagnosticJourneyWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _DiagnosticJourneyWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Palette definition
    final purpleAccent = const Color(0xFF6C6CFF);
    final purpleBorder = const Color(0xFF8B8BFF);
    final purpleBg = isLight ? const Color(0xFFF2F2FF) : const Color(0xFF232338);

    final redAccent = const Color(0xFFF05252);
    final redBg = isLight ? const Color(0xFFFFF2F2) : const Color(0xFF332020);

    final greenAccent = const Color(0xFF10B981);
    final greenBg = isLight ? const Color(0xFFEEFAF4) : const Color(0xFF1C332A);

    final cardBg = isLight ? Colors.white : const Color(0xFF1E222A);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333842);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF6B7280) : const Color(0xFFA0A5B1);

    final defaultTopIcons = [
      Icons.search_rounded,
      Icons.calendar_month_rounded,
      Icons.home_rounded,
      Icons.science_rounded,
      Icons.description_rounded,
    ];

    final defaultMidIcons = [
      Icons.lightbulb_outline_rounded,
      Icons.alt_route_rounded,
      Icons.assignment_outlined,
      Icons.notifications_active_outlined,
      Icons.history_rounded,
    ];

    final bottomIcons = [
      Icons.close_rounded,
      Icons.priority_high_rounded,
      Icons.check_rounded,
    ];

    final bottomColors = [
      purpleAccent,
      redAccent,
      greenAccent,
    ];

    // Data for Top Steps from JSON
    final rawTopSteps = (slide.rawContent['top_steps'] as List?) ?? [];
    final topSteps = rawTopSteps.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['description']?.toString() ?? '',
        "icon": defaultTopIcons[idx % defaultTopIcons.length],
        "isRed": item['isRed'] == true,
      };
    }).toList();

    // Data for Middle Missing Layer (Sub-steps) from JSON
    final rawMissingLayer = (slide.rawContent['missing_layer'] as Map?) ?? {};
    final rawMidSteps = (rawMissingLayer['steps'] as List?) ?? [];
    final missingLayerSteps = rawMidSteps.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['description']?.toString() ?? '',
        "icon": defaultMidIcons[idx % defaultMidIcons.length],
      };
    }).toList();

    // Data for Bottom Feature Cards from JSON
    final rawBottomCards = (slide.rawContent['bottom_cards'] as List?) ?? [];
    final bottomCards = rawBottomCards.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      final List bulletsList = (item['bullets'] as List?) ?? [];
      return {
        "key_prefix": "bot_$idx",
        "title": item['title']?.toString() ?? '',
        "icon": bottomIcons[idx % bottomIcons.length],
        "color": bottomColors[idx % bottomColors.length],
        "bullets": bulletsList.map((b) => b.toString()).toList(),
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Title Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 12),

        // 1. TOP ROW: 5 Steps with Loop Connection
        Expanded(
          flex: 25,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Dashed Loop Connection Line from Card 5 down and left
              Positioned.fill(
                child: CustomPaint(
                  painter: _TopToMiddleLoopPainter(
                    color: purpleBorder,
                    isLight: isLight,
                  ),
                ),
              ),

              Row(
                children: List.generate(topSteps.length, (idx) {
                  final item = topSteps[idx];
                  final isRed = item['isRed'] == true;
                  final stepIcon = item['icon'] as IconData;

                  return Expanded(
                    child: Row(
                      children: [
                        // Card Container
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRed ? redAccent.withValues(alpha: 0.5) : purpleBorder,
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon Circle
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isRed ? redBg : purpleBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    stepIcon,
                                    size: 26,
                                    color: isRed ? redAccent : purpleAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Text Column
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableTextElement(
                                        elementKey: 'top_title_$idx',
                                        label: 'Step ${idx + 1} Title',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('top_title_$idx', item['title'] as String),
                                          style: TextStyle(
                                            color: isRed ? redAccent : purpleAccent,
                                            fontSize: slide.getFontSize('top_title_$idx', 18.0),
                                            fontWeight: slide.getFontWeight('top_title_$idx', FontWeight.w800),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      SelectableTextElement(
                                        elementKey: 'top_desc_$idx',
                                        label: 'Step ${idx + 1} Description',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('top_desc_$idx', item['desc'] as String),
                                          style: TextStyle(
                                            color: textMuted,
                                            fontSize: slide.getFontSize('top_desc_$idx', 15.0),
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Connector Arrow between cards
                        if (idx < topSteps.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: CustomPaint(
                              size: const Size(22, 18),
                              painter: _DashedArrowPainter(color: purpleBorder),
                            ),
                          )
                        else
                          const SizedBox(width: 20),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 44),

        // 2. MIDDLE ROW: "THE MISSING LAYER" Banner + "REPEAT / PREVENT / MANAGE" Card
        Expanded(
          flex: 29,
          child: Row(
            children: [
              // Left Section: Missing Layer Banner (Indented from left to fit arrow)
              Expanded(
                flex: 78,
                child: Container(
                  margin: const EdgeInsets.only(left: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: redBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: redAccent.withValues(alpha: 0.25), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // Left Label: THE MISSING LAYER
                      SizedBox(
                        width: 130,
                        child: SelectableTextElement(
                          elementKey: 'mid_label',
                          label: 'Banner Label',
                          selectedElementKey: renderContext.selectedElementKey,
                          onSelectElement: renderContext.onSelectElement,
                          child: Text(
                            slide.getElementText('mid_label', 'THE\nMISSING\nLAYER'),
                            style: TextStyle(
                              color: redAccent,
                              fontSize: slide.getFontSize('mid_label', 18.0),
                              fontWeight: slide.getFontWeight('mid_label', FontWeight.w900),
                              height: 1.2,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 5 Sub-steps
                      Expanded(
                        child: Row(
                          children: List.generate(missingLayerSteps.length, (idx) {
                            final item = missingLayerSteps[idx];
                            final iconData = item['icon'] as IconData;

                            return Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Icon Circle
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: redAccent.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            iconData,
                                            size: 24,
                                            color: redAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Title
                                        SelectableTextElement(
                                          elementKey: 'mid_title_$idx',
                                          label: 'Substep ${idx + 1} Title',
                                          selectedElementKey: renderContext.selectedElementKey,
                                          onSelectElement: renderContext.onSelectElement,
                                          child: Text(
                                            slide.getElementText('mid_title_$idx', item['title'] as String),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: redAccent,
                                              fontSize: slide.getFontSize('mid_title_$idx', 16.0),
                                              fontWeight: slide.getFontWeight('mid_title_$idx', FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        // Subtext
                                        SelectableTextElement(
                                          elementKey: 'mid_desc_$idx',
                                          label: 'Substep ${idx + 1} Description',
                                          selectedElementKey: renderContext.selectedElementKey,
                                          onSelectElement: renderContext.onSelectElement,
                                          child: Text(
                                            slide.getElementText('mid_desc_$idx', item['desc'] as String),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: textMuted,
                                              fontSize: slide.getFontSize('mid_desc_$idx', 14.0),
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (idx < missingLayerSteps.length - 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: CustomPaint(
                                        size: const Size(18, 14),
                                        painter: _DashedArrowPainter(color: redAccent),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dashed Green Arrow connecting Middle Banner to Right Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomPaint(
                  size: const Size(26, 20),
                  painter: _DashedArrowPainter(color: greenAccent),
                ),
              ),

              // Right Section: REPEAT / PREVENT / MANAGE Card
              Expanded(
                flex: 22,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: greenBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: greenAccent.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: greenAccent.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          size: 26,
                          color: greenAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableTextElement(
                        elementKey: 'right_mid_title',
                        label: 'Goal Header',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText('right_mid_title', 'REPEAT / PREVENT /\nMANAGE'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: greenAccent,
                            fontSize: slide.getFontSize('right_mid_title', 17.5),
                            fontWeight: slide.getFontWeight('right_mid_title', FontWeight.w800),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SelectableTextElement(
                        elementKey: 'right_mid_desc',
                        label: 'Goal Subtitle',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText('right_mid_desc', 'Better outcomes\nover time'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: slide.getFontSize('right_mid_desc', 14.5),
                            height: 1.2,
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

        const SizedBox(height: 16),

        // 3. BOTTOM ROW: 3 Feature Cards (TODAY, THE GAP, THE OPPORTUNITY)
        Expanded(
          flex: 46,
          child: Row(
            children: bottomCards.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final prefix = item['key_prefix'] as String;
              final cardColor = item['color'] as Color;
              final iconData = item['icon'] as IconData;
              final bullets = item['bullets'] as List<String>;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: idx == bottomCards.length - 1 ? 0 : 14),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cardBorder, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row (Icon + Title)
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: cardColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SelectableTextElement(
                            elementKey: '${prefix}_title',
                            label: 'Card ${idx + 1} Header',
                            selectedElementKey: renderContext.selectedElementKey,
                            onSelectElement: renderContext.onSelectElement,
                            child: Text(
                              slide.getElementText('${prefix}_title', item['title'] as String),
                              style: TextStyle(
                                color: cardColor,
                                fontSize: slide.getFontSize('${prefix}_title', 26.0),
                                fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w900),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Bullet Points List
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(bullets.length, (bIdx) {
                            final bulletKey = '${prefix}_bullet_$bIdx';

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '•  ',
                                  style: TextStyle(
                                    color: textDark.withValues(alpha: 0.8),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: SelectableTextElement(
                                    elementKey: bulletKey,
                                    label: 'Bullet ${bIdx + 1}',
                                    selectedElementKey: renderContext.selectedElementKey,
                                    onSelectElement: renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText(bulletKey, bullets[bIdx]),
                                      style: TextStyle(
                                        color: isLight ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                                        fontSize: slide.getFontSize(bulletKey, 19.5),
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Custom painter to draw horizontal dashed line with an arrowhead '-- >'
class _DashedArrowPainter extends CustomPainter {
  final Color color;

  _DashedArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dashWidth = 4.0;
    final dashSpace = 3.0;
    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width - 4) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(0, size.width - 4), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Arrowhead
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width - 6, y - 4)
      ..lineTo(size.width, y)
      ..lineTo(size.width - 6, y + 4);

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _DashedArrowPainter oldDelegate) => oldDelegate.color != color;
}

/// Custom painter for the loop connector coming out of Card 5 down, left, down, and right into THE MISSING LAYER card
class _TopToMiddleLoopPainter extends CustomPainter {
  final Color color;
  final bool isLight;

  _TopToMiddleLoopPainter({required this.color, required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Solid circle dot at the right of Card 5
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final card5RightX = size.width - 15;
    final topY = size.height * 0.5;
    final loopRightX = size.width + 16;
    final gapY = size.height + 22;
    final farLeftX = 10.0;
    final middleRowMidY = size.height + 44 + 85.0;
    final targetBannerX = 36.0;

    canvas.drawCircle(Offset(card5RightX, topY), 5.0, dotPaint);

    final path = Path();
    // 1. Move right from Card 5
    path.moveTo(card5RightX + 5.0, topY);
    path.lineTo(loopRightX - 10, topY);
    // Turn 1: Down
    path.arcToPoint(Offset(loopRightX, topY + 10), radius: const Radius.circular(10));
    path.lineTo(loopRightX, gapY - 10);
    // Turn 2: Left across the gap
    path.arcToPoint(Offset(loopRightX - 10, gapY), radius: const Radius.circular(10));
    path.lineTo(farLeftX + 12, gapY);
    // Turn 3: Down on the left (smooth counter-clockwise 90° curve)
    path.arcToPoint(Offset(farLeftX, gapY + 12), radius: const Radius.circular(12), clockwise: false);
    path.lineTo(farLeftX, middleRowMidY - 12);
    // Turn 4: Right into THE MISSING LAYER card (smooth counter-clockwise 90° curve)
    path.arcToPoint(Offset(farLeftX + 12, middleRowMidY), radius: const Radius.circular(12), clockwise: false);
    path.lineTo(targetBannerX, middleRowMidY);

    // Draw bold dashed path
    final dashWidth = 6.0;
    final dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = (distance + dashWidth > metric.length) ? metric.length - distance : dashWidth;
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dashWidth + dashSpace;
      }
    }

    // Arrowhead pointing RIGHT into THE MISSING LAYER card
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowPath = Path()
      ..moveTo(targetBannerX - 8, middleRowMidY - 6)
      ..lineTo(targetBannerX, middleRowMidY)
      ..lineTo(targetBannerX - 8, middleRowMidY + 6);

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _TopToMiddleLoopPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isLight != isLight;
}
