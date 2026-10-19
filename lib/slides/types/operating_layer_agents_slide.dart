import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

/// Slide type representing "The Operating Layer: Intelligent Agents Powering Every Part of Machaxi"
class OperatingLayerAgentsSlide extends BaseSlide {
  @override
  String get type => 'operating_layer_agents';

  @override
  String get displayName => 'Operating Layer Agents';

  @override
  Widget build(SlideRenderContext context) {
    return _OperatingLayerAgentsWidget(renderContext: context);
  }
}

class _OperatingLayerAgentsWidget extends StatelessWidget {
  final SlideRenderContext renderContext;

  const _OperatingLayerAgentsWidget({required this.renderContext});

  @override
  Widget build(BuildContext context) {
    final slide = renderContext.slide;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textDark = isLight ? const Color(0xFF111827) : Colors.white;
    final textMuted = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    final cardThemes = [
      {
        "primary": const Color(0xFF2563EB),
        "soft_bg": isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E293B),
        "fallback_icon": Icons.domain_rounded,
        "item_icons": [
          Icons.pie_chart_outline_rounded,
          Icons.calendar_month_rounded,
          Icons.group_outlined,
          Icons.person_outline_rounded,
          Icons.build_outlined,
          Icons.error_outline_rounded,
        ]
      },
      {
        "primary": const Color(0xFF7C3AED),
        "soft_bg": isLight ? const Color(0xFFF3F0FF) : const Color(0xFF261E38),
        "fallback_icon": Icons.chat_bubble_rounded,
        "item_icons": [
          Icons.calendar_month_rounded,
          Icons.credit_card_rounded,
          Icons.info_outline_rounded,
          Icons.campaign_outlined,
          Icons.description_outlined,
          Icons.person_rounded,
        ]
      },
      {
        "primary": const Color(0xFF059669),
        "soft_bg": isLight ? const Color(0xFFECFDF5) : const Color(0xFF132A22),
        "fallback_icon": Icons.trending_up_rounded,
        "item_icons": [
          Icons.person_add_alt_rounded,
          Icons.track_changes_rounded,
          Icons.notifications_none_rounded,
          Icons.event_available_rounded,
          Icons.warning_amber_rounded,
          Icons.autorenew_rounded,
        ]
      },
    ];

    final featureIcons = [
      Icons.storage_rounded,
      Icons.auto_awesome,
      Icons.verified_user_outlined,
      Icons.bar_chart_rounded,
    ];

