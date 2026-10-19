import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

class ThankYouSlide extends BaseSlide {
  @override
  String get type => 'thank_you';

  @override
  String get displayName => 'Thank You Slide';

  @override
  Widget build(SlideRenderContext renderContext) {
    final slide = renderContext.slide;
    final List productVideos = slide.rawContent['productVideos'] as List? ?? [];

    return Builder(
      builder: (context) {
        final isLight = Theme.of(context).brightness == Brightness.light;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            renderContext.buildTitleHeader(context),
            const SizedBox(height: 14),
            if (productVideos.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: productVideos.asMap().entries.map((vEntry) {
                  final vIdx = vEntry.key;
                  final v = vEntry.value;
                  final keyStr = 'diagram_label_$vIdx';
                  return SelectableTextElement(
                    elementKey: keyStr,
                    label: 'Diagram Label',
                    selectedElementKey: renderContext.selectedElementKey,
                    onSelectElement: renderContext.onSelectElement,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: renderContext.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableIconElement(
                            elementKey: 'sol_icon_video_$vIdx',
                            label: 'Video Icon',
                            icon: slide.getIcon('sol_icon_video_$vIdx', Icons.play_circle_fill),
                            size: slide.getFontSize('sol_icon_video_$vIdx', 12.0),
                            color: renderContext.accentColor,
                            selectedElementKey: renderContext.selectedElementKey,
                            onSelectElement: renderContext.onSelectElement,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            slide.getElementText(keyStr, v.toString()),
                            style: TextStyle(
                              color: renderContext.accentColor,
                              fontSize: slide.getFontSize(keyStr, 16.0),
                              fontWeight: slide.getFontWeight(keyStr, FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF222222),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableIconElement(
                    elementKey: 'sol_icon_phone',
                    label: 'Phone Icon',
                    icon: slide.getIcon('sol_icon_phone', Icons.phone),
                    size: slide.getFontSize('sol_icon_phone', 14.0),
                    color: Colors.grey,
                    selectedElementKey: renderContext.selectedElementKey,
                    onSelectElement: renderContext.onSelectElement,
                  ),
                  const SizedBox(width: 6),
                  SelectableTextElement(
                    elementKey: 'body_phone',
                    label: 'Body Text',
                    selectedElementKey: renderContext.selectedElementKey,
                    onSelectElement: renderContext.onSelectElement,
                    child: Text(
                      '+91 8171094556',
                      style: TextStyle(
                        fontSize: slide.getFontSize('body_phone', 16.0),
                        fontWeight: slide.getFontWeight('body_phone', FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SelectableIconElement(
                    elementKey: 'sol_icon_email',
                    label: 'Email Icon',
                    icon: slide.getIcon('sol_icon_email', Icons.email),
                    size: slide.getFontSize('sol_icon_email', 14.0),
                    color: Colors.grey,
                    selectedElementKey: renderContext.selectedElementKey,
                    onSelectElement: renderContext.onSelectElement,
                  ),
                  const SizedBox(width: 6),
                  SelectableTextElement(
                    elementKey: 'body_email',
                    label: 'Body Text',
                    selectedElementKey: renderContext.selectedElementKey,
                    onSelectElement: renderContext.onSelectElement,
                    child: Text(
                      'business@heydoc.co.in',
                      style: TextStyle(
                        fontSize: slide.getFontSize('body_email', 16.0),
                        fontWeight: slide.getFontWeight('body_email', FontWeight.w600),
                      ),
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
