import '../../image_helper.dart';
import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "The Diagnostic Journey Still Breaks After the Report"
class DiagnosticJourneyBreaksSlide extends BaseSlide {
  @override
  String get type => 'diagnostic_journey_breaks';

  @override
  String get displayName => 'Diagnostic Journey Still Breaks';

  @override
  Widget build(SlideRenderContext context) {
    return _DiagnosticJourneyBreaksWidget(renderContext: context);
  }
}

class _DiagnosticJourneyBreaksWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _DiagnosticJourneyBreaksWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Theme colors
    final textDark = isLight ? const Color(0xFF0F172A) : Colors.white;
    final textMuted = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    final defaultUdIcons = [
      Icons.chat_bubble_rounded,
      Icons.mic_rounded,
      Icons.insert_drive_file_rounded,
      Icons.archive_rounded,
    ];
    final defaultUdBadgeBgs = [
      const Color(0xFFEDE9FE),
      const Color(0xFFE0F2FE),
      const Color(0xFFDCFCE7),
      const Color(0xFFFFEDD5),
    ];
    final defaultUdIconColors = [
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
      const Color(0xFF16A34A),
      const Color(0xFFEA580C),
    ];
    final defaultUdPrefixes = ["ud_chat", "ud_voice", "ud_docs", "ud_archive"];

    final defaultCaIcons = [
      Icons.auto_awesome_rounded,
      Icons.bar_chart_rounded,
      Icons.health_and_safety_rounded,
      Icons.favorite_rounded,
      Icons.add_rounded,
    ];
    final defaultCaBadgeBgs = [
      const Color(0xFFEDE9FE),
      const Color(0xFFE0F2FE),
      const Color(0xFFCCFBF1),
      const Color(0xFFFFEDD5),
      const Color(0xFFFFE4E6),
    ];
    final defaultCaIconColors = [
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
      const Color(0xFF0D9488),
      const Color(0xFFEA580C),
      const Color(0xFFE11D48),
    ];
    final defaultCaPrefixes = ["ca_agent1", "ca_agent2", "ca_agent3", "ca_agent4", "ca_more"];

    final defaultActIcons = [
      Icons.notifications_active_rounded,
      Icons.calendar_month_rounded,
      Icons.assignment_rounded,
      Icons.warning_amber_rounded,
    ];
    final defaultActBadgeBgs = [
      const Color(0xFFEDE9FE),
      const Color(0xFFE0F2FE),
      const Color(0xFFDCFCE7),
      const Color(0xFFFFEDD5),
    ];
    final defaultActIconColors = [
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
      const Color(0xFF16A34A),
      const Color(0xFFEA580C),
    ];
    final defaultActPrefixes = ["act_remind", "act_follow", "act_care", "act_escalate"];

    // USER DATA from JSON
    final rawUdItems = ((slide.rawContent['user_data'] as Map?)?['items'] as List?) ?? [];
    final userDataItems = rawUdItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "icon": defaultUdIcons[idx % defaultUdIcons.length],
        "badgeBg": defaultUdBadgeBgs[idx % defaultUdBadgeBgs.length],
        "iconColor": defaultUdIconColors[idx % defaultUdIconColors.length],
        "prefix": idx < defaultUdPrefixes.length ? defaultUdPrefixes[idx] : "ud_$idx",
      };
    }).toList();

    // COMPANY AGENTS from JSON
    final rawCaItems = ((slide.rawContent['company_agents'] as Map?)?['items'] as List?) ?? [];
    final companyAgents = rawCaItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "icon": defaultCaIcons[idx % defaultCaIcons.length],
        "badgeBg": defaultCaBadgeBgs[idx % defaultCaBadgeBgs.length],
        "iconColor": defaultCaIconColors[idx % defaultCaIconColors.length],
        "prefix": idx < defaultCaPrefixes.length ? defaultCaPrefixes[idx] : "ca_$idx",
      };
    }).toList();

    // ACTIONS from JSON
    final rawActItems = ((slide.rawContent['actions'] as Map?)?['items'] as List?) ?? [];
    final actionItems = rawActItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "icon": defaultActIcons[idx % defaultActIcons.length],
        "badgeBg": defaultActBadgeBgs[idx % defaultActBadgeBgs.length],
        "iconColor": defaultActIconColors[idx % defaultActIconColors.length],
        "prefix": idx < defaultActPrefixes.length ? defaultActPrefixes[idx] : "act_$idx",
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Title Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 14),

        // MAIN CONTENT AREA
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
                final totalW = constraints.maxWidth;
                final totalH = constraints.maxHeight;

                final leftW = totalW * 0.27;
                final centerArrowW = totalW * 0.045;
                final brainW = totalW * 0.17;
                final rightW = totalW * 0.47;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ==================== 1. LEFT COLUMN (USER DATA, COMPANY AGENTS, ACTIONS) ====================
                    SizedBox(
                      width: leftW,
                      height: totalH,
                      child: Stack(
                        children: [
                          // Outer Dashed Bracket Boundary Line connecting Left Section to Center Arrow
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _LeftOuterDashedBoundaryPainter(
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),

                          // Left Cards Column
                          Padding(
                            padding: const EdgeInsets.only(right: 56.0),
                            child: Column(
                              children: [
                                // TOP CARD: USER DATA
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: cardBorder, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isLight ? 0.025 : 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SelectableTextElement(
                                        elementKey: 'user_data_header',
                                        label: 'User Data Header',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('user_data_header', 'USER DATA'),
                                          style: TextStyle(
                                            color: textMuted,
                                            fontSize: slide.getFontSize('user_data_header', 14.5),
                                            fontWeight: slide.getFontWeight('user_data_header', FontWeight.w900),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: userDataItems.map((item) {
                                          final prefix = item['prefix'] as String;

                                          return Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: item['badgeBg'] as Color,
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  child: Icon(
                                                    item['icon'] as IconData,
                                                    size: 23,
                                                    color: item['iconColor'] as Color,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_title',
                                                  label: 'Item Title',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                                    style: TextStyle(
                                                      color: textDark,
                                                      fontSize: slide.getFontSize('${prefix}_title', 13.0),
                                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),

                                // Upper Expanded Vertical Dashed Line between USER DATA and COMPANY AGENTS
                                Expanded(
                                  child: CustomPaint(
                                    painter: _VerticalDashedLinePainter(
                                      color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),

                                // MIDDLE CARD: COMPANY AGENTS
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: cardBorder, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isLight ? 0.025 : 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SelectableTextElement(
                                        elementKey: 'company_agents_header',
                                        label: 'Company Agents Header',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('company_agents_header', 'COMPANY AGENTS'),
                                          style: TextStyle(
                                            color: textMuted,
                                            fontSize: slide.getFontSize('company_agents_header', 14.5),
                                            fontWeight: slide.getFontWeight('company_agents_header', FontWeight.w900),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        children: companyAgents.asMap().entries.map((entry) {
                                          final idx = entry.key;
                                          final item = entry.value;
                                          final prefix = item['prefix'] as String;

                                          return Padding(
                                            padding: EdgeInsets.only(bottom: idx == companyAgents.length - 1 ? 0 : 9),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: item['badgeBg'] as Color,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(
                                                      item['icon'] as IconData,
                                                      size: 20,
                                                      color: item['iconColor'] as Color,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: SelectableTextElement(
                                                      elementKey: '${prefix}_title',
                                                      label: 'Agent Title',
                                                      selectedElementKey: renderContext.selectedElementKey,
                                                      onSelectElement: renderContext.onSelectElement,
                                                      child: Text(
                                                        slide.getElementText('${prefix}_title', item['title'] as String),
                                                        style: TextStyle(
                                                          color: textDark,
                                                          fontSize: slide.getFontSize('${prefix}_title', 14.5),
                                                          fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),

                                // Lower Expanded Vertical Dashed Line between COMPANY AGENTS and ACTIONS
                                Expanded(
                                  child: CustomPaint(
                                    painter: _VerticalDashedLinePainter(
                                      color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),

                                // BOTTOM CARD: ACTIONS
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: cardBorder, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isLight ? 0.025 : 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SelectableTextElement(
                                        elementKey: 'actions_header',
                                        label: 'Actions Header',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('actions_header', 'ACTIONS'),
                                          style: TextStyle(
                                            color: textMuted,
                                            fontSize: slide.getFontSize('actions_header', 14.5),
                                            fontWeight: slide.getFontWeight('actions_header', FontWeight.w900),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: actionItems.map((item) {
                                          final prefix = item['prefix'] as String;

                                          return Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: item['badgeBg'] as Color,
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  child: Icon(
                                                    item['icon'] as IconData,
                                                    size: 23,
                                                    color: item['iconColor'] as Color,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                SelectableTextElement(
                                                  elementKey: '${prefix}_title',
                                                  label: 'Action Title',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                                    style: TextStyle(
                                                      color: textDark,
                                                      fontSize: slide.getFontSize('${prefix}_title', 13.0),
                                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w600),
                                                    ),
                                                  ),
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
                        ],
                      ),
                    ),

                    // Left Double-Ended Dashed Arrow (<----->) extending right towards brain icon
                    SizedBox(
                      width: centerArrowW,
                      height: 40,
                      child: CustomPaint(
                        painter: _DashedDoubleArrowPainter(
                          color: const Color(0xFF3B82F6),
                          marginLeft: 32.0, // Expanded gap away from Left Section
                          marginRight: -16.0, // Extends right up to the brain graphic
                        ),
                      ),
                    ),

                    // ==================== 2. CENTER BRAIN SECTION ====================
                    SizedBox(
                      width: brainW,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brain Graphic
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: Image.asset(
                              'assets/hero/brain.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 180,
                                  height: 180,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Center Company Logo Widget (Displays client company logo <presentationId>/assets/logo.png)
                          Builder(
                            builder: (context) {
                              String? logoPath = renderContext.companyLogoPath;
                              final cName = renderContext.companyName ?? '';

                              final String effectiveLogo = (logoPath != null && logoPath.isNotEmpty)
                                  ? logoPath
                                  : 'assets/presets/logo_presets/heydoc.png';

                              Widget logoWidget = buildUniversalImage(
                                effectiveLogo,
                                height: 48,
                                fit: BoxFit.contain,
                                presentationId: renderContext.folderPath ?? '',
                                fallback: cName.isNotEmpty
                                    ? Text(
                                        cName,
                                        style: TextStyle(
                                          color: isLight ? const Color(0xFF1E293B) : Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              );

                              return SizedBox(
                                height: 52,
                                child: Center(child: logoWidget),
                              );
                            },
                          ),
                          const SizedBox(height: 4),

                          // Subtitle Label: BRAIN
                          SelectableTextElement(
                            elementKey: 'brain_sub_label',
                            label: 'Brain Sub Label',
                            selectedElementKey: renderContext.selectedElementKey,
                            onSelectElement: renderContext.onSelectElement,
                            child: Text(
                              'BRAIN',
                              style: TextStyle(
                                color: const Color(0xFF2563EB),
                                fontSize: slide.getFontSize('brain_sub_label', 19.0),
                                fontWeight: slide.getFontWeight('brain_sub_label', FontWeight.w900),
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Double-Ended Dashed Arrow (<----->) extending left towards brain icon
                    SizedBox(
                      width: centerArrowW,
                      height: 40,
                      child: CustomPaint(
                        painter: _DashedDoubleArrowPainter(
                          color: const Color(0xFF3B82F6),
                          marginLeft: -16.0, // Extends left right up to the brain graphic
                          marginRight: 32.0, // Expanded gap away from Right Dashboard UI
                        ),
                      ),
                    ),

                    // ==================== 3. RIGHT COLUMN (ENTERPRISE DASHBOARD UI) ====================
                    SizedBox(
                      width: rightW,
                      height: totalH,
                      child: ClipRect(
                        child: Image.asset(
                          'assets/presets/enterprise_dashboard.png',
                          fit: BoxFit.fitHeight,
                          alignment: Alignment.centerLeft,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                              ),
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.dashboard_rounded, size: 48, color: Color(0xFF3B82F6)),
                                  SizedBox(height: 8),
                                  Text(
                                    'Enterprise Dashboard UI',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }
}

/// Custom painter for Left Section Outer Dashed Boundary Bracket & Inner Company Agent Inter-Connection Bus
class _LeftOuterDashedBoundaryPainter extends CustomPainter {
  final Color color;

  _LeftOuterDashedBoundaryPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cornerRadius = 14.0;
    final innerCornerRadius = 8.0;
    final dashWidth = 4.0;
    final dashSpace = 3.0;

    final cardAreaW = size.width - 56.0; // Where the cards end on the right
    final innerSpineX = cardAreaW + 24.0; // Inner bus spine position (24px gap from card)
    final outerSpineX = size.width - 8.0; // Outer main spine position (24px gap from inner bus)

    final topDotY = size.height * 0.08;
    final bottomDotY = size.height * 0.92;
    final centerY = size.height * 0.5;

    // Paints
    final mainPaint = Paint()
      ..color = const Color(0xFF6366F1) // Soft purple/indigo for main outer line
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    // ================= 1. OUTER MAIN CONNECTING BRACKET LINE =================
    // Top Purple Dot on USER DATA card edge
    dotPaint.color = const Color(0xFF8B5CF6);
    canvas.drawCircle(Offset(cardAreaW, topDotY), 4.0, dotPaint);

    // Bottom Blue Dot on ACTIONS card edge
    dotPaint.color = const Color(0xFF3B82F6);
    canvas.drawCircle(Offset(cardAreaW, bottomDotY), 4.0, dotPaint);

    // Outer Main Path: Top dot -> right -> 90deg turn down -> vertical spine -> 90deg turn left -> Bottom dot
    final outerPath = Path()
      ..moveTo(cardAreaW, topDotY)
      ..lineTo(outerSpineX - cornerRadius, topDotY)
      ..quadraticBezierTo(outerSpineX, topDotY, outerSpineX, topDotY + cornerRadius)
      ..lineTo(outerSpineX, bottomDotY - cornerRadius)
      ..quadraticBezierTo(outerSpineX, bottomDotY, outerSpineX - cornerRadius, bottomDotY)
      ..lineTo(cardAreaW, bottomDotY);

    _drawDashedPath(canvas, outerPath, mainPaint, dashWidth, dashSpace);

    // Branch from outerSpineX at centerY to size.width (connecting to center arrow)
    final outerBranchPath = Path()
      ..moveTo(outerSpineX, centerY)
      ..lineTo(size.width, centerY);
    _drawDashedPath(canvas, outerBranchPath, mainPaint, dashWidth, dashSpace);

    // Central Node Dot on outer spine branch end
    dotPaint.color = const Color(0xFF3B82F6);
    canvas.drawCircle(Offset(size.width, centerY), 3.5, dotPaint);

    // ================= 2. INNER COMPANY AGENTS INTER-CONNECTION BUS =================
    // 5 Agent Dots & Colors
    final agentColors = [
      const Color(0xFF3B82F6), // Care Assistant (Blue)
      const Color(0xFF0EA5E9), // Triage Agent (Light Blue/Cyan)
      const Color(0xFF14B8A6), // Insurance Agent (Teal/Mint)
      const Color(0xFFF97316), // Wellness Coach (Orange)
      const Color(0xFFEF4444), // More Agents (Red/Coral)
    ];

    // Compute 5 agent Y positions in center region of height
    final agentTopY = size.height * 0.31;
    final agentBottomY = size.height * 0.69;
    final agentStepY = (agentBottomY - agentTopY) / 4;
    final agentYs = List.generate(5, (i) => agentTopY + i * agentStepY);

    // Draw 5 Agent Dots & Inner Curved Connecting Bus Segments
    for (int i = 0; i < 5; i++) {
      final y = agentYs[i];
      dotPaint.color = agentColors[i];
      canvas.drawCircle(Offset(cardAreaW, y), 3.5, dotPaint);

      if (i < 4) {
        final nextY = agentYs[i + 1];
        final segmentPaint = Paint()
          ..color = agentColors[i].withValues(alpha: 0.85)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        // Path from current agent dot to innerSpineX, down to nextY, and turn back to next agent dot
        final segmentPath = Path()
          ..moveTo(cardAreaW, y)
          ..lineTo(innerSpineX - innerCornerRadius, y)
          ..quadraticBezierTo(innerSpineX, y, innerSpineX, y + innerCornerRadius)
          ..lineTo(innerSpineX, nextY - innerCornerRadius)
          ..quadraticBezierTo(innerSpineX, nextY, innerSpineX - innerCornerRadius, nextY)
          ..lineTo(cardAreaW, nextY);

        _drawDashedPath(canvas, segmentPath, segmentPaint, 3.5, 2.5);
      }
    }

    // Horizontal bridge line connecting innerSpineX at centerY to outerSpineX
    final bridgePaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.7)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bridgePath = Path()
      ..moveTo(innerSpineX, centerY)
      ..lineTo(outerSpineX, centerY);
    _drawDashedPath(canvas, bridgePath, bridgePaint, 3.5, 2.5);
  }

  @override
  bool shouldRepaint(covariant _LeftOuterDashedBoundaryPainter oldDelegate) => oldDelegate.color != color;
}

/// Custom painter for Double-Ended Dashed Connector Arrow (<--------->)
class _DashedDoubleArrowPainter extends CustomPainter {
  final Color color;
  final double marginLeft;
  final double marginRight;

  _DashedDoubleArrowPainter({
    required this.color,
    this.marginLeft = 12.0,
    this.marginRight = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final y = size.height / 2;

    final path = Path()
      ..moveTo(marginLeft + 6, y)
      ..lineTo(size.width - marginRight - 6, y);

    _drawDashedPath(canvas, path, paint, 5.0, 3.5);

    // Left Arrowhead (<)
    final leftHead = Path()
      ..moveTo(marginLeft + 7, y - 5)
      ..lineTo(marginLeft, y)
      ..lineTo(marginLeft + 7, y + 5);
    canvas.drawPath(leftHead, paint);

    // Right Arrowhead (>)
    final rightHead = Path()
      ..moveTo(size.width - marginRight - 7, y - 5)
      ..lineTo(size.width - marginRight, y)
      ..lineTo(size.width - marginRight - 7, y + 5);
    canvas.drawPath(rightHead, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedDoubleArrowPainter oldDelegate) => true;
}

/// Custom painter for Vertical Dashed Line connecting Middle Card to Bottom Card
class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;

  _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final x = size.width / 2;
    final path = Path()
      ..moveTo(x, 0)
      ..lineTo(x, size.height);

    _drawDashedPath(canvas, path, paint, 4.0, 3.0);
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) => oldDelegate.color != color;
}

/// Helper to render any Path with uniform dash width and dash space
void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
  for (final metric in path.computeMetrics()) {
    double distance = 0.0;
    while (distance < metric.length) {
      final extractLength = (distance + dashWidth).clamp(0.0, metric.length);
      final extractPath = metric.extractPath(distance, extractLength);
      canvas.drawPath(extractPath, paint);
      distance += dashWidth + dashSpace;
    }
  }
}
