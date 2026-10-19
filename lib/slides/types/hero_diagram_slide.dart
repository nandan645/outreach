import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

class HeroDiagramSlide extends BaseSlide {
  @override
  String get type => 'hero_diagram';

  @override
  String get displayName => 'Hero Diagram';

  @override
  Widget build(SlideRenderContext renderContext) {
    return Builder(
      builder: (context) {
        final isLight = Theme.of(context).brightness == Brightness.light;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            renderContext.buildTitleHeader(context),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF222224),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLight ? const Color(0xFFECEFF2) : const Color(0xFF333333),
                    width: 1.2,
                  ),
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
                    const SizedBox(height: 16),
                    // Top handle pill indicator
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFF1E1E1E) : const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16, left: 20, right: 20),
                        child: Center(
                          child: HeroDiagramWidget(
                            rawContent: renderContext.slide.rawContent,
                            companyLogoPath: renderContext.companyLogoPath,
                            companyName: renderContext.companyName,
                            folderPath: renderContext.folderPath,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
