import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "HeyDoc AI Adds the Action Layer Around Redcliffe's Existing Infrastructure."
class ActionLayerInfrastructureSlide extends BaseSlide {
  @override
  String get type => 'action_layer_infrastructure';

  @override
  String get displayName => 'Action Layer Around Infrastructure';

  @override
  Widget build(SlideRenderContext context) {
    return _ActionLayerInfrastructureWidget(renderContext: context);
  }
}

class _ActionLayerInfrastructureWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _ActionLayerInfrastructureWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Theme colors
    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);

    final defaultSysIcons = [
      Icons.science_rounded,
      Icons.psychology_rounded,
      Icons.coronavirus_rounded,
      Icons.face_retouching_natural_rounded,
      Icons.calendar_month_rounded,
      Icons.groups_rounded,
    ];

    final defaultLeftCapIcons = [
      Icons.chat_bubble_outline_rounded,
      Icons.psychology_outlined,
      Icons.description_outlined,
    ];

    final defaultRightCapIcons = [
      Icons.hub_outlined,
      Icons.storage_rounded,
      Icons.person_outline_rounded,
    ];

    final defaultAgentIcons = [
      Icons.calendar_month_rounded,
      Icons.description_outlined,
      Icons.volunteer_activism_rounded,
      Icons.settings_rounded,
      Icons.work_outline_rounded,
    ];

    final defaultOutcomeIcons = [
      Icons.person_rounded,
      Icons.medical_services_rounded,
      Icons.apartment_rounded,
      Icons.build_rounded,
    ];

    // Left Systems Data from JSON
    final rawSystems = (slide.rawContent['existing_systems'] as List?) ?? [];
    final existingSystems = rawSystems.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['desc']?.toString() ?? '',
        "icon": defaultSysIcons[idx % defaultSysIcons.length],
        "prefix": "sys_${idx + 1}",
      };
    }).toList();

    // WellnessGPT Center Left Capabilities from JSON
    final rawLCaps = ((slide.rawContent['wellnessgpt'] as Map?)?['left_capabilities'] as List?) ?? [];
    final leftCaps = rawLCaps.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "icon": defaultLeftCapIcons[idx % defaultLeftCapIcons.length],
        "prefix": "cap_l${idx + 1}",
      };
    }).toList();

    // WellnessGPT Center Right Capabilities from JSON
    final rawRCaps = ((slide.rawContent['wellnessgpt'] as Map?)?['right_capabilities'] as List?) ?? [];
    final rightCaps = rawRCaps.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "icon": defaultRightCapIcons[idx % defaultRightCapIcons.length],
        "prefix": "cap_r${idx + 1}",
      };
    }).toList();

    // WellnessGPT Bottom Specialized Agents from JSON
    final rawAgents = ((slide.rawContent['wellnessgpt'] as Map?)?['agents'] as List?) ?? [];
    final bottomAgents = rawAgents.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "icon": defaultAgentIcons[idx % defaultAgentIcons.length],
        "prefix": "ag_${idx + 1}",
      };
    }).toList();

    // Right Outcomes Data from JSON
    final rawOutcomes = (slide.rawContent['outcomes'] as List?) ?? [];
    final outcomes = rawOutcomes.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['desc']?.toString() ?? '',
        "icon": defaultOutcomeIcons[idx % defaultOutcomeIcons.length],
        "prefix": "out_${idx + 1}",
      };
    }).toList();

    final blueAccent = const Color(0xFF2563EB);
    final blueBgSoft = isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E293B);
    final purpleAccent = const Color(0xFF6D28D9);
    final purpleBgSoft = isLight ? const Color(0xFFF5F3FF) : const Color(0xFF261E38);
    final tealAccent = const Color(0xFF0D9488);
    final tealBgSoft = isLight ? const Color(0xFFECFDF5) : const Color(0xFF132A22);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Title Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 14),

        // MAIN CONTENT AREA
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF181C24),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.4),
            ),
            child: Column(
              children: [
                // Top Indicator Pill Bar
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFF1F2937) : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3 MAIN COLUMNS ROW WITH CURVED CONNECTOR PAINTERS
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalW = constraints.maxWidth;
                      final totalH = constraints.maxHeight;

                      final leftW = totalW * 0.205;
                      final centerW = totalW * 0.52;
                      final rightW = totalW * 0.205;

                      final gap1W = totalW * 0.035;
                      final gap2W = totalW * 0.035;

                      return Stack(
                        children: [
                          // ==================== CURVED CONNECTORS CUSTOM PAINTERS ====================
                          // Left System Dots to Center WellnessGPT Curved Lines
                          Positioned(
                            left: leftW,
                            top: 0,
                            width: gap1W,
                            height: totalH,
                            child: CustomPaint(
                              painter: _LeftSystemToCenterPainter(
                                color: isLight ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                                count: 6,
                              ),
                            ),
                          ),

                          // Center WellnessGPT Right to Outcomes Dots Curved Lines
                          Positioned(
                            left: leftW + gap1W + centerW,
                            top: 0,
                            width: gap2W,
                            height: totalH,
                            child: CustomPaint(
                              painter: _CenterToRightOutcomesPainter(
                                color: isLight ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                                count: 4,
                              ),
                            ),
                          ),

                          // Center WellnessGPT Bottom to 5 Agents Branching Tree Painter
                          Positioned(
                            left: leftW + gap1W,
                            top: totalH * 0.67,
                            width: centerW,
                            height: totalH * 0.08,
                            child: CustomPaint(
                              painter: _CenterToBottomAgentsPainter(
                                color: isLight ? const Color(0xFFA5B4FC) : const Color(0xFF818CF8),
                                count: 5,
                              ),
                            ),
                          ),

                          // ==================== 3 COLUMNS WIDGET TREE ====================
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ------------------ 1. LEFT COLUMN: REDCLIFFE'S EXISTING SYSTEMS ------------------
                              SizedBox(
                                width: leftW,
                                height: totalH,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: cardBorder, width: 1.4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableTextElement(
                                        elementKey: 'left_sys_header',
                                        label: 'Left Systems Header',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('left_sys_header', "REDCLIFFE'S EXISTING SYSTEMS"),
                                          style: TextStyle(
                                            color: blueAccent,
                                            fontSize: slide.getFontSize('left_sys_header', 18.0),
                                            fontWeight: slide.getFontWeight('left_sys_header', FontWeight.w900),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: existingSystems.map((item) {
                                            final prefix = item['prefix'] as String;
                                            final iconData = item['icon'] as IconData;

                                            return Row(
                                              children: [
                                                Container(
                                                  width: 54,
                                                  height: 54,
                                                  decoration: BoxDecoration(
                                                    color: blueBgSoft,
                                                    borderRadius: BorderRadius.circular(18),
                                                  ),
                                                  child: Icon(
                                                    iconData,
                                                    size: 29,
                                                    color: blueAccent,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SelectableTextElement(
                                                        elementKey: '${prefix}_title',
                                                        label: 'System Title',
                                                        selectedElementKey: renderContext.selectedElementKey,
                                                        onSelectElement: renderContext.onSelectElement,
                                                        child: Text(
                                                          slide.getElementText('${prefix}_title', item['title'] as String),
                                                          style: TextStyle(
                                                            color: textDark,
                                                            fontSize: slide.getFontSize('${prefix}_title', 18.5),
                                                            fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.bold),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      SelectableTextElement(
                                                        elementKey: '${prefix}_desc',
                                                        label: 'System Description',
                                                        selectedElementKey: renderContext.selectedElementKey,
                                                        onSelectElement: renderContext.onSelectElement,
                                                        child: Text(
                                                          slide.getElementText('${prefix}_desc', item['desc'] as String),
                                                          style: TextStyle(
                                                            color: textMuted,
                                                            fontSize: slide.getFontSize('${prefix}_desc', 15.0),
                                                            fontWeight: FontWeight.w500,
                                                            height: 1.2,
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
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(width: gap1W),

                              // ------------------ 2. CENTER COLUMN: WELLNESSGPT & AGENTS ------------------
                              SizedBox(
                                width: centerW,
                                height: totalH,
                                child: Column(
                                  children: [
                                    // Upper WellnessGPT Container
                                    SizedBox(
                                      height: totalH * 0.67,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isLight ? const Color(0xFFFBFBFD) : const Color(0xFF261E38),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: isLight ? const Color(0xFFDDD6FE) : const Color(0xFF4C1D95),
                                            width: 1.4,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            // Header Title: WELLNESSGPT
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SelectableTextElement(
                                                  elementKey: 'wellness_title',
                                                  label: 'WellnessGPT Title',
                                                  selectedElementKey: renderContext.selectedElementKey,
                                                  onSelectElement: renderContext.onSelectElement,
                                                  child: Text(
                                                    'WELLNESSGPT',
                                                    style: TextStyle(
                                                      color: purpleAccent,
                                                      fontSize: slide.getFontSize('wellness_title', 27.0),
                                                      fontWeight: slide.getFontWeight('wellness_title', FontWeight.w900),
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.auto_awesome,
                                                  size: 26,
                                                  color: Color(0xFF7C3AED),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // Center AI Graphic + 3 Left Caps + 3 Right Caps Row
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  // Left 3 Capabilities
                                                  Expanded(
                                                    flex: 32,
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: leftCaps.map((item) {
                                                        final prefix = item['prefix'] as String;
                                                        final iconData = item['icon'] as IconData;

                                                        return Row(
                                                          children: [
                                                            Container(
                                                              width: 48,
                                                              height: 48,
                                                              decoration: BoxDecoration(
                                                                color: isLight ? const Color(0xFFEDE9FE) : const Color(0xFF372A54),
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: Icon(
                                                                iconData,
                                                                size: 24,
                                                                color: purpleAccent,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 10),
                                                            Expanded(
                                                              child: ConstrainedBox(
                                                                constraints: const BoxConstraints(maxWidth: 185),
                                                                child: SelectableTextElement(
                                                                  elementKey: '${prefix}_title',
                                                                  label: 'Cap Title',
                                                                  selectedElementKey: renderContext.selectedElementKey,
                                                                  onSelectElement: renderContext.onSelectElement,
                                                                  child: Text(
                                                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                                                    style: TextStyle(
                                                                      color: textDark,
                                                                      fontSize: slide.getFontSize('${prefix}_title', 15.5),
                                                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w700),
                                                                      height: 1.18,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),

                                                  // Center AI Brain Image Graphic
                                                  Expanded(
                                                    flex: 36,
                                                    child: Center(
                                                      child: SizedBox(
                                                        width: 150,
                                                        height: 150,
                                                        child: Image.asset(
                                                          'assets/hero/brain.png',
                                                          fit: BoxFit.contain,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              width: 150,
                                                              height: 150,
                                                              decoration: const BoxDecoration(
                                                                color: Color(0xFF6366F1),
                                                                shape: BoxShape.circle,
                                                              ),
                                                              alignment: Alignment.center,
                                                              child: const Text(
                                                                'AI',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 36,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Right 3 Capabilities
                                                  Expanded(
                                                    flex: 32,
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: rightCaps.map((item) {
                                                        final prefix = item['prefix'] as String;
                                                        final iconData = item['icon'] as IconData;

                                                        return Row(
                                                          children: [
                                                            Container(
                                                              width: 48,
                                                              height: 48,
                                                              decoration: BoxDecoration(
                                                                color: isLight ? const Color(0xFFEDE9FE) : const Color(0xFF372A54),
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: Icon(
                                                                iconData,
                                                                size: 24,
                                                                color: purpleAccent,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 10),
                                                            Expanded(
                                                              child: ConstrainedBox(
                                                                constraints: const BoxConstraints(maxWidth: 185),
                                                                child: SelectableTextElement(
                                                                  elementKey: '${prefix}_title',
                                                                  label: 'Cap Title',
                                                                  selectedElementKey: renderContext.selectedElementKey,
                                                                  onSelectElement: renderContext.onSelectElement,
                                                                  child: Text(
                                                                    slide.getElementText('${prefix}_title', item['title'] as String),
                                                                    style: TextStyle(
                                                                      color: textDark,
                                                                      fontSize: slide.getFontSize('${prefix}_title', 15.5),
                                                                      fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w700),
                                                                      height: 1.18,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const Spacer(),

                                    // Lower 5 Specialized Agents Row
                                    SizedBox(
                                      height: totalH * 0.26,
                                      child: Row(
                                        children: bottomAgents.asMap().entries.map((entry) {
                                          final idx = entry.key;
                                          final item = entry.value;
                                          final prefix = item['prefix'] as String;
                                          final iconData = item['icon'] as IconData;

                                          return Expanded(
                                            child: Container(
                                              margin: EdgeInsets.only(right: idx == bottomAgents.length - 1 ? 0 : 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: cardBg,
                                                borderRadius: BorderRadius.circular(18),
                                                border: Border.all(color: cardBorder, width: 1.2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      color: purpleBgSoft,
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: Icon(
                                                      iconData,
                                                      size: 25,
                                                      color: purpleAccent,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SelectableTextElement(
                                                    elementKey: '${prefix}_title',
                                                    label: 'Agent Title',
                                                    selectedElementKey: renderContext.selectedElementKey,
                                                    onSelectElement: renderContext.onSelectElement,
                                                    child: Text(
                                                      slide.getElementText('${prefix}_title', item['title'] as String),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: textDark,
                                                        fontSize: slide.getFontSize('${prefix}_title', 15.5),
                                                        fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.bold),
                                                        height: 1.15,
                                                      ),
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
                                ),
                              ),

                              SizedBox(width: gap2W),

                              // ------------------ 3. RIGHT COLUMN: PEOPLE & OUTCOMES ------------------
                              SizedBox(
                                width: rightW,
                                height: totalH,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: cardBorder, width: 1.4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableTextElement(
                                        elementKey: 'right_out_header',
                                        label: 'Right Outcomes Header',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('right_out_header', 'PEOPLE & OUTCOMES'),
                                          style: TextStyle(
                                            color: tealAccent,
                                            fontSize: slide.getFontSize('right_out_header', 18.0),
                                            fontWeight: slide.getFontWeight('right_out_header', FontWeight.w900),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: outcomes.map((item) {
                                            final prefix = item['prefix'] as String;
                                            final iconData = item['icon'] as IconData;

                                            return Row(
                                              children: [
                                                Container(
                                                  width: 54,
                                                  height: 54,
                                                  decoration: BoxDecoration(
                                                    color: tealBgSoft,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    iconData,
                                                    size: 29,
                                                    color: tealAccent,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SelectableTextElement(
                                                        elementKey: '${prefix}_title',
                                                        label: 'Outcome Title',
                                                        selectedElementKey: renderContext.selectedElementKey,
                                                        onSelectElement: renderContext.onSelectElement,
                                                        child: Text(
                                                          slide.getElementText('${prefix}_title', item['title'] as String),
                                                          style: TextStyle(
                                                            color: tealAccent,
                                                            fontSize: slide.getFontSize('${prefix}_title', 18.0),
                                                            fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.bold),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      SelectableTextElement(
                                                        elementKey: '${prefix}_desc',
                                                        label: 'Outcome Description',
                                                        selectedElementKey: renderContext.selectedElementKey,
                                                        onSelectElement: renderContext.onSelectElement,
                                                        child: Text(
                                                          slide.getElementText('${prefix}_desc', item['desc'] as String),
                                                          style: TextStyle(
                                                            color: textMuted,
                                                            fontSize: slide.getFontSize('${prefix}_desc', 15.0),
                                                            fontWeight: FontWeight.w500,
                                                            height: 1.2,
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
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
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

/// Custom painter for Left System dots converging via smooth curved lines to Center WellnessGPT trunk
class _LeftSystemToCenterPainter extends CustomPainter {
  final Color color;
  final int count;

  _LeftSystemToCenterPainter({required this.color, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final trunkX = size.width * 0.50;
    final endX = size.width;
    final cornerRadius = 6.0;
    final dotRadius = 4.0;
    final dashWidth = 4.0;
    final dashSpace = 3.0;

    // Header offset inside Left Card: top padding (18) + title font (18) + header gap (10) = 46px
    final topOffset = 46.0;
    final bottomOffset = 18.0;
    final availableH = size.height - topOffset - bottomOffset;
    final stepY = availableH / count;

    // Y positions aligned 100% dead-center to each of the 6 left items
    final inputYs = List.generate(count, (i) => topOffset + (i + 0.5) * stepY);

    // Single central output Y aligned with vertical center of upper WellnessGPT card
    final centerCardY = size.height * 0.335;

    // 1. Draw 6 Left Input Lines turning with rounded corners into vertical trunk at trunkX
    for (int i = 0; i < count; i++) {
      final y = inputYs[i];

      // Left Node Dot on item edge
      canvas.drawCircle(Offset(0, y), dotRadius, dotPaint);

      final path = Path();
      path.moveTo(0, y);
      path.lineTo(trunkX - cornerRadius, y);

      // Turn direction towards centerCardY
      if (y < centerCardY) {
        // Upper lines turn downwards into trunk
        path.quadraticBezierTo(trunkX, y, trunkX, y + cornerRadius);
      } else {
        // Lower lines turn upwards into trunk
        path.quadraticBezierTo(trunkX, y, trunkX, y - cornerRadius);
      }

      _drawDashedPath(canvas, path, linePaint, dashWidth, dashSpace);
    }

    // 2. Continuous Vertical Spine/Trunk Line at trunkX
    final spinePath = Path()
      ..moveTo(trunkX, inputYs[0] + cornerRadius)
      ..lineTo(trunkX, inputYs[count - 1] - cornerRadius);
    _drawDashedPath(canvas, spinePath, linePaint, dashWidth, dashSpace);

    // 3. Single Central Output Line going right from trunkX to endX at centerCardY
    final pathOut = Path()
      ..moveTo(trunkX, centerCardY)
      ..lineTo(endX, centerCardY);
    _drawDashedPath(canvas, pathOut, linePaint, dashWidth, dashSpace);

    // Single Output Node Dot on WellnessGPT card edge
    canvas.drawCircle(Offset(endX, centerCardY), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LeftSystemToCenterPainter oldDelegate) => oldDelegate.color != color;
}

/// Custom painter for Center WellnessGPT trunk splitting via smooth curved lines into 4 Right Outcome dots
class _CenterToRightOutcomesPainter extends CustomPainter {
  final Color color;
  final int count;

  _CenterToRightOutcomesPainter({required this.color, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final startX = 0.0;
    final trunkX = size.width * 0.50;
    final endX = size.width;
    final cornerRadius = 6.0;
    final dotRadius = 4.0;
    final dashWidth = 4.0;
    final dashSpace = 3.0;

    // Header offset inside Right Card: top padding (18) + title font (18) + header gap (10) = 46px
    final topOffset = 46.0;
    final bottomOffset = 18.0;
    final availableH = size.height - topOffset - bottomOffset;
    final stepY = availableH / count;

    // Y positions of 4 Right Outcomes
    final outputYs = List.generate(count, (i) => topOffset + (i + 0.5) * stepY);

    // Single central input Y aligned with vertical center of upper WellnessGPT card
    final centerCardY = size.height * 0.335;

    // 1. Single Input Trunk Line from WellnessGPT right edge directly to trunkX
    canvas.drawCircle(Offset(startX, centerCardY), dotRadius, dotPaint);

    final pathIn = Path()
      ..moveTo(startX, centerCardY)
      ..lineTo(trunkX, centerCardY);
    _drawDashedPath(canvas, pathIn, linePaint, dashWidth, dashSpace);

    // 2. Continuous Vertical Spine Line at trunkX
    final spinePath = Path()
      ..moveTo(trunkX, outputYs[0] + cornerRadius)
      ..lineTo(trunkX, outputYs[count - 1] - cornerRadius);
    _drawDashedPath(canvas, spinePath, linePaint, dashWidth, dashSpace);

    // 3. 4 Output Lines turning with rounded corners from trunkX to 4 Outcome item dots on right
    for (int i = 0; i < count; i++) {
      final y = outputYs[i];

      final path = Path();
      if (y < centerCardY) {
        // Upper lines turn upwards from trunk to right
        path.moveTo(trunkX, y + cornerRadius);
        path.quadraticBezierTo(trunkX, y, trunkX + cornerRadius, y);
      } else {
        // Lower lines turn downwards from trunk to right
        path.moveTo(trunkX, y - cornerRadius);
        path.quadraticBezierTo(trunkX, y, trunkX + cornerRadius, y);
      }
      path.lineTo(endX, y);
      _drawDashedPath(canvas, path, linePaint, dashWidth, dashSpace);

      // Right Node Dot aligned dead center to outcome item
      canvas.drawCircle(Offset(endX, y), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CenterToRightOutcomesPainter oldDelegate) => oldDelegate.color != color;
}

/// Helper to render any Path with uniform dash width and dash space, seamlessly emerging from dots
void _drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint,
  double dashWidth,
  double dashSpace, {
  bool startSolid = true,
}) {
  for (final metric in path.computeMetrics()) {
    double distance = 0.0;
    if (startSolid && metric.length > 0) {
      final firstLength = (dashWidth + 3.0).clamp(0.0, metric.length);
      final firstPath = metric.extractPath(0.0, firstLength);
      canvas.drawPath(firstPath, paint);
      distance = firstLength + dashSpace;
    }
    while (distance < metric.length) {
      final extractLength = (distance + dashWidth).clamp(0.0, metric.length);
      final extractPath = metric.extractPath(distance, extractLength);
      canvas.drawPath(extractPath, paint);
      distance += dashWidth + dashSpace;
    }
  }
}

/// Custom painter for Center WellnessGPT bottom splitting into 5 Agents
class _CenterToBottomAgentsPainter extends CustomPainter {
  final Color color;
  final int count;

  _CenterToBottomAgentsPainter({required this.color, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final branchY = size.height * 0.45;
    final endY = size.height;
    final cornerRadius = 12.0;
    final dotRadius = 4.0;
    final dashWidth = 5.0;
    final dashSpace = 3.5;

    final stepX = size.width / count;

    // Top Stem Dot at WellnessGPT bottom edge
    canvas.drawCircle(Offset(centerX, 0), dotRadius, dotPaint);

    // 5 Curved & Dashed Branching Lines to each agent top edge
    for (int i = 0; i < count; i++) {
      final agentX = (i + 0.5) * stepX;
      final path = Path();

      if ((agentX - centerX).abs() < 1.0) {
        // Middle agent (index 2): straight vertical line down
        path.moveTo(centerX, 0);
        path.lineTo(centerX, endY);
      } else if (agentX < centerX) {
        // Left agents (indices 0, 1): turn left at branchY, then turn down at agentX
        path.moveTo(centerX, 0);
        path.lineTo(centerX, branchY - cornerRadius);
        path.quadraticBezierTo(centerX, branchY, centerX - cornerRadius, branchY);
        path.lineTo(agentX + cornerRadius, branchY);
        path.quadraticBezierTo(agentX, branchY, agentX, branchY + cornerRadius);
        path.lineTo(agentX, endY);
      } else {
        // Right agents (indices 3, 4): turn right at branchY, then turn down at agentX
        path.moveTo(centerX, 0);
        path.lineTo(centerX, branchY - cornerRadius);
        path.quadraticBezierTo(centerX, branchY, centerX + cornerRadius, branchY);
        path.lineTo(agentX - cornerRadius, branchY);
        path.quadraticBezierTo(agentX, branchY, agentX, branchY + cornerRadius);
        path.lineTo(agentX, endY);
      }

      _drawDashedPath(canvas, path, linePaint, dashWidth, dashSpace);

      // Agent top node dot
      canvas.drawCircle(Offset(agentX, endY), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CenterToBottomAgentsPainter oldDelegate) => oldDelegate.color != color;
}
