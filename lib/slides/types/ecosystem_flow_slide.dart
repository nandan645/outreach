import 'package:flutter/material.dart';
import '../../presentation_editor_screen.dart';
import '../base_slide.dart';
import '../slide_context.dart';

class EcosystemFlowSlide extends BaseSlide {
  @override
  String get type => 'ecosystem_flow';

  @override
  String get displayName => 'Ecosystem Flow';

  @override
  Widget build(SlideRenderContext renderContext) {
    final slide = renderContext.slide;
    String initialPath;
    if (slide.hasImageOverride('eco_image')) {
      initialPath = slide.getImagePath('eco_image');
    } else {
      initialPath = slide.getImagePath('eco_image');
      if (initialPath.isEmpty) {
        initialPath = 'assets/presets/multi_feature_showcase/ecosystem_flow_preset.png';
      }
    }

    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            renderContext.buildTitleHeader(context),
            const SizedBox(height: 10),
            Expanded(
              child: ImageDropzoneWidget(
                slideId: slide.id,
                imageKey: 'eco_image',
                companyName: renderContext.companyName,
                label: 'Ecosystem Flow Diagram Image',
                formatHint: 'Max Size Image',
                height: double.infinity,
                initialImagePath: initialPath,
                folderPath: renderContext.folderPath,
                onImageSelected: (path) {
                  if (renderContext.onImageChanged != null) {
                    renderContext.onImageChanged!('eco_image', path);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
