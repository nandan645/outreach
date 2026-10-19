import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

class ArchitectureFlowSlide extends BaseSlide {
  @override
  String get type => 'architecture_flow';

  @override
  String get displayName => 'Architecture Flow';

  @override
  Widget build(SlideRenderContext renderContext) {
    final slide = renderContext.slide;
    final List flow = slide.rawContent['flow'] as List? ?? [];

    return Builder(
      builder: (context) {
        final isLight = Theme.of(context).brightness == Brightness.light;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            renderContext.buildTitleHeader(context),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: flow.asMap().entries.expand((entry) {
                        final index = entry.key;
                        final item = entry.value is Map ? entry.value as Map : {};
                        final isLast = index == flow.length - 1;

                        final headerWidget = Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF222222),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              border: Border(
                                top: BorderSide(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                                left: BorderSide(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                                right: BorderSide(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: renderContext.accentColor,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SelectableTextElement(
                                    elementKey: 'card_title_$index',
                                    label: 'Card Header',
                                    selectedElementKey: renderContext.selectedElementKey,
                                    onSelectElement: renderContext.onSelectElement,
                                    child: Text(
                                      slide.getElementText('card_title_$index', item['stage']?.toString() ?? ''),
                                      style: TextStyle(
                                        color: isLight ? const Color(0xFF111827) : Colors.white,
                                        fontSize: slide.getFontSize('card_title_$index', 16.0),
                                        fontWeight: slide.getFontWeight('card_title_$index', FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (isLast) return [headerWidget];
                        return [headerWidget, const SizedBox(width: 44)];
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: flow.asMap().entries.expand((entry) {
                        final index = entry.key;
                        final item = entry.value is Map ? entry.value as Map : {};
                        final List agents = item['agents'] as List? ?? [];
                        final isLast = index == flow.length - 1;

                        final visualWidget = Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF222222),
                              border: Border(
                                left: BorderSide(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                                right: BorderSide(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                              ),
                            ),
                            child: agents.isNotEmpty
                                ? Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isLight ? Colors.white : const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333),
                                      ),
                                    ),
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: agents.asMap().entries.map((aEntry) {
                                            final aIdx = aEntry.key;
                                            final a = aEntry.value;
                                            final keyStr = 'diagram_label_${index}_$aIdx';
                                            return SelectableTextElement(
                                              elementKey: keyStr,
                                              label: 'Diagram Label',
                                              selectedElementKey: renderContext.selectedElementKey,
                                              onSelectElement: renderContext.onSelectElement,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: renderContext.accentColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  slide.getElementText(keyStr, a.toString()),
                                                  style: TextStyle(
                                                    color: renderContext.accentColor,
                                                    fontSize: slide.getFontSize(keyStr, 12.0),
                                                    fontWeight: slide.getFontWeight(keyStr, FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  )
                                : () {
                                     final imgKey = 'arch_image_$index';
                                     String initialPath;
                                     if (slide.hasImageOverride(imgKey)) {
                                       initialPath = slide.getImagePath(imgKey);
                                     } else {
                                       initialPath = slide.getImagePath(imgKey);
                                       if (initialPath.isEmpty) {
                                         if (index == 0) {
                                           initialPath = 'assets/presets/architecture_flow_presets/architecture_flow_01.png';
                                         } else if (index == 1) {
                                           initialPath = 'assets/presets/architecture_flow_presets/architecture_flow_02.png';
                                         } else {
                                           initialPath = 'assets/presets/architecture_flow_presets/architecture_flow_04.png';
                                         }
                                       }
                                     }

                                     return ImageDropzoneWidget(
                                       slideId: slide.id,
                                       imageKey: imgKey,
                                       companyName: renderContext.companyName,
                                       label: 'Card Image',
                                       formatHint: '1:1',
                                       height: double.infinity,
                                       initialImagePath: initialPath,
                                       folderPath: renderContext.folderPath,
                                       onImageSelected: (path) {
                                         if (renderContext.onImageChanged != null) {
                                           renderContext.onImageChanged!(imgKey, path);
                                         }
                                       },
                                     );
                                   }(),
                          ),
                        );

                        if (isLast) return [visualWidget];
                        return [
                          visualWidget,
                          SizedBox(
                            width: 44,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: renderContext.accentColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: SelectableIconElement(
                                  elementKey: 'arch_arrow_icon_$index',
                                  label: 'Arrow Icon',
                                  icon: slide.getIcon('arch_arrow_icon_$index', Icons.swap_horiz),
                                  size: slide.getFontSize('arch_arrow_icon_$index', 18.0),
                                  color: renderContext.accentColor,
                                  selectedElementKey: renderContext.selectedElementKey,
                                  onSelectElement: renderContext.onSelectElement,
                                ),
                              ),
                            ),
                          ),
                        ];
                      }).toList(),
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: flow.asMap().entries.expand((entry) {
                        final index = entry.key;
                        final item = entry.value is Map ? entry.value as Map : {};
                        final isLast = index == flow.length - 1;

                        final descWidget = Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF222222),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border(
                                bottom: BorderSide(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                                left: BorderSide(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                                right: BorderSide(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                              ),
                            ),
                            child: SelectableTextElement(
                              elementKey: 'body_$index',
                              label: 'Body Text',
                              selectedElementKey: renderContext.selectedElementKey,
                              onSelectElement: renderContext.onSelectElement,
                              child: Text(
                                slide.getElementText('body_$index', item['description']?.toString() ?? ''),
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                  fontSize: slide.getFontSize('body_$index', 13.5),
                                  fontWeight: slide.getFontWeight('body_$index', FontWeight.normal),
                                ),
                              ),
                            ),
                          ),
                        );

                        if (isLast) return [descWidget];
                        return [descWidget, const SizedBox(width: 44)];
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
