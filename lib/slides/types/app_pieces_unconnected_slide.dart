import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "The App Has the Pieces. The Player Still Has to Connect Them."
class AppPiecesUnconnectedSlide extends BaseSlide {
  @override
  String get type => 'app_pieces_unconnected';

  @override
  String get displayName => 'App Pieces Unconnected';

  @override
  Widget build(SlideRenderContext context) {
    return _AppPiecesUnconnectedWidget(renderContext: context);
  }
}

class _AppPiecesUnconnectedWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _AppPiecesUnconnectedWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;

    final stepColors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFFEA580C),
    ];

    final stepSoftBgs = isLight
        ? [
            const Color(0xFFEFF6FF),
            const Color(0xFFF5F3FF),
            const Color(0xFFFFF7ED),
          ]
        : [
            const Color(0xFF1E293B),
            const Color(0xFF261E38),
            const Color(0xFF3B2A1A),
          ];

    final stepIcons = [
      Icons.help_outline_rounded,
      Icons.alt_route_rounded,
      Icons.analytics_outlined,
    ];

    // Raw columns data from JSON
    final rawColumns = (slide.rawContent['columns'] as List?) ?? [];
    final columns = rawColumns.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      final dynamic qData = item['questions'] ?? item['question'];
      final rawQuestions = qData is List
          ? qData
          : (qData != null && qData.toString().isNotEmpty ? [qData] : <dynamic>[]);
      final questionsList = rawQuestions.map((q) => q.toString()).toList();
      if (questionsList.isEmpty) {
        final overrideQ = slide.getElementText('col_${idx + 1}_q_1', '');
        if (overrideQ.isNotEmpty) {
          questionsList.add(overrideQ);
        }
      }
      return {
        "step_number": item['step_number']?.toString() ?? '',
        "step_title": item['step_title']?.toString() ?? '',
        "description": item['description']?.toString() ?? '',
        "question_label": item['question_label']?.toString() ?? '',
        "questions": questionsList,
        "image_key": item['image_key']?.toString() ?? 'mobile_image_$idx',
        "color": stepColors[idx % stepColors.length],
        "soft_bg": stepSoftBgs[idx % stepSoftBgs.length],
        "icon": stepIcons[idx % stepIcons.length],
        "prefix": "col_${idx + 1}",
      };
    }).toList();

    // Raw Gap Banner data from JSON
    final rawGap = (slide.rawContent['gap_banner'] as Map?) ?? {};
    final gapTitle = rawGap['title']?.toString() ?? '';
    final gapDesc = rawGap['description']?.toString() ?? '';
    final rawIssues = (rawGap['issues'] as List?) ?? [];
    final issues = rawIssues.map((i) => i.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Title & Subtitle Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 14),

        // 1. MAIN 3 COLUMNS WITH PHONE MOCKUPS
        Expanded(
          flex: 82,
          child: Row(
            children: columns.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final prefix = item['prefix'] as String;
              final color = item['color'] as Color;
              final softBg = item['soft_bg'] as Color;
              final iconData = item['icon'] as IconData;
              final imageKey = item['image_key'] as String;
              final questionsList = item['questions'] as List<String>;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: idx == columns.length - 1 ? 0 : 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder, width: 1.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left Mockup Slot (Mobile Phone Ratio 9:18)
                      AspectRatio(
                        aspectRatio: 9 / 18,
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

                      const SizedBox(width: 12),

                      // Right Content Column (Adaptive Width)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Soft Colored Icon Box
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: softBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                iconData,
                                size: 28,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Step Number & Title
                            SelectableTextElement(
                              elementKey: '${prefix}_title',
                              label: 'Step Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText(
                                    '${prefix}_title',
                                    (item['step_number'] as String).isNotEmpty
                                        ? '${item['step_number']}. ${item['step_title']}'
                                        : item['step_title'] as String),
                                style: TextStyle(
                                  color: color,
                                  fontSize: slide.getFontSize('${prefix}_title', 19.0),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Description Text
                            SelectableTextElement(
                              elementKey: '${prefix}_desc',
                              label: 'Step Description',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText(
                                    '${prefix}_desc', item['description'] as String),
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: slide.getFontSize('${prefix}_desc', 15.0),
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Dashed Divider
                            CustomPaint(
                              size: const Size(double.infinity, 1),
                              painter: _DashedLinePainter(
                                color: isLight
                                    ? const Color(0xFFE5E7EB)
                                    : const Color(0xFF444444),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Question Subheader
                            SelectableTextElement(
                              elementKey: '${prefix}_q_label',
                              label: 'Question Label',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText(
                                    '${prefix}_q_label', item['question_label'] as String),
                                style: TextStyle(
                                  color: color,
                                  fontSize: slide.getFontSize('${prefix}_q_label', 13.0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Chat Bubble / Speech Box with User Badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: softBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: questionsList.asMap().entries.map((qEntry) {
                                      final qIdx = qEntry.key;
                                      final q = qEntry.value;
                                      final qKey = '${prefix}_q_${qIdx + 1}';

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 3.0),
                                        child: SelectableTextElement(
                                          elementKey: qKey,
                                          label: 'Question ${qIdx + 1}',
                                          selectedElementKey: renderContext.selectedElementKey,
                                          onSelectElement: renderContext.onSelectElement,
                                          child: Text(
                                            slide.getElementText(qKey, q),
                                            style: TextStyle(
                                              color: textDark,
                                              fontSize: slide.getFontSize(qKey, 13.5),
                                              fontWeight: FontWeight.w600,
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                                // Small User Avatar Icon on Bottom-Right of Speech Bubble
                                Positioned(
                                  right: -8,
                                  bottom: -8,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: cardBg, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // 2. BOTTOM GAP BANNER
        Expanded(
          flex: 18,
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
                // Left Warning Section: THE GAP
                Expanded(
                  flex: 50,
                  child: Row(
                    children: [
                      // Warning Badge Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 28,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableTextElement(
                              elementKey: 'gap_banner_title',
                              label: 'Gap Banner Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText('gap_banner_title', gapTitle),
                                style: TextStyle(
                                  color: const Color(0xFFEF4444),
                                  fontSize: slide.getFontSize('gap_banner_title', 18.5),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            SelectableTextElement(
                              elementKey: 'gap_banner_desc',
                              label: 'Gap Banner Description',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText('gap_banner_desc', gapDesc),
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: slide.getFontSize('gap_banner_desc', 14.5),
                                  fontWeight: FontWeight.w700,
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

                // Vertical Separator Line
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333),
                ),

                // Right Issues Row (5 small cross icon items)
                Expanded(
                  flex: 50,
                  child: Row(
                    children: issues.asMap().entries.map((entry) {
                      final iIdx = entry.key;
                      final issueText = entry.value;
                      final issueKey = 'gap_issue_${iIdx + 1}';

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableTextElement(
                              elementKey: issueKey,
                              label: 'Issue ${iIdx + 1}',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText(issueKey, issueText),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: slide.getFontSize(issueKey, 13.0),
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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

/// Helper painter for drawing dashed horizontal divider lines
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
