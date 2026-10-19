import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "From Vision AI to Coach Intelligence"
class VisionAiToCoachIntelligenceSlide extends BaseSlide {
  @override
  String get type => 'vision_ai_to_coach_intelligence';

  @override
  String get displayName => 'From Vision AI to Coach Intelligence';

  @override
  Widget build(SlideRenderContext context) {
    return _VisionAiToCoachIntelligenceWidget(renderContext: context);
  }
}

class _VisionAiToCoachIntelligenceWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _VisionAiToCoachIntelligenceWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    final purpleHeaderColor = const Color(0xFF4F46E5);

    final outcomeIconColors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF0D9488), // Teal
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFEA580C), // Orange
      const Color(0xFF16A34A), // Green
    ];

    final outcomeBgColors = isLight
        ? [
            const Color(0xFFEFF6FF),
            const Color(0xFFCCFBF1),
            const Color(0xFFF3F0FF),
            const Color(0xFFFFF7ED),
            const Color(0xFFDCFCE7),
          ]
        : [
            const Color(0xFF1E293B),
            const Color(0xFF132A22),
            const Color(0xFF261E38),
            const Color(0xFF3B2A1A),
            const Color(0xFF143823),
          ];

    final outcomeIcons = [
      Icons.track_changes_rounded,
      Icons.bar_chart_rounded,
      Icons.monitor_heart_rounded,
      Icons.access_time_rounded,
      Icons.check_circle_rounded,
    ];

    // Data parsing for 6 Cards from JSON
    final rawCards = (slide.rawContent['cards'] as List?) ?? [];
    final cards = (rawCards.isNotEmpty)
        ? rawCards.asMap().entries.map((entry) {
            final idx = entry.key;
            final Map item = entry.value is Map ? entry.value as Map : {};
            return {
              "step": item['step']?.toString() ?? '',
              "title": item['title']?.toString() ?? '',
              "image_key": item['image_key']?.toString() ?? 'card_image_$idx',
              "headline": item['headline']?.toString() ?? '',
              "body": item['body']?.toString() ?? '',
              "prefix": "card_${idx + 1}",
            };
          }).toList()
        : List.generate(
            6,
            (idx) => {
              "step": '',
              "title": '',
              "image_key": 'card_image_$idx',
              "headline": '',
              "body": '',
              "prefix": "card_${idx + 1}",
            },
          );

    // Data parsing for Bottom Banner from JSON
    final rawBanner = (slide.rawContent['bottom_banner'] as Map?) ?? {};
    final bannerTitle = rawBanner['title']?.toString() ?? '';
    final bannerSubtitle = rawBanner['subtitle']?.toString() ?? '';
    final rawOutcomes = (rawBanner['outcomes'] as List?) ?? [];
    final outcomes = rawOutcomes.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['description']?.toString() ?? '',
        "icon": outcomeIcons[idx % outcomeIcons.length],
        "color": outcomeIconColors[idx % outcomeIconColors.length],
        "bg": outcomeBgColors[idx % outcomeBgColors.length],
        "prefix": "out_${idx + 1}",
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 14),

        // 1. TOP ROW: 6 EQUAL-WIDTH CARDS WITH SQUARED & VERTICALLY CENTERED IMAGE DROPZONES
        Expanded(
          flex: 78,
          child: Row(
            children: [
              for (int idx = 0; idx < cards.length; idx++) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 40),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cardBorder, width: 1.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isLight ? 0.04 : 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top Section (Badge + Title) with fixed height for perfect alignment
                        SizedBox(
                          height: 88,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Step Badge Number
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cards[idx]['step'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Step Title
                              SelectableTextElement(
                                elementKey: '${cards[idx]['prefix']}_title',
                                label: 'Card ${idx + 1} Title',
                                selectedElementKey:
                                    renderContext.selectedElementKey,
                                onSelectElement: renderContext.onSelectElement,
                                child: Text(
                                  slide.getElementText(
                                      '${cards[idx]['prefix']}_title',
                                      cards[idx]['title'] as String),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: purpleHeaderColor,
                                    fontSize: slide.getFontSize(
                                        '${cards[idx]['prefix']}_title', 17.0),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Middle: Squared Image vertically centered in remaining space
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: ImageDropzoneWidget(
                                  slideId: slide.id,
                                  imageKey: cards[idx]['image_key'] as String,
                                  companyName: renderContext.companyName,
                                  label: 'Image ${idx + 1}',
                                  formatHint: '1:1',
                                  height: double.infinity,
                                  initialImagePath: slide.getImagePath(
                                      cards[idx]['image_key'] as String),
                                  folderPath: renderContext.folderPath,
                                  onImageSelected: (path) {
                                    if (renderContext.onImageChanged != null) {
                                      renderContext.onImageChanged!(
                                          cards[idx]['image_key'] as String,
                                          path);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Bottom Section (Headline + Body) with fixed height for perfect alignment
                        SizedBox(
                          height: 88,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Bold Headline Subtext
                              SelectableTextElement(
                                elementKey: '${cards[idx]['prefix']}_headline',
                                label: 'Card ${idx + 1} Headline',
                                selectedElementKey:
                                    renderContext.selectedElementKey,
                                onSelectElement: renderContext.onSelectElement,
                                child: Text(
                                  slide.getElementText(
                                      '${cards[idx]['prefix']}_headline',
                                      cards[idx]['headline'] as String),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: slide.getFontSize(
                                        '${cards[idx]['prefix']}_headline',
                                        16.5),
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Body Description Text
                              SelectableTextElement(
                                elementKey: '${cards[idx]['prefix']}_body',
                                label: 'Card ${idx + 1} Body',
                                selectedElementKey:
                                    renderContext.selectedElementKey,
                                onSelectElement: renderContext.onSelectElement,
                                child: Text(
                                  slide.getElementText(
                                      '${cards[idx]['prefix']}_body',
                                      cards[idx]['body'] as String),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: slide.getFontSize(
                                        '${cards[idx]['prefix']}_body', 14.0),
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
                      ],
                    ),
                  ),
                ),

                // Flow Arrow Connector Line between Cards
                if (idx < cards.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 2,
                          color: const Color(0xFFCBD5E1),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF818CF8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFF818CF8),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. BOTTOM OUTCOMES BANNER
        Expanded(
          flex: 22,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFAFAFA) : const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF2E333D),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Left Header Part: Brain Icon + Title & Subtitle
                Expanded(
                  flex: 30,
                  child: Row(
                    children: [
                      // Brain / Intelligence Icon Circle
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F0FF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.psychology_rounded,
                          size: 28,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableTextElement(
                              elementKey: 'bottom_title',
                              label: 'Bottom Banner Title',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText(
                                    'bottom_title', bannerTitle),
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: slide.getFontSize(
                                      'bottom_title', 18.0),
                                  fontWeight: FontWeight.w900,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SelectableTextElement(
                              elementKey: 'bottom_sub',
                              label: 'Bottom Banner Subtitle',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText(
                                    'bottom_sub', bannerSubtitle),
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: slide.getFontSize(
                                      'bottom_sub', 13.5),
                                  fontWeight: FontWeight.w500,
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
                  width: 1.2,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: isLight
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFF333333),
                ),

                // Right Outcomes Part (5 items with matching icons)
                Expanded(
                  flex: 70,
                  child: Row(
                    children: outcomes.map((oItem) {
                      final prefix = oItem['prefix'] as String;
                      final iconData = oItem['icon'] as IconData;
                      final color = oItem['color'] as Color;
                      final bg = oItem['bg'] as Color;

                      return Expanded(
                        child: Row(
                          children: [
                            // Icon Circle
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: bg,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                iconData,
                                size: 20,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Text Column
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableTextElement(
                                    elementKey: '${prefix}_title',
                                    label: 'Outcome Title',
                                    selectedElementKey:
                                        renderContext.selectedElementKey,
                                    onSelectElement:
                                        renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText('${prefix}_title',
                                          oItem['title'] as String),
                                      style: TextStyle(
                                        color: textDark,
                                        fontSize: slide.getFontSize(
                                            '${prefix}_title', 15.0),
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableTextElement(
                                    elementKey: '${prefix}_desc',
                                    label: 'Outcome Desc',
                                    selectedElementKey:
                                        renderContext.selectedElementKey,
                                    onSelectElement:
                                        renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText('${prefix}_desc',
                                          oItem['desc'] as String),
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: slide.getFontSize(
                                            '${prefix}_desc', 12.5),
                                        fontWeight: FontWeight.w500,
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
