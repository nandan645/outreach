# HeyDoc Outreach — Presentation Platform

> **Developer & AI Agent Handoff Guide**: This document details the system architecture, code organization, backend contracts, slide extension model, and deployment workflows for the HeyDoc Outreach presentation application.

---

## 1. System Overview

HeyDoc Outreach is an interactive Flutter Web application designed to generate, customize, edit, and present outreach pitch decks tailored to various healthcare verticals (Hospital Care, Labs & Diagnostics, Health Insurance, E-Pharmacies, Digital Health & Fitness).

- **Frontend**: Flutter Web (CanvasKit / WebAssembly / HTML renderer), Dart 3.
- **Backend / Storage**: Cloud API server hosted at `https://ppts.nandanabhi.me` (with fallback to `https://api.nandanabhi.me`).
- **AI Intelligence**: Direct integration with Google Gemini (`v1beta`) for slide generation, restructuring, and copywriting.
- **Hosting**: GitHub Pages deployed via GitHub Actions at [https://nandan645.github.io/outreach/](https://nandan645.github.io/outreach/).

---

## 2. Directory & File Structure

```
ppt_flutter_application/
├── .github/
│   └── workflows/
│       └── deploy.yml            # CI/CD: Builds and deploys Flutter Web to GitHub Pages
├── assets/
│   ├── fonts/                   # Satoshi font family (Light, Regular, Medium, Bold, Black)
│   ├── hero/                    # Hero diagram graphics
│   ├── presets/                 # Preset visual assets categorized by slide type
│   │   ├── architecture_flow_presets/
│   │   ├── comparison_ecosystem_presets/
│   │   ├── consumer_experience/
│   │   ├── core_capabilities/
│   │   ├── dynamic_presets/
│   │   ├── enterprise_brain/
│   │   ├── intelligence_dashboards/
│   │   ├── logo_presets/         # Healthcare partner/client logos
│   │   ├── metric_cards/
│   │   ├── mobile_mockup/
│   │   ├── modular_ui_mockups/
│   │   ├── multi_feature_showcase/
│   │   ├── patient_journey_steps/
│   │   └── platform_showcase/
│   └── prompts/                 # Sector-specific system prompts fed into Gemini
│       ├── digital_health_and_fitness.md
│       ├── e-pharmacies.md
│       ├── health_insurance.md
│       ├── hospital_care.md
│       └── labs_and_diagnostics.md
├── lib/
│   ├── main.dart                # App entrypoint, theme, dashboard list, PresentationModel
│   ├── api_service.dart         # Backend REST API client with failover & asset resolution
│   ├── image_helper.dart        # Normalizes asset paths, remote URLs, and base64 data URIs
│   ├── account_preferences_screen.dart # Gemini API key setup, model testing, and provider preferences
│   ├── create_presentation_screen.dart # Deck creation wizard (PDF parsing, sector prompts, Gemini calls)
│   ├── presentation_editor_screen.dart # Interactive slide canvas, property inspector, reordering, export
│   └── slides/                  # Extensible slide engine
│       ├── base_slide.dart      # Abstract BaseSlide definition
│       ├── slide_context.dart   # Visual theme & runtime context passed to each slide
│       ├── slide_registry.dart  # Central registry for lookup & discovery of slide types
│       ├── slides.dart          # Aggregator exporting all slides and running initSlideRegistry()
│       └── types/               # 18+ modular slide implementations
├── web/                         # Web entry point, manifest.json, favicon, index.html
├── pubspec.yaml                 # Dependencies and asset declarations
├── pubspec.lock                 # Deterministic dependency lockfile
├── analysis_options.yaml        # Flutter and Dart static analysis lints
└── README.md                    # Developer handoff documentation
```

---

## 3. Core Modules & Data Flow

### A. API Service (`lib/api_service.dart`)
Handles communication with the backend presentation storage server:
- **Automatic Failover**: Tries `https://ppts.nandanabhi.me` first; automatically switches to `https://api.nandanabhi.me` if the primary is unreachable.
- **Asset URL Resolution**: `ApiService.resolveAssetUrl(rawPath, presentationId)` resolves local preset assets, absolute URLs, or presentation-specific uploaded media.
- **Endpoints**:
  - `GET /api/health` — Checks backend availability.
  - `GET /api/settings` / `POST /api/settings` — Reads/saves global config (e.g., Gemini API keys, default models).
  - `GET /api/presentations` — Retrieves all presentations metadata.
  - `POST /api/presentations` — Creates a new presentation folder with `manifest.json` and `presentation.json`.
  - `POST /api/presentations/:id/save` — Persists slide edits and manifest updates.
  - `DELETE /api/presentations/:id` — Removes a presentation from the server.
  - `POST /api/upload` — Uploads binary files (logos, documents) encoded in Base64.

### B. AI Engine & Prompt Pipeline
Located in `lib/create_presentation_screen.dart` and `lib/account_preferences_screen.dart`:
1. Users enter an outreach target company and sector (e.g., *Hospital Care*).
2. The app reads the corresponding sector prompt from `assets/prompts/<sector>.md`.
3. An optional client brief or annual report (PDF) can be uploaded; text is extracted and injected into the prompt.
4. Calls Google Gemini via `https://generativelanguage.googleapis.com/v1beta/models/<model>:generateContent?key=<apiKey>`.
5. Gemini returns a structured JSON payload conforming to the slide schemas registered in `lib/slides/`.

### C. Slide Architecture (`lib/slides/`)
Each slide in the presentation is a standalone modular component:
- **`BaseSlide`** (`lib/slides/base_slide.dart`):
  ```dart
  abstract class BaseSlide {
    String get type;
    String get title;
    Widget buildSlide(BuildContext context, Map<String, dynamic> data, SlideContext slideContext);
    Widget buildEditor(BuildContext context, Map<String, dynamic> data, void Function(Map<String, dynamic>) onChanged);
  }
  ```
- **`SlideContext`** (`lib/slides/slide_context.dart`): Supplies company branding, primary/accent colors, and slide numbering to the slide.
- **`SlideRegistry`** (`lib/slides/slide_registry.dart`): A runtime registry holding registered `BaseSlide` instances by `type`. Initialized on app boot via `initSlideRegistry()` in `lib/main.dart`.

---

## 4. How to Add a New Slide Type

To add a new slide type for developers or AI agents:

1. **Create the slide file** in `lib/slides/types/new_slide_name.dart`:
   - Implement `BaseSlide`.
   - Provide a unique `type` identifier (e.g., `'new_slide_name'`).
   - Implement `buildSlide()` for presentation view.
   - Implement `buildEditor()` for the slide settings inspector panel in the editor.

2. **Register the slide**:
   - In `lib/slides/slides.dart`:
     - Add `export 'types/new_slide_name.dart';`
     - Import the slide and call `SlideRegistry.register(NewSlideName());` in `initSlideRegistry()`.

3. **Update Prompts (Optional)**:
   - If AI generation should produce this slide, describe its JSON schema in the markdown files under `assets/prompts/`.

---

## 5. Development & Local Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.13+ / Dart 3.12+)
- Google Chrome (for Flutter Web debugging)
- GitHub CLI (`gh`) for repository management

### Commands
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis
dart analyze

# 3. Run unit / widget tests
flutter test

# 4. Run locally on Chrome (Debug)
flutter run -d chrome

# 5. Build for Web (Production release)
flutter build web --release
```

---

## 6. Deployment & CI/CD

Deployment to GitHub Pages is **fully automated** via GitHub Actions:
- **Workflow File**: `.github/workflows/deploy.yml`
- **Trigger**: Every push to the `main` or `master` branches, or manual trigger (`workflow_dispatch`).
- **Dynamic Subpathing**: The workflow compiles the web bundle using:
  ```bash
  flutter build web --release --base-href "/${{ github.event.repository.name }}/"
  ```
  This guarantees that all scripts, canvaskit WASM blobs, and assets resolve correctly under the GitHub Pages subpath (`https://<username>.github.io/<repo>/`).
- **Build Artifacts in Git**: The `build/` directory is intentionally ignored in `.gitignore`. No build outputs or minified binaries are tracked in Git; the CI runner compiles the clean source code from scratch on every push.

---

## 7. Configuration & Secrets

- **Gemini API Key**: Configured at runtime via the in-app **Account Preferences** screen (`/preferences`). Keys are saved in backend settings via `POST /api/settings` and never hardcoded in source control.
- **Backend URL**: Hardcoded defaults live in `ApiService.candidateUrls` (`lib/api_service.dart`).
