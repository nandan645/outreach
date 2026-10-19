import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "What Company Gains with WellnessGPT"
class WhatCompanyGainsSlide extends BaseSlide {
  @override
  String get type => 'what_company_gains';

  @override
  String get displayName => 'What Company Gains';

  @override
  Widget build(SlideRenderContext context) {
    return _WhatCompanyGainsWidget(renderContext: context);
  }
}

class _WhatCompanyGainsWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _WhatCompanyGainsWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    final cardConfigs = [
      {
        "primary": const Color(0xFF2563EB),
        "soft_bg": isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E293B),
        "bottom_bg": isLight ? const Color(0xFFF0F6FF) : const Color(0xFF182238),
        "key_outcome_icon": Icons.groups_rounded,
      },
      {
        "primary": const Color(0xFF7C3AED),
        "soft_bg": isLight ? const Color(0xFFF3F0FF) : const Color(0xFF2E1F4D),
        "bottom_bg": isLight ? const Color(0xFFF8F5FF) : const Color(0xFF251A3E),
        "key_outcome_icon": Icons.badge_rounded,
      },
      {
        "primary": const Color(0xFF0D9488),
        "soft_bg": isLight ? const Color(0xFFF0FDF4) : const Color(0xFF133629),
        "bottom_bg": isLight ? const Color(0xFFF2FDF7) : const Color(0xFF102E24),
        "key_outcome_icon": Icons.apartment_rounded,
      },
      {
        "primary": const Color(0xFFD97706),
        "soft_bg": isLight ? const Color(0xFFFFFBEB) : const Color(0xFF382A13),
        "bottom_bg": isLight ? const Color(0xFFFFFDF5) : const Color(0xFF2D2210),
        "key_outcome_icon": Icons.trending_up_rounded,
      },
    ];

    final cardsData = (slide.rawContent['cards'] as List<dynamic>? ?? []);
    final pilotData = (slide.rawContent['pilot_opportunity'] as Map<String, dynamic>? ?? {});
    final pilotSteps = (pilotData['steps'] as List<dynamic>? ?? []);

    final pilotIcons = [
      Icons.center_focus_strong_rounded,
      Icons.bar_chart_rounded,
      Icons.check_circle_outline_rounded,
      Icons.layers_outlined,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 14),

        // Main 4 Cards Row
        Expanded(
          flex: 74,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cardsData.asMap().entries.map((entry) {
                final idx = entry.key;
                final card = entry.value as Map<String, dynamic>;
                final config = cardConfigs[idx % cardConfigs.length];

                final primaryColor = config['primary'] as Color;
                final softBg = config['soft_bg'] as Color;
                final bottomBg = config['bottom_bg'] as Color;
                final outcomeIcon = config['key_outcome_icon'] as IconData;

                final imageKey = card['image_key'] as String? ?? 'gain_image_$idx';
                final title = card['title'] as String? ?? '';
                final subtitle = card['subtitle'] as String? ?? '';
                final bullets = (card['bullets'] as List<dynamic>? ?? []).cast<String>();
                final rawKeyOutcomes = card['key_outcomes'] ?? card['key_outcome'] ?? card['outcome'] ?? card['outcomes'];
                String outcomesTitle = '';
                String outcomesText = '';
                bool hasOutcome = false;

                if (rawKeyOutcomes is Map) {
                  hasOutcome = true;
                  final map = rawKeyOutcomes;
                  final rawTitle = map['title'] ?? map['label'] ?? map['heading'] ?? map['name'];
                  if (rawTitle != null && rawTitle.toString().trim().isNotEmpty) {
                    outcomesTitle = rawTitle.toString().trim();
                  } else {
                    outcomesTitle = 'KEY OUTCOMES';
                  }

                  outcomesText = (map['outcomes_text'] ??
                          map['outcomesText'] ??
                          map['text'] ??
                          map['value'] ??
                          map['description'] ??
                          map['outcome'] ??
                          map['detail'] ??
                          '')
                      .toString()
                      .trim();
                } else if (rawKeyOutcomes is String) {
                  hasOutcome = rawKeyOutcomes.trim().isNotEmpty;
                  outcomesTitle = 'KEY OUTCOMES';
                  outcomesText = rawKeyOutcomes.trim();
                } else if (rawKeyOutcomes is List) {
                  hasOutcome = rawKeyOutcomes.isNotEmpty;
                  outcomesTitle = 'KEY OUTCOMES';
                  outcomesText = rawKeyOutcomes.map((e) {
                    if (e is Map) {
                      return (e['text'] ?? e['value'] ?? e['title'] ?? e['name'] ?? e.toString()).toString().trim();
                    }
                    return e.toString().trim();
                  }).where((s) => s.isNotEmpty).join('  |  ');
                } else if (card.containsKey('outcomes_text') ||
                    card.containsKey('outcome_text') ||
                    card.containsKey('outcome') ||
                    card.containsKey('key_outcome') ||
                    card.containsKey('metrics') ||
                    card.containsKey('outcome_metrics')) {
                  outcomesTitle = 'KEY OUTCOMES';
                  outcomesText = (card['outcomes_text'] ??
                          card['outcome_text'] ??
                          card['outcome'] ??
                          card['key_outcome'] ??
                          card['metrics'] ??
                          card['outcome_metrics'] ??
                          '')
                      .toString()
                      .trim();
                  hasOutcome = outcomesText.isNotEmpty;
                }

                final outcomeOverride = slide.rawContent['text_overrides']?['card_${idx + 1}_outcome_text']?.toString();
                if (outcomeOverride != null && outcomeOverride.trim().isNotEmpty) {
                  hasOutcome = true;
                  if (outcomesTitle.isEmpty) outcomesTitle = 'KEY OUTCOMES';
                }

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: idx < cardsData.length - 1 ? 16 : 0),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cardBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Illustration Dropzone Box (9:4 ratio)
                        AspectRatio(
                          aspectRatio: 9 / 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: softBg,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ImageDropzoneWidget(
                              slideId: slide.id,
                              imageKey: imageKey,
                              companyName: renderContext.companyName,
                              label: 'Upload Illustration',
                              formatHint: 'Image / Asset',
                              initialImagePath: slide.getImagePath(imageKey),
                              folderPath: renderContext.folderPath,
                              onImageSelected: (path) {
                                if (renderContext.onImageChanged != null) {
                                  renderContext.onImageChanged!(imageKey, path);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title with Vertical Accent Line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4.5,
                              height: 26,
                              margin: const EdgeInsets.only(right: 10, top: 2),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Expanded(
                              child: SelectableTextElement(
                                elementKey: 'card_${idx + 1}_title',
                                label: 'Card ${idx + 1} Title',
                                selectedElementKey: renderContext.selectedElementKey,
                                onSelectElement: renderContext.onSelectElement,
                                child: Text(
                                  slide.getElementText('card_${idx + 1}_title', title),
                                  style: TextStyle(
                                    fontSize: slide.getFontSize('card_${idx + 1}_title', 22.0),
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        SelectableTextElement(
                          elementKey: 'card_${idx + 1}_subtitle',
                          label: 'Card ${idx + 1} Subtitle',
                          selectedElementKey: renderContext.selectedElementKey,
                          onSelectElement: renderContext.onSelectElement,
                          child: Text(
                            slide.getElementText('card_${idx + 1}_subtitle', subtitle),
                            style: TextStyle(
                              fontSize: slide.getFontSize('card_${idx + 1}_subtitle', 15.0),
                              color: textMuted,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Bullet Points
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: bullets.asMap().entries.map((bEntry) {
                              final bIdx = bEntry.key;
                              final bullet = bEntry.value;
                              final bulletKey = 'card_${idx + 1}_bullet_${bIdx + 1}';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(top: 7, right: 10),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: SelectableTextElement(
                                        elementKey: bulletKey,
                                        label: 'Card ${idx + 1} Point ${bIdx + 1}',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText(bulletKey, bullet),
                                          style: TextStyle(
                                            fontSize: slide.getFontSize(bulletKey, 15.0),
                                            color: textDark.withValues(alpha: 0.9),
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        if (hasOutcome) ...[
                          const SizedBox(height: 10),
                          // Key Outcomes Box at Bottom of Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: bottomBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.18),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: SelectableIconElement(
                                    elementKey: 'card_${idx + 1}_outcome_icon',
                                    label: 'Card ${idx + 1} Outcome Icon',
                                    icon: slide.getIcon('card_${idx + 1}_outcome_icon', outcomeIcon),
                                    size: slide.getFontSize('card_${idx + 1}_outcome_icon', 20.0),
                                    color: primaryColor,
                                    selectedElementKey: renderContext.selectedElementKey,
                                    onSelectElement: renderContext.onSelectElement,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SelectableTextElement(
                                        elementKey: 'card_${idx + 1}_outcome_title',
                                        label: 'Card ${idx + 1} Outcome Header',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText('card_${idx + 1}_outcome_title', outcomesTitle.toUpperCase()),
                                          style: TextStyle(
                                            fontSize: slide.getFontSize('card_${idx + 1}_outcome_title', 12.0),
                                            fontWeight: slide.getFontWeight('card_${idx + 1}_outcome_title', FontWeight.bold),
                                            color: primaryColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      SelectableTextElement(
                                        elementKey: 'card_${idx + 1}_outcome_text',
                                        label: 'Card ${idx + 1} Outcome Text',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText(
                                            'card_${idx + 1}_outcome_text',
                                            outcomesText,
                                          ),
                                          style: TextStyle(
                                            fontSize: slide.getFontSize('card_${idx + 1}_outcome_text', 14.5),
                                            fontWeight: slide.getFontWeight('card_${idx + 1}_outcome_text', FontWeight.w600),
                                            color: textDark,
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
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Banner Section (Pilot Opportunity)
          Expanded(
            flex: 26,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cardBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left Side: Image Dropzone + Title & Subtitle
                  Expanded(
                    flex: 52,
                    child: Row(
                      children: [
                        // Beaker / Pilot Image Dropzone Box
                        SizedBox(
                          width: 74,
                          height: 74,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isLight
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ImageDropzoneWidget(
                              slideId: slide.id,
                              imageKey: 'pilot_image_0',
                              companyName: renderContext.companyName,
                              label: 'Upload',
                              formatHint: 'Icon',
                              height: 74,
                              initialImagePath: slide.getImagePath('pilot_image_0'),
                              folderPath: renderContext.folderPath,
                              onImageSelected: (path) {
                                if (renderContext.onImageChanged != null) {
                                  renderContext.onImageChanged!('pilot_image_0', path);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 0, width: 16),

                        // Opportunity Text Column
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableTextElement(
                                elementKey: 'pilot_label',
                                label: 'Pilot Label',
                                selectedElementKey: renderContext.selectedElementKey,
                                onSelectElement: renderContext.onSelectElement,
                                child: Text(
                                  slide.getElementText(
                                    'pilot_label',
                                    (pilotData['label'] as String? ?? '').toUpperCase(),
                                  ),
                                  style: TextStyle(
                                    fontSize: slide.getFontSize('pilot_label', 13.0),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4F46E5),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              SelectableTextElement(
                                elementKey: 'pilot_title',
                                label: 'Pilot Title',
                                selectedElementKey: renderContext.selectedElementKey,
                                onSelectElement: renderContext.onSelectElement,
                                child: Text(
                                  slide.getElementText(
                                    'pilot_title',
                                    pilotData['title'] as String? ?? '',
                                  ),
                                  style: TextStyle(
                                    fontSize: slide.getFontSize('pilot_title', 19.0),
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 3),
                              SelectableTextElement(
                                elementKey: 'pilot_subtitle',
                                label: 'Pilot Subtitle',
                                selectedElementKey: renderContext.selectedElementKey,
                                onSelectElement: renderContext.onSelectElement,
                                child: Text(
                                  slide.getElementText(
                                    'pilot_subtitle',
                                    pilotData['subtitle'] as String? ?? '',
                                  ),
                                  style: TextStyle(
                                    fontSize: slide.getFontSize('pilot_subtitle', 15.0),
                                    color: textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: cardBorder,
                  ),

                  // Right Side: 4 Pilot Steps Flow
                  Expanded(
                    flex: 48,
                    child: Row(
                      children: pilotSteps.asMap().entries.map((stepEntry) {
                        final sIdx = stepEntry.key;
                        final stepObj = stepEntry.value as Map<String, dynamic>;
                        final isLastStep = sIdx == pilotSteps.length - 1;
                        final stepIcon = pilotIcons[sIdx % pilotIcons.length];

                        final stepName = stepObj['step_name'] as String? ?? '';
                        final stepDesc = stepObj['step_desc'] as String? ?? '';
                        final stepNameKey = 'pilot_step_${sIdx + 1}_name';
                        final stepDescKey = 'pilot_step_${sIdx + 1}_desc';

                        return Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isLight
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        stepIcon,
                                        size: 22,
                                        color: const Color(0xFF4F46E5),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableTextElement(
                                      elementKey: stepNameKey,
                                      label: 'Step ${sIdx + 1} Name',
                                      selectedElementKey: renderContext.selectedElementKey,
                                      onSelectElement: renderContext.onSelectElement,
                                      child: Text(
                                        slide.getElementText(
                                          stepNameKey,
                                          stepName.toUpperCase(),
                                        ),
                                        style: TextStyle(
                                          fontSize: slide.getFontSize(stepNameKey, 13.0),
                                          fontWeight: FontWeight.bold,
                                          color: isLight
                                              ? const Color(0xFF4F46E5)
                                              : const Color(0xFF818CF8),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SelectableTextElement(
                                      elementKey: stepDescKey,
                                      label: 'Step ${sIdx + 1} Desc',
                                      selectedElementKey: renderContext.selectedElementKey,
                                      onSelectElement: renderContext.onSelectElement,
                                      child: Text(
                                        slide.getElementText(
                                          stepDescKey,
                                          stepDesc,
                                        ),
                                        style: TextStyle(
                                          fontSize: slide.getFontSize(stepDescKey, 13.0),
                                          color: textMuted,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLastStep)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Color(0xFF94A3B8),
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
