export 'base_slide.dart';
export 'slide_context.dart';
export 'slide_registry.dart';

export 'types/hero_diagram_slide.dart';
export 'types/metric_cards_slide.dart';
export 'types/three_stage_process_slide.dart';
export 'types/architecture_flow_slide.dart';
export 'types/ecosystem_flow_slide.dart';
export 'types/thank_you_slide.dart';
export 'types/diagnostic_journey_slide.dart';
export 'types/relationship_moments_slide.dart';
export 'types/ai_intelligence_next_layer_slide.dart';
export 'types/continuous_patient_journey_slide.dart';
export 'types/action_layer_infrastructure_slide.dart';
export 'types/diagnostic_journey_breaks_slide.dart';
export 'types/app_pieces_unconnected_slide.dart';
export 'types/intent_to_action_slide.dart';
export 'types/personalized_player_experience_slide.dart';
export 'types/vision_ai_to_coach_intelligence_slide.dart';
export 'types/operating_layer_agents_slide.dart';
export 'types/what_company_gains_slide.dart';
export 'types/custom_slide.dart';

import 'slide_registry.dart';
import 'types/hero_diagram_slide.dart';
import 'types/metric_cards_slide.dart';
import 'types/three_stage_process_slide.dart';
import 'types/architecture_flow_slide.dart';
import 'types/ecosystem_flow_slide.dart';
import 'types/thank_you_slide.dart';
import 'types/diagnostic_journey_slide.dart';
import 'types/relationship_moments_slide.dart';
import 'types/ai_intelligence_next_layer_slide.dart';
import 'types/continuous_patient_journey_slide.dart';
import 'types/action_layer_infrastructure_slide.dart';
import 'types/diagnostic_journey_breaks_slide.dart';
import 'types/app_pieces_unconnected_slide.dart';
import 'types/intent_to_action_slide.dart';
import 'types/personalized_player_experience_slide.dart';
import 'types/vision_ai_to_coach_intelligence_slide.dart';
import 'types/operating_layer_agents_slide.dart';
import 'types/what_company_gains_slide.dart';
import 'types/custom_slide.dart';

/// Initializes and registers all active slide types
void initSlideRegistry() {
  SlideRegistry.register(HeroDiagramSlide());
  SlideRegistry.register(MetricCardsSlide());
  SlideRegistry.register(ThreeStageProcessSlide());
  SlideRegistry.register(ArchitectureFlowSlide());
  SlideRegistry.register(EcosystemFlowSlide());
  SlideRegistry.register(ThankYouSlide());
  SlideRegistry.register(DiagnosticJourneySlide());
  SlideRegistry.register(RelationshipMomentsSlide());
  SlideRegistry.register(AiIntelligenceNextLayerSlide());
  SlideRegistry.register(ContinuousPatientJourneySlide());
  SlideRegistry.register(ActionLayerInfrastructureSlide());
  SlideRegistry.register(DiagnosticJourneyBreaksSlide());
  SlideRegistry.register(AppPiecesUnconnectedSlide());
  SlideRegistry.register(IntentToActionSlide());
  SlideRegistry.register(PersonalizedPlayerExperienceSlide());
  SlideRegistry.register(VisionAiToCoachIntelligenceSlide());
  SlideRegistry.register(OperatingLayerAgentsSlide());
  SlideRegistry.register(WhatCompanyGainsSlide());
  SlideRegistry.register(CustomSlide());
}

