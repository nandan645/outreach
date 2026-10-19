import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "From Player Data to a Personalized Player Experience"
class PersonalizedPlayerExperienceSlide extends BaseSlide {
  @override
  String get type => 'personalized_player_experience';

  @override
  String get displayName => 'Personalized Player Experience';

  @override
  Widget build(SlideRenderContext context) {
    return _PersonalizedPlayerExperienceWidget(renderContext: context);
  }
}

class _PersonalizedPlayerExperienceWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _PersonalizedPlayerExperienceWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFECEFF2) : const Color(0xFF333333);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    final contextIcons = [
      Icons.person_outline_rounded,
      Icons.calendar_month_rounded,
      Icons.bar_chart_rounded,
      Icons.fitness_center_rounded,
      Icons.credit_card_rounded,
      Icons.chat_bubble_outline_rounded,
    ];

    final actionIcons = [
      Icons.calendar_month_rounded,
      Icons.sports_rounded,
      Icons.notifications_none_rounded,
      Icons.chat_bubble_outline_rounded,
      Icons.sync_rounded,
    ];

    final stepIcons = [
      Icons.person_outline_rounded,
      Icons.auto_awesome_rounded,
      Icons.track_changes_rounded,
    ];

    // Data parsing from JSON
    final rawContext = (slide.rawContent['player_context'] as Map?) ?? {};
    final contextTitle = rawContext['title']?.toString() ?? '';
    final rawContextItems = (rawContext['items'] as List?) ?? [];
    final contextItems = rawContextItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['description']?.toString() ?? '',
        "icon": contextIcons[idx % contextIcons.length],
        "prefix": "ctx_${idx + 1}",
      };
    }).toList();

    final rawWellness = (slide.rawContent['wellnessgpt'] as Map?) ?? {};
    final wellnessTitle = rawWellness['title']?.toString() ?? '';
    final rawWellnessSteps = (rawWellness['steps'] as List?) ?? [];
    final wellnessSteps = rawWellnessSteps.map((s) => s.toString()).toList();

    final rawAction = (slide.rawContent['next_best_action'] as Map?) ?? {};
    final actionTitle = rawAction['title']?.toString() ?? '';
    final rawActionItems = (rawAction['items'] as List?) ?? [];
    final actionItems = rawActionItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['description']?.toString() ?? '',
        "icon": actionIcons[idx % actionIcons.length],
        "prefix": "act_${idx + 1}",
      };
    }).toList();

    final rawExperience = (slide.rawContent['player_experience'] as Map?) ?? {};
    final expTitle = rawExperience['title']?.toString() ?? '';
    final expImageKey = rawExperience['image_key']?.toString() ?? 'mobile_image_0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 16),

        // MAIN CANVAS CONTAINER
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Handle Indicator Pill
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFF1E1E1E) : const Color(0xFFCCCCCC),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 12),

                // 4 COLUMNS CONTENT ROW
                Expanded(
                  child: Row(
                    children: [
                      // ==================== 1. PLAYER CONTEXT (LEFT COLUMN) ====================
                      Expanded(
                        flex: 21,
                        child: Column(
                          children: [
                            // Header Pill
                            SelectableTextElement(
                              elementKey: 'player_context_title',
                              label: 'Player Context Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  slide.getElementText('player_context_title', contextTitle),
                                  style: TextStyle(
                                    color: const Color(0xFF2563EB),
                                    fontSize: slide.getFontSize('player_context_title', 13.5),
                                    fontWeight: slide.getFontWeight('player_context_title', FontWeight.w800),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Unified Container for all Player Context items
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF262A34),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF333844),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: contextItems.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    final prefix = item['prefix'] as String;
                                    final iconData = item['icon'] as IconData;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Icon Circle
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E293B),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: SelectableIconElement(
                                              elementKey: '${prefix}_icon',
                                              label: 'Context Icon ${idx + 1}',
                                              icon: slide.getIcon('${prefix}_icon', iconData),
                                              size: slide.getFontSize('${prefix}_icon', 22.0),
                                              color: const Color(0xFF2563EB),
                                              selectedElementKey: renderContext.selectedElementKey,
                                              onSelectElement: renderContext.onSelectElement,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Text Column
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_title',
                                                  label: 'Context Title ${idx + 1}',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                                    style: TextStyle(
                                                      color: textDark,
                                                      fontSize: slide.getFontSize('${prefix}_title', 17.0),
                                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w800),
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_desc',
                                                  label: 'Context Desc ${idx + 1}',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_desc', item['desc'] as String),
                                                    style: TextStyle(
                                                      color: textMuted,
                                                      fontSize: slide.getFontSize('${prefix}_desc', 13.5),
                                                      fontWeight: slide.getFontWeight('${prefix}_desc', FontWeight.w500),
                                                      height: 1.25,
                                                    ),
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // LEFT CONNECTING LINES (Player Context -> Brain)
                      SizedBox(
                        width: 56,
                        child: Column(
                          children: [
                            const SizedBox(height: 38),
                            Expanded(
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _LeftBrainConnectorPainter(
                                  itemCount: contextItems.length,
                                  lineColor: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  dotColor: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================== 2. WELLNESSGPT (CENTER COLUMN) ====================
                      Expanded(
                        flex: 23,
                        child: Column(
                          children: [
                            // Header Pill
                            SelectableTextElement(
                              elementKey: 'wellness_title',
                              label: 'Wellness Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  slide.getElementText('wellness_title', wellnessTitle),
                                  style: TextStyle(
                                    color: const Color(0xFF2563EB),
                                    fontSize: slide.getFontSize('wellness_title', 13.5),
                                    fontWeight: slide.getFontWeight('wellness_title', FontWeight.w800),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Brain Graphic Node & Steps
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Brain Graphic with AI Badge
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/hero/brain.png',
                                        width: 185,
                                        height: 185,
                                        fit: BoxFit.contain,
                                        errorBuilder: (ctx, err, stack) => const Icon(
                                          Icons.psychology_rounded,
                                          size: 145,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                                        decoration: BoxDecoration(
                                          color: isLight ? Colors.white : const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'AI',
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),

                                  // 3 Pill Steps with Down Arrows (Equal Size)
                                  ...wellnessSteps.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final stepText = entry.value;
                                    final iconData = stepIcons[idx % stepIcons.length];
                                    final isLast = idx == wellnessSteps.length - 1;
                                    final stepKey = 'wellness_step_${idx + 1}';

                                    return Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 240,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF262A34),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF333844),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SelectableIconElement(
                                                  elementKey: '${stepKey}_icon',
                                                  label: 'Step Icon ${idx + 1}',
                                                  icon: slide.getIcon('${stepKey}_icon', iconData),
                                                  size: slide.getFontSize('${stepKey}_icon', 20.0),
                                                  color: const Color(0xFF2563EB),
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: SelectableTextElement(
                                                    elementKey: stepKey,
                                                    label: 'Wellness Step ${idx + 1}',
                                                    selectedElementKey: renderContext.selectedElementKey,
                                                    onSelectElement: renderContext.onSelectElement,
                                                    child: Text(
                                                      slide.getElementText(stepKey, stepText),
                                                      style: TextStyle(
                                                        color: textDark,
                                                        fontSize: slide.getFontSize(stepKey, 14.5),
                                                        fontWeight: slide.getFontWeight(stepKey, FontWeight.w700),
                                                        height: 1.2,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (!isLast)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 4),
                                            child: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 22,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // RIGHT CONNECTING LINES (Brain -> Next Best Action)
                      SizedBox(
                        width: 56,
                        child: Column(
                          children: [
                            const SizedBox(height: 38),
                            Expanded(
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _RightBrainConnectorPainter(
                                  itemCount: actionItems.length,
                                  lineColor: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  dotColor: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================== 3. NEXT BEST ACTION (MIDDLE-RIGHT COLUMN) ====================
                      Expanded(
                        flex: 21,
                        child: Column(
                          children: [
                            // Header Pill
                            SelectableTextElement(
                              elementKey: 'next_best_action_title',
                              label: 'Next Best Action Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F0FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  slide.getElementText('next_best_action_title', actionTitle),
                                  style: TextStyle(
                                    color: const Color(0xFF6D28D9),
                                    fontSize: slide.getFontSize('next_best_action_title', 13.5),
                                    fontWeight: slide.getFontWeight('next_best_action_title', FontWeight.w800),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Unified Container for all Next Best Action items
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isLight ? const Color(0xFFFBF9FF) : const Color(0xFF251E38),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isLight ? const Color(0xFFEDE9FE) : const Color(0xFF3B2E59),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: actionItems.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    final prefix = item['prefix'] as String;
                                    final iconData = item['icon'] as IconData;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Icon Circle
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isLight ? const Color(0xFFF3F0FF) : const Color(0xFF32284D),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: SelectableIconElement(
                                              elementKey: '${prefix}_icon',
                                              label: 'Action Icon ${idx + 1}',
                                              icon: slide.getIcon('${prefix}_icon', iconData),
                                              size: slide.getFontSize('${prefix}_icon', 22.0),
                                              color: const Color(0xFF6D28D9),
                                              selectedElementKey: renderContext.selectedElementKey,
                                              onSelectElement: renderContext.onSelectElement,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Text Column
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_title',
                                                  label: 'Action Title ${idx + 1}',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                                    style: TextStyle(
                                                      color: textDark,
                                                      fontSize: slide.getFontSize('${prefix}_title', 17.0),
                                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w800),
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_desc',
                                                  label: 'Action Desc ${idx + 1}',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_desc', item['desc'] as String),
                                                    style: TextStyle(
                                                      color: textMuted,
                                                      fontSize: slide.getFontSize('${prefix}_desc', 13.5),
                                                      fontWeight: slide.getFontWeight('${prefix}_desc', FontWeight.w500),
                                                      height: 1.25,
                                                    ),
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // ==================== 4. PLAYER EXPERIENCE (RIGHT COLUMN: PHONE MOCKUP) ====================
                      Expanded(
                        flex: 24,
                        child: Column(
                          children: [
                            // Header Pill
                            SelectableTextElement(
                              elementKey: 'player_experience_title',
                              label: 'Player Experience Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F0FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  slide.getElementText('player_experience_title', expTitle),
                                  style: TextStyle(
                                    color: const Color(0xFF6D28D9),
                                    fontSize: slide.getFontSize('player_experience_title', 12.0),
                                    fontWeight: slide.getFontWeight('player_experience_title', FontWeight.w800),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Phone Mockup Dropzone Container
                            Expanded(
                              child: ImageDropzoneWidget(
                                slideId: slide.id,
                                imageKey: expImageKey,
                                companyName: renderContext.companyName,
                                label: 'Player App',
                                formatHint: '9:18',
                                height: double.infinity,
                                isMobileFrame: true,
                                initialImagePath: slide.getImagePath(expImageKey),
                                folderPath: renderContext.folderPath,
                                onImageSelected: (path) {
                                  if (renderContext.onImageChanged != null) {
                                    renderContext.onImageChanged!(expImageKey, path);
                                  }
                                },
                              ),
                            ),
                          ],
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
    );
  }
}

/// Painter for the dashed circuit lines from Player Context to the AI Brain (straight + 90° turns with rounded corners)
class _LeftBrainConnectorPainter extends CustomPainter {
  final int itemCount;
  final Color lineColor;
  final Color dotColor;

  _LeftBrainConnectorPainter({
    required this.itemCount,
    required this.lineColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount <= 0) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final xTrunk = w * 0.72;

    // Center of brain in vertically centered layout:
    final effectiveTargetY = math.max(45.0, (h - 390.0) / 2.0 + 92.5);

    // Draw 90° orthogonal lines with curved corners from each item
    for (int i = 0; i < itemCount; i++) {
      final y = (i + 0.5) * (h / itemCount);

      // Blue dot on left edge
      canvas.drawCircle(Offset(2.0, y), 3.8, dotPaint);

      final path = Path();
      if ((y - effectiveTargetY).abs() < 4.0) {
        // Direct horizontal line
        path.moveTo(2.0, y);
        path.lineTo(w - 7.0, effectiveTargetY);
      } else if (y < effectiveTargetY) {
        // Above target: horizontal -> 90° turn down -> vertical -> 90° turn right -> horizontal
        final r = math.min(10.0, (effectiveTargetY - y) / 2.0);
        path.moveTo(2.0, y);
        path.lineTo(xTrunk - r, y);
        path.arcToPoint(
          Offset(xTrunk, y + r),
          radius: Radius.circular(r),
          clockwise: true,
        );
        path.lineTo(xTrunk, effectiveTargetY - r);
        path.arcToPoint(
          Offset(xTrunk + r, effectiveTargetY),
          radius: Radius.circular(r),
          clockwise: false,
        );
        path.lineTo(w - 7.0, effectiveTargetY);
      } else {
        // Below target: horizontal -> 90° turn up -> vertical -> 90° turn right -> horizontal
        final r = math.min(10.0, (y - effectiveTargetY) / 2.0);
        path.moveTo(2.0, y);
        path.lineTo(xTrunk - r, y);
        path.arcToPoint(
          Offset(xTrunk, y - r),
          radius: Radius.circular(r),
          clockwise: false,
        );
        path.lineTo(xTrunk, effectiveTargetY + r);
        path.arcToPoint(
          Offset(xTrunk + r, effectiveTargetY),
          radius: Radius.circular(r),
          clockwise: true,
        );
        path.lineTo(w - 7.0, effectiveTargetY);
      }

      _drawDashedPath(canvas, path, linePaint, 4.0, 4.0);
    }

    // Cyan accent dot near arrowhead
    final cyanDotPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.86, effectiveTargetY), 3.4, cyanDotPaint);

    // Arrowhead pointing right into the brain
    final arrowPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(w, effectiveTargetY)
      ..lineTo(w - 7.0, effectiveTargetY - 5.0)
      ..lineTo(w - 7.0, effectiveTargetY + 5.0)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLength, double dashSpace) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LeftBrainConnectorPainter oldDelegate) =>
      oldDelegate.itemCount != itemCount ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dotColor != dotColor;
}

/// Painter for the dashed circuit lines from the AI Brain to Next Best Action (straight + 90° turns with rounded corners)
class _RightBrainConnectorPainter extends CustomPainter {
  final int itemCount;
  final Color lineColor;
  final Color dotColor;

  _RightBrainConnectorPainter({
    required this.itemCount,
    required this.lineColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount <= 0) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final xTrunk = w * 0.28;

    // Center of brain in vertically centered layout:
    final effectiveStartY = math.max(45.0, (h - 390.0) / 2.0 + 92.5);

    // Cyan dot near brain output
    final cyanDotPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(6.0, effectiveStartY), 3.4, cyanDotPaint);

    // Draw 90° orthogonal lines with curved corners branching to each action item
    for (int i = 0; i < itemCount; i++) {
      final y = (i + 0.5) * (h / itemCount);

      final path = Path();
      if ((y - effectiveStartY).abs() < 4.0) {
        // Direct horizontal line
        path.moveTo(0, effectiveStartY);
        path.lineTo(w - 2.0, y);
      } else if (y < effectiveStartY) {
        // Above brain: horizontal -> 90° turn up -> vertical -> 90° turn right -> horizontal
        final r = math.min(10.0, (effectiveStartY - y) / 2.0);
        path.moveTo(0, effectiveStartY);
        path.lineTo(xTrunk - r, effectiveStartY);
        path.arcToPoint(
          Offset(xTrunk, effectiveStartY - r),
          radius: Radius.circular(r),
          clockwise: false,
        );
        path.lineTo(xTrunk, y + r);
        path.arcToPoint(
          Offset(xTrunk + r, y),
          radius: Radius.circular(r),
          clockwise: true,
        );
        path.lineTo(w - 2.0, y);
      } else {
        // Below brain: horizontal -> 90° turn down -> vertical -> 90° turn right -> horizontal
        final r = math.min(10.0, (y - effectiveStartY) / 2.0);
        path.moveTo(0, effectiveStartY);
        path.lineTo(xTrunk - r, effectiveStartY);
        path.arcToPoint(
          Offset(xTrunk, effectiveStartY + r),
          radius: Radius.circular(r),
          clockwise: true,
        );
        path.lineTo(xTrunk, y - r);
        path.arcToPoint(
          Offset(xTrunk + r, y),
          radius: Radius.circular(r),
          clockwise: false,
        );
        path.lineTo(w - 2.0, y);
      }

      _drawDashedPath(canvas, path, linePaint, 4.0, 4.0);

      // Purple dot on right edge
      canvas.drawCircle(Offset(w - 2.0, y), 3.8, dotPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLength, double dashSpace) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RightBrainConnectorPainter oldDelegate) =>
      oldDelegate.itemCount != itemCount ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dotColor != dotColor;
}

