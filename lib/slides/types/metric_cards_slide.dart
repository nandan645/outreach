import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

class MetricCardsSlide extends BaseSlide {
  @override
  String get type => 'metric_cards';

  @override
  String get displayName => 'Metric Cards';

  @override
  Widget build(SlideRenderContext renderContext) {
    return Builder(
      builder: (context) => _buildDefaultTemplate(context, renderContext),
    );
  }


  // Template 1: Default Grid with Card Containers & Bottom Banner (1920x1080 Proportional Canvas)
  Widget _buildDefaultTemplate(BuildContext context, SlideRenderContext renderContext) {
    final slide = renderContext.slide;
    final companyName = (renderContext.companyName != null && renderContext.companyName!.isNotEmpty)
        ? renderContext.companyName!
        : 'Redcliffe';

    final List metrics = slide.rawContent['metrics'] as List? ?? [
      {
        "title": "Annual Patients Served",
        "value": "2.5M+",
        "description": "A vast pool of recurring health data ready for longitudinal engagement."
      },
      {
        "title": "Home Collection Coverage",
        "value": "220+ Cities",
        "description": "Seamless physical reach combined with digital-first patient convenience."
      },
      {
        "title": "Lab Network",
        "value": "2.5M+",
        "description": "Extensive diagnostic infrastructure generating high-fidelity health profiles."
      },
      {
        "title": "Collection Centres",
        "value": "2000+",
        "description": "Nationwide touchpoints capturing key regional patient demographics."
      },
      {
        "title": "Corporate Partners",
        "value": "500+",
        "description": "Enterprise wellness opportunities ready for automated health navigation."
      },
    ];

    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF222224);
    final cardBorder = isLight ? const Color(0xFFECEFF2) : const Color(0xFF333333);

