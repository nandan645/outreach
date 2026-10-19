import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

class ThreeStageProcessSlide extends BaseSlide {
  @override
  String get type => 'three_stage_process';

  @override
  String get displayName => 'Three Stage Process';

  @override
  Widget build(SlideRenderContext renderContext) {
    final slide = renderContext.slide;
    final List stages = (slide.rawContent['stages'] as List?) ?? [];

    return Builder(
      builder: (context) {
        final isLight = Theme.of(context).brightness == Brightness.light;

        final stageThemes = [
          {
            'tagColor': const Color(0xFFD97706),
            'gradientColors': isLight
                ? [const Color(0xFFFDE68A), const Color(0xFFFEF3C7).withValues(alpha: 0.15)]
                : [const Color(0xFF785E1A), const Color(0xFF382F18).withValues(alpha: 0.2)],
            'badgeBg': const Color(0xFFF59E0B),
          },
          {
            'tagColor': const Color(0xFFEF4444),
            'gradientColors': isLight
                ? [const Color(0xFFFCA5A5), const Color(0xFFFEE2E2).withValues(alpha: 0.15)]
                : [const Color(0xFF7F2929), const Color(0xFF3A1E1E).withValues(alpha: 0.2)],
            'badgeBg': const Color(0xFFEF4444),
          },
          {
            'tagColor': const Color(0xFF3B82F6),
            'gradientColors': isLight
                ? [const Color(0xFF93C5FD), const Color(0xFFDBEAFE).withValues(alpha: 0.15)]
                : [const Color(0xFF1E40AF), const Color(0xFF1B2B45).withValues(alpha: 0.2)],
            'badgeBg': const Color(0xFF3B82F6),
          },
          {
            'tagColor': const Color(0xFF10B981),
            'gradientColors': isLight
                ? [const Color(0xFF6EE7B7), const Color(0xFFD1FAE5).withValues(alpha: 0.15)]
                : [const Color(0xFF065F46), const Color(0xFF18382B).withValues(alpha: 0.2)],
            'badgeBg': const Color(0xFF10B981),
          },
        ];

        final numStages = stages.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            renderContext.buildTitleHeader(context),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stages.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stage = entry.value is Map ? entry.value as Map : {};

                    final theme = stageThemes[idx % stageThemes.length];
                    final tagColor = theme['tagColor'] as Color;
                    final gradientColors = theme['gradientColors'] as List<Color>;
                    final badgeBg = theme['badgeBg'] as Color;

                    double topOffset = 0.0;
                    if (numStages == 3) {
                      if (idx == 0) {
                        topOffset = 240.0;
                      } else if (idx == 1) {
                        topOffset = 120.0;
                      } else {
                        topOffset = 0.0;
                      }
                    } else if (numStages > 1) {
                      topOffset = (numStages - 1 - idx) * 120.0;
                    }

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: idx == 0 ? 0 : 20.0,
                          right: idx == numStages - 1 ? 0 : 20.0,
                          top: topOffset,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 88,
                              height: 420,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: gradientColors,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: badgeBg.withValues(alpha: 0.45),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: SelectableIconElement(
                                      elementKey: 'process_icon_$idx',
                                      label: 'Stage Arrow',
                                      icon: slide.getIcon('process_icon_$idx', Icons.arrow_forward),
                                      size: slide.getFontSize('process_icon_$idx', 34.0),
                                      color: Colors.white,
                                      selectedElementKey: renderContext.selectedElementKey,
                                      onSelectElement: renderContext.onSelectElement,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SelectableTextElement(
                                    elementKey: 'diagram_label_$idx',
                                    label: 'Stage Tag Header',
                                    selectedElementKey: renderContext.selectedElementKey,
                                    onSelectElement: renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText(
                                        'diagram_label_$idx',
                                        stage['label']?.toString() ?? 'STAGE ${idx + 1}',
                                      ).toUpperCase(),
                                      style: TextStyle(
                                        color: tagColor,
                                        fontSize: slide.getFontSize('diagram_label_$idx', 22.0),
                                        fontWeight: slide.getFontWeight('diagram_label_$idx', FontWeight.w800),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SelectableTextElement(
                                    elementKey: 'card_title_$idx',
                                    label: 'Stage Header',
                                    selectedElementKey: renderContext.selectedElementKey,
                                    onSelectElement: renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText(
                                        'card_title_$idx',
                                        stage['title']?.toString() ?? '',
                                      ),
                                      style: TextStyle(
                                        color: isLight ? const Color(0xFF111827) : Colors.white,
                                        fontSize: slide.getFontSize('card_title_$idx', 24.0),
                                        fontWeight: slide.getFontWeight('card_title_$idx', FontWeight.bold),
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: SelectableTextElement(
                                        elementKey: 'body_$idx',
                                        label: 'Stage Description',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText(
                                            'body_$idx',
                                            stage['description']?.toString() ?? '',
                                          ),
                                          style: TextStyle(
                                            color: isLight ? const Color(0xFF4B5563) : const Color(0xFFCCCCCC),
                                            fontSize: slide.getFontSize('body_$idx', 17.5),
                                            fontWeight: slide.getFontWeight('body_$idx', FontWeight.normal),
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ),
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
            ),
          ],
        );
      },
    );
  }
}