    final featureColors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFF2563EB),
    ];

    final featureBgs = isLight
        ? [
            const Color(0xFFEFF6FF),
            const Color(0xFFF3F0FF),
            const Color(0xFFECFDF5),
            const Color(0xFFEFF6FF),
          ]
        : [
            const Color(0xFF1E293B),
            const Color(0xFF261E38),
            const Color(0xFF132A22),
            const Color(0xFF1E293B),
          ];

    // Data parsing for 3 Agents from JSON
    final rawAgents = (slide.rawContent['agents'] as List?) ?? [];
    final agents = rawAgents.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      final rawItems = (item['items'] as List?) ?? [];
      final themeMap = cardThemes[idx % cardThemes.length];

      return {
        "title": item['title']?.toString() ?? '',
        "subtitle": item['subtitle']?.toString() ?? '',
        "image_key": item['image_key']?.toString() ?? 'agent_image_$idx',
        "items": rawItems.map((i) => i.toString()).toList(),
        "theme": themeMap,
        "prefix": "agent_${idx + 1}",
      };
    }).toList();

    // Data parsing for Bottom Banner from JSON
    final rawBanner = (slide.rawContent['bottom_banner'] as Map?) ?? {};
    final bannerTitle = rawBanner['title']?.toString() ?? '';
    final bannerSubtitle = rawBanner['subtitle']?.toString() ?? '';
    final rawFeatures = (rawBanner['features'] as List?) ?? [];
    final features = rawFeatures.asMap().entries.map((entry) {
      final idx = entry.key;
      final Map item = entry.value is Map ? entry.value as Map : {};
      return {
        "title": item['title']?.toString() ?? '',
        "desc": item['description']?.toString() ?? '',
        "icon": featureIcons[idx % featureIcons.length],
        "color": featureColors[idx % featureColors.length],
        "bg": featureBgs[idx % featureBgs.length],
        "prefix": "feat_${idx + 1}",
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle Header
        renderContext.buildTitleHeader(context),
        const SizedBox(height: 14),

        // 1. TOP ROW: 3 AGENT CARDS WITH SEQUENTIAL CONNECTORS
        Expanded(
          flex: 74,
          child: Row(
            children: [
              for (int idx = 0; idx < agents.length; idx++) ...[
                () {
                  final agent = agents[idx];
                  final prefix = agent['prefix'] as String;
                  final imageKey = agent['image_key'] as String;
                  final itemList = agent['items'] as List<String>;
                  final theme = agent['theme'] as Map<String, dynamic>;
                  final primaryColor = theme['primary'] as Color;
                  final softBg = theme['soft_bg'] as Color;
                  final itemIconsList = theme['item_icons'] as List<IconData>;

                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBorder, width: 1.3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Image Dropzone + Title & Subtitle
                          Row(
                            children: [
                              // Image Upload Dropzone Box (76x76)
                              SizedBox(
                                width: 76,
                                height: 76,
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
                                    label: 'Upload',
                                    formatHint: 'Asset',
                                    height: 76,
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

                              const SizedBox(width: 14),

                              // Title & Subtitle Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableTextElement(
                                      elementKey: '${prefix}_title',
                                      label: 'Agent Title',
                                      selectedElementKey: renderContext.selectedElementKey,
                                      onSelectElement: renderContext.onSelectElement,
                                      child: Text(
                                        slide.getElementText('${prefix}_title', agent['title'] as String),
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: slide.getFontSize('${prefix}_title', 24.0),
                                          fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w800),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    SelectableTextElement(
                                      elementKey: '${prefix}_sub',
                                      label: 'Agent Subtitle',
                                      selectedElementKey: renderContext.selectedElementKey,
                                      onSelectElement: renderContext.onSelectElement,
                                      child: Text(
                                        slide.getElementText('${prefix}_sub', agent['subtitle'] as String),
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: slide.getFontSize('${prefix}_sub', 16.0),
                                          fontWeight: slide.getFontWeight('${prefix}_sub', FontWeight.w500),
                                          height: 1.2,
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

                          const SizedBox(height: 14),

                          // 6 Item Pills Column
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: itemList.asMap().entries.map((iEntry) {
                                final iIdx = iEntry.key;
                                final itemText = iEntry.value;
                                final iconData = itemIconsList[iIdx % itemIconsList.length];
                                final iconKey = '${prefix}_icon_${iIdx + 1}';
                                final itemKey = '${prefix}_item_${iIdx + 1}';
                                final currentIcon = slide.getIcon(iconKey, iconData);
                                final currentText = slide.getElementText(itemKey, itemText);

                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: softBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SelectableIconElement(
                                        elementKey: iconKey,
                                        label: 'Agent Item Icon',
                                        icon: currentIcon,
                                        size: slide.getFontSize(iconKey, 20.0),
                                        color: primaryColor,
                                        selectedElementKey: renderContext.selectedElementKey,
                                        onSelectElement: renderContext.onSelectElement,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SelectableTextElement(
                                          elementKey: itemKey,
                                          label: 'Agent Item',
                                          selectedElementKey: renderContext.selectedElementKey,
                                          onSelectElement: renderContext.onSelectElement,
                                          child: Text(
                                            currentText,
                                            style: TextStyle(
                                              color: textDark,
                                              fontSize: slide.getFontSize(itemKey, 16.0),
                                              fontWeight: slide.getFontWeight(itemKey, FontWeight.w700),
                                              height: 1.25,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                  );
                }(),

                // Connector Right Arrow Circle between Agent Cards
                if (idx < agents.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 2,
                          color: const Color(0xFFCBD5E1),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isLight ? Colors.white : const Color(0xFF2A2E39),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF444444),
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 24,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 2,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. BOTTOM POWERED BY WELLNESSGPT BANNER
        Expanded(
          flex: 26,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFAFAFA) : const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF2E333D),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Left Header Part: Brain Graphic Dropzone + Title & Subtitle
                Expanded(
                  flex: 32,
                  child: Row(
                    children: [
                      // Brain Image Dropzone Slot (70x70)
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ImageDropzoneWidget(
                            slideId: slide.id,
                            imageKey: 'brain_image',
                            companyName: renderContext.companyName,
                            label: 'Brain',
                            formatHint: 'PNG',
                            height: 70,
                            initialImagePath: slide.getImagePath('brain_image').isNotEmpty
                                ? slide.getImagePath('brain_image')
                                : 'assets/hero/brain.png',
                            folderPath: renderContext.folderPath,
                            onImageSelected: (path) {
                              if (renderContext.onImageChanged != null) {
                                renderContext.onImageChanged!('brain_image', path);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Subtitle Column
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
                                slide.getElementText('bottom_title', bannerTitle),
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: slide.getFontSize('bottom_title', 20.0),
                                  fontWeight: slide.getFontWeight('bottom_title', FontWeight.w900),
                                  height: 1.2,
                                ),
                                maxLines: 1,
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
                                slide.getElementText('bottom_sub', bannerSubtitle),
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: slide.getFontSize('bottom_sub', 15.0),
                                  fontWeight: slide.getFontWeight('bottom_sub', FontWeight.w500),
                                  height: 1.2,
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
                  width: 1.5,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333),
                ),

                // Right Features Part (4 items with circular icons)
                Expanded(
                  flex: 68,
                  child: Row(
                    children: features.map((fItem) {
                      final prefix = fItem['prefix'] as String;
                      final iconData = fItem['icon'] as IconData;
                      final color = fItem['color'] as Color;
                      final bg = fItem['bg'] as Color;
                      final iconKey = '${prefix}_icon';
                      final currentIcon = slide.getIcon(iconKey, iconData);

                      return Expanded(
                        child: Row(
                          children: [
                            // Icon Circle
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: bg,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: SelectableIconElement(
                                elementKey: iconKey,
                                label: 'Feature Icon',
                                icon: currentIcon,
                                size: slide.getFontSize(iconKey, 24.0),
                                color: color,
                                selectedElementKey: renderContext.selectedElementKey,
                                onSelectElement: renderContext.onSelectElement,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Text Column
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableTextElement(
                                    elementKey: '${prefix}_title',
                                    label: 'Feature Title',
                                    selectedElementKey: renderContext.selectedElementKey,
                                    onSelectElement: renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText('${prefix}_title', fItem['title'] as String),
                                      style: TextStyle(
                                        color: textDark,
                                        fontSize: slide.getFontSize('${prefix}_title', 16.5),
                                        fontWeight: slide.getFontWeight('${prefix}_title', FontWeight.w800),
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableTextElement(
                                    elementKey: '${prefix}_desc',
                                    label: 'Feature Desc',
                                    selectedElementKey: renderContext.selectedElementKey,
                                    onSelectElement: renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText('${prefix}_desc', fItem['desc'] as String),
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: slide.getFontSize('${prefix}_desc', 14.0),
                                        fontWeight: slide.getFontWeight('${prefix}_desc', FontWeight.w500),
                                        height: 1.15,
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