    final pastelColors = isLight
        ? [
            const Color(0xFFFEE2E2), // Soft coral/pink
            const Color(0xFFCCFBF1), // Soft teal
            const Color(0xFFE0F2FE), // Soft sky blue
            const Color(0xFFD1FAE5), // Soft mint
            const Color(0xFFE0E7FF), // Soft lavender
          ]
        : [
            const Color(0xFF3B2727),
            const Color(0xFF1F3A36),
            const Color(0xFF1E3448),
            const Color(0xFF1C3B2F),
            const Color(0xFF262B44),
          ];



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 16),

        // 1. Metric Cards Row
        Expanded(
          flex: 68,
          child: Row(
            children: metrics.asMap().entries.map((entry) {
              final idx = entry.key;
              final Map item = entry.value is Map ? entry.value as Map : {};
              final imageKey = 'metric_image_$idx';
              final pastelBg = pastelColors[idx % pastelColors.length];

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: idx == metrics.length - 1 ? 0 : 12),
                  padding: const EdgeInsets.only(top: 16, bottom: 14, left: 16, right: 16),
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
                      // Top Handle Indicator Bar
                      Center(
                        child: Container(
                          width: 52,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFF1E1E1E) : const Color(0xFFCCCCCC),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metric Value (Coral Red Accent)
                      SelectableTextElement(
                        elementKey: 'metric_val_$idx',
                        label: 'Metric',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText('metric_val_$idx', item['value']?.toString() ?? ''),
                          style: TextStyle(
                            color: const Color(0xFFF05252),
                            fontSize: slide.getFontSize('metric_val_$idx', 48.0),
                            fontWeight: slide.getFontWeight('metric_val_$idx', FontWeight.w900),
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Card Title
                      SelectableTextElement(
                        elementKey: 'card_title_$idx',
                        label: 'Card Header',
                        selectedElementKey: renderContext.selectedElementKey,
                        onSelectElement: renderContext.onSelectElement,
                        child: Text(
                          slide.getElementText('card_title_$idx', item['title']?.toString() ?? ''),
                          style: TextStyle(
                            color: isLight ? const Color(0xFF111827) : Colors.white,
                            fontSize: slide.getFontSize('card_title_$idx', 22.0),
                            fontWeight: slide.getFontWeight('card_title_$idx', FontWeight.bold),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Body Description
                      Expanded(
                        child: SelectableTextElement(
                          elementKey: 'body_$idx',
                          label: 'Body Text',
                          selectedElementKey: renderContext.selectedElementKey,
                          onSelectElement: renderContext.onSelectElement,
                          child: Text(
                            slide.getElementText('body_$idx', item['description']?.toString() ?? ''),
                            style: TextStyle(
                              color: isLight ? const Color(0xFF4B5563) : const Color(0xFFA0A0A0),
                              fontSize: slide.getFontSize('body_$idx', 15.5),
                              fontWeight: slide.getFontWeight('body_$idx', FontWeight.normal),
                              height: 1.35,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bottom Image Slot in 16:9 Ratio with Pastel Container
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: pastelBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: ImageDropzoneWidget(
                              slideId: slide.id,
                              imageKey: imageKey,
                              companyName: renderContext.companyName,
                              label: 'Select Asset',
                              formatHint: 'PNG, JPG, SVG',
                              height: double.infinity,
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
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // 2. Bottom Banner Container Card
        Expanded(
          flex: 32,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF4F8FC) : const Color(0xFF1E2630),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLight ? const Color(0xFFE2EBF4) : const Color(0xFF2E3B4E),
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                // Left Content Column
                Expanded(
                  flex: 74,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with Vertical Blue Accent Bar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 4.5,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableTextElement(
                                  elementKey: 'bottom_banner_title',
                                  label: 'Banner Header',
                                  selectedElementKey: renderContext.selectedElementKey,
                                  onSelectElement: renderContext.onSelectElement,
                                  child: Text(
                                    slide.getElementText(
                                      'bottom_banner_title',
                                      '$companyName has built the diagnostic engine.',
                                    ),
                                    style: TextStyle(
                                      color: isLight ? const Color(0xFF111827) : Colors.white,
                                      fontSize: 21.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                SelectableTextElement(
                                  elementKey: 'bottom_banner_sub',
                                  label: 'Banner Subtitle',
                                  selectedElementKey: renderContext.selectedElementKey,
                                  onSelectElement: renderContext.onSelectElement,
                                  child: Builder(
                                    builder: (context) {
                                      final subText = slide.getElementText(
                                        'bottom_banner_sub',
                                        'The next opportunity is the relationship around it.',
                                      );
                                      if (subText.contains('relationship')) {
                                        final parts = subText.split('relationship');
                                        return Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: parts.first,
                                                style: TextStyle(
                                                  color: isLight ? const Color(0xFF111827) : Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const TextSpan(
                                                text: 'relationship',
                                                style: TextStyle(
                                                  color: Color(0xFF1877F2),
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: parts.sublist(1).join('relationship'),
                                                style: TextStyle(
                                                  color: isLight ? const Color(0xFF111827) : Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return Text(
                                        subText,
                                        style: TextStyle(
                                          color: isLight ? const Color(0xFF111827) : Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Row of Checkmark Badges loaded directly from JSON
                      Builder(
                        builder: (context) {
                          final List badgesList = (slide.rawContent['badges'] as List?) ?? [];
                          return Row(
                            children: badgesList.asMap().entries.map((bEntry) {
                              final badgeIdx = bEntry.key;
                              final badgeText = bEntry.value.toString();
                              final badgeKey = 'banner_badge_$badgeIdx';

                              return Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD0E8FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Color(0xFF1877F2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SelectableTextElement(
                                        elementKey: badgeKey,
                                        label: 'Badge ${badgeIdx + 1}',
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                        child: Text(
                                          slide.getElementText(badgeKey, badgeText),
                                          style: TextStyle(
                                            color: isLight ? const Color(0xFF374151) : const Color(0xFFCCCCCC),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right India Network Map Asset & Action Button
                Expanded(
                  flex: 26,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            'assets/india_network_map.png',
                            height: double.infinity,
                            fit: BoxFit.fitHeight,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.map_outlined,
                              size: 52,
                              color: Color(0xFF1877F2),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1877F2),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1877F2).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 21,
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
    );
  }

}
