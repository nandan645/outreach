import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "One Diagnostic. One Patient. One Continuous Journey."
class ContinuousPatientJourneySlide extends BaseSlide {
  @override
  String get type => 'continuous_patient_journey';

  @override
  String get displayName => 'Continuous Patient Journey';

  @override
  Widget build(SlideRenderContext context) {
    return _ContinuousPatientJourneyWidget(renderContext: context);
  }
}

class _ContinuousPatientJourneyWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _ContinuousPatientJourneyWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Theme colors
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);

    final defaultHmIcons = [
      Icons.science_rounded,
      Icons.favorite_rounded,
      Icons.description_outlined,
      Icons.person_outline_rounded,
    ];

    final defaultResIcons = [
      Icons.person_pin_rounded,
      Icons.fact_check_rounded,
      Icons.timer_rounded,
      Icons.monitor_heart_rounded,
    ];

    // Section 2: HealthMem Grid Items from JSON
    final rawHmItems = ((slide.rawContent['healthmem'] as Map?)?['items'] as List?) ?? [];
    final healthMemGrid = rawHmItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "icon": defaultHmIcons[idx % defaultHmIcons.length],
        "prefix": "hm_${idx + 1}",
      };
    }).toList();

    // Section 3: The Result Vertical Cards from JSON
    final rawResCards = ((slide.rawContent['results'] as Map?)?['cards'] as List?) ?? [];
    final resultCards = rawResCards.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['description']?.toString() ?? '',
        "icon": defaultResIcons[idx % defaultResIcons.length],
        "prefix": "res_${idx + 1}",
      };
    }).toList();

    final purpleAccent = const Color(0xFF6366F1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Header Title & Subtitle
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 14),

        // MAIN CONTENT ROW (3 Columns + 2 Arrow Connectors)
        Expanded(
          child: Row(
            children: [
              // ==================== 1. SECTION 1 (LEFT): 2 MOBILE MOCKUPS ====================
              Expanded(
                flex: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: ImageDropzoneWidget(
                        slideId: slide.id,
                        imageKey: 'mobile_image_0',
                        companyName: renderContext.companyName,
                        label: 'Mockup 1',
                        formatHint: '9:18',
                        height: double.infinity,
                        isMobileFrame: true,
                        initialImagePath: slide.getImagePath('mobile_image_0').isNotEmpty
                            ? slide.getImagePath('mobile_image_0')
                            : 'assets/presets/mobile_mockup/chat_screen_1.png',
                        folderPath: renderContext.folderPath,
                        onImageSelected: (path) {
                          if (renderContext.onImageChanged != null) {
                            renderContext.onImageChanged!('mobile_image_0', path);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ImageDropzoneWidget(
                        slideId: slide.id,
                        imageKey: 'mobile_image_1',
                        companyName: renderContext.companyName,
                        label: 'Mockup 2',
                        formatHint: '9:18',
                        height: double.infinity,
                        isMobileFrame: true,
                        initialImagePath: slide.getImagePath('mobile_image_1').isNotEmpty
                            ? slide.getImagePath('mobile_image_1')
                            : 'assets/presets/mobile_mockup/chat_screen_2.png',
                        folderPath: renderContext.folderPath,
                        onImageSelected: (path) {
                          if (renderContext.onImageChanged != null) {
                            renderContext.onImageChanged!('mobile_image_1', path);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Connector 1 (<---->)
              SizedBox(
                width: 58,
                child: CustomPaint(
                  size: const Size(58, 20),
                  painter: _DoubleEndedDashedArrowPainter(
                    color: isLight ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                  ),
                ),
              ),

              // ==================== 2. SECTION 2 (MIDDLE): HealthMem ====================
              Expanded(
                flex: 21,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Title: HealthMem
                    SelectableTextElement(
                      elementKey: 'healthmem_title',
                      label: 'HealthMem Title',
                      selectedElementKey: renderContext.selectedElementKey,
                      onSelectElement: renderContext.onSelectElement,
                      child: Text(
                        'HealthMem',
                        style: TextStyle(
                          color: textDark,
                          fontSize: slide.getFontSize('healthmem_title', 26.0),
                          fontWeight: slide.getFontWeight('healthmem_title', FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableTextElement(
                      elementKey: 'healthmem_sub',
                      label: 'HealthMem Subtitle',
                      selectedElementKey: renderContext.selectedElementKey,
                      onSelectElement: renderContext.onSelectElement,
                      child: Text(
                        slide.getElementText('healthmem_sub', 'Longitudinal patient context\nacross all interactions'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: slide.getFontSize('healthmem_sub', 15.5),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2x2 Grid Container (or odd last item full width)
                    Builder(
                      builder: (context) {
                        Widget buildHealthMemCard(Map item) {
                          final prefix = item['prefix'] as String;
                          final iconData = item['icon'] as IconData;

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFF5F3FF) : const Color(0xFF272338),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  iconData,
                                  size: 28,
                                  color: purpleAccent,
                                ),
                                const SizedBox(height: 6),
                                SelectableTextElement(
                                  elementKey: '${prefix}_title',
                                  label: 'Grid Item Title',
                                  selectedElementKey: renderContext.selectedElementKey,
                                  onSelectElement: renderContext.onSelectElement,
                                  child: Text(
                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: textDark,
                                      fontSize: slide.getFontSize('${prefix}_title', 15.0),
                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final List<Widget> healthMemRows = [];
                        for (int i = 0; i < healthMemGrid.length; i += 2) {
                          if (i + 1 < healthMemGrid.length) {
                            healthMemRows.add(
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: buildHealthMemCard(healthMemGrid[i])),
                                    const SizedBox(width: 10),
                                    Expanded(child: buildHealthMemCard(healthMemGrid[i + 1])),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Odd number of items: last item takes full width
                            healthMemRows.add(
                              Row(
                                children: [
                                  Expanded(child: buildHealthMemCard(healthMemGrid[i])),
                                ],
                              ),
                            );
                          }
                          if (i + 2 < healthMemGrid.length) {
                            healthMemRows.add(const SizedBox(height: 10));
                          }
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E232A),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isLight ? const Color(0xFFEEF2FF) : const Color(0xFF333A48),
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: healthMemRows,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Arrow Connector 2 (<---->)
              SizedBox(
                width: 58,
                child: CustomPaint(
                  size: const Size(58, 20),
                  painter: _DoubleEndedDashedArrowPainter(
                    color: isLight ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                  ),
                ),
              ),

              // ==================== 3. SECTION 3 (RIGHT): The Result ====================
              Expanded(
                flex: 25,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLight
                          ? [const Color(0xFFE2F5FC), const Color(0xFFEEFBFC)]
                          : [const Color(0xFF1B2C36), const Color(0xFF17333B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isLight ? const Color(0xFFBAE6FD) : const Color(0xFF1E4E5E),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Sparkle Icon + "The Result"
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 32,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 10),
                          SelectableTextElement(
                            elementKey: 'result_header_title',
                            label: 'Result Header Title',
                            selectedElementKey: renderContext.selectedElementKey,
                            onSelectElement: renderContext.onSelectElement,
                            child: Text(
                              'The Result',
                              style: TextStyle(
                                color: isLight ? const Color(0xFF0F2942) : Colors.white,
                                fontSize: slide.getFontSize('result_header_title', 26.0),
                                fontWeight: slide.getFontWeight('result_header_title', FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 4 Stacked White Feature Cards (Equal Increased Height with 18px Gaps)
                      Expanded(
                        child: Column(
                          children: resultCards.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final prefix = item['prefix'] as String;
                            final iconData = item['icon'] as IconData;

                            return Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isLight ? Colors.white : const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(20),
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
                                          // Left Rounded Square Icon Badge
                                          Container(
                                            width: 54,
                                            height: 54,
                                            decoration: BoxDecoration(
                                              color: isLight ? const Color(0xFFE0F7F6) : const Color(0xFF133834),
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            child: Icon(
                                              iconData,
                                              size: 28,
                                              color: const Color(0xFF00B4B4),
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Right Title + Description
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_title',
                                                  label: 'Result Title',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                                    softWrap: true,
                                                    style: TextStyle(
                                                      color: textDark,
                                                      fontSize: slide.getFontSize('${prefix}_title', 17.5),
                                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w800),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_desc',
                                                  label: 'Result Description',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_desc', item['desc'] as String),
                                                    softWrap: true,
                                                    style: TextStyle(
                                                      color: isLight ? const Color(0xFF475569) : const Color(0xFF9CA3AF),
                                                      fontSize: slide.getFontSize('${prefix}_desc', 14.5),
                                                      fontWeight: FontWeight.w500,
                                                      height: 1.25,
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
                                  if (idx < resultCards.length - 1)
                                    const SizedBox(height: 18),
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
          ),
        ),
      ],
    );
  }
}

/// Custom painter for double-ended dashed arrow <---->
class _DoubleEndedDashedArrowPainter extends CustomPainter {
  final Color color;

  _DoubleEndedDashedArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final startX = 6.0;
    final endX = size.width - 6.0;

    // 1. Draw dashed horizontal line
    final dashWidth = 5.5;
    final dashSpace = 4.0;
    double currentX = startX;

    while (currentX < endX) {
      canvas.drawLine(
        Offset(currentX, midY),
        Offset((currentX + dashWidth).clamp(startX, endX), midY),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }

    // 2. Left Arrowhead (<)
    final arrowPathLeft = Path()
      ..moveTo(startX + 8, midY - 6)
      ..lineTo(startX, midY)
      ..lineTo(startX + 8, midY + 6);
    canvas.drawPath(arrowPathLeft, paint);

    // 3. Right Arrowhead (>)
    final arrowPathRight = Path()
      ..moveTo(endX - 8, midY - 6)
      ..lineTo(endX, midY)
      ..lineTo(endX - 8, midY + 6);
    canvas.drawPath(arrowPathRight, paint);
  }

  @override
  bool shouldRepaint(covariant _DoubleEndedDashedArrowPainter oldDelegate) => oldDelegate.color != color;
}
