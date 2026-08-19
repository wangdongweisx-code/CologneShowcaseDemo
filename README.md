# Momcozy Cologne Showcase Demo

Standalone, offline-first SwiftUI exhibition app based on the supplied PRD and Figma design.

The runtime visual layer uses the approved Figma frames directly. SwiftUI only adds
transparent interaction areas above the frames, so the images, typography, spacing,
colors and composition are not redrawn or substituted.

## Implemented

- No login or backend dependency.
- The supplied showcase reel's first 10 seconds play in a continuous offline loop.
- Tapping the video opens the exact Figma selling-points directory page.
- Tapping one of the five directory cards opens that feature's Cover Page first.
- The selling-points page information icon opens the exact Figma disclaimer, and its close button returns to the directory.
- 53 exact Figma frame exports bundled for fully offline use.
- Exact Figma cover pages for all five showcase modules.
- Unified Figma feature titles across the selling-points page and every Cover Page: AI Device Assistant, AI Voice Log, AI Lactation Plan, Tailored Breastfeeding Timeline and Mom Groups.
- Exact Figma screen sequences for V3 pairing, CozyAI device help, AI Voice Log, AI Lactation Plan, Tailored Breastfeeding Timeline and Mom Groups.
- The supplemented AI Lactation Plan flow now includes feeding method, pumping frequency, night pumping, preferred-time selection, plan confirmation and generation.
- The 2441 px home page and 1376 px lactation-data page preserve the complete Figma composition and scroll vertically.
- AI Lactation Plan keeps the Cologne-show Figma screens intact while adding the V1.5 7.28 interaction rules: required privacy consent, quantity steppers, Yes/No selection, editable preferred times, selectable days, animated generation progress, scrollable tips and end-date editing.
- Local simulated navigation through transparent tap and swipe areas; no hardware dependency.
- CozyAI supports recommendation chips, free-text messages, loading states, answer bubbles and tappable web citations. It uses local exhibition-safe answers by default and can switch to the OpenAI Responses API through the included server-side proxy.
- Exact Figma legal disclaimer screen.
- Global two-minute inactivity reset to the standby experience.

Runtime order: `10-second video loop → selling-points directory → selected Cover Page → selected feature flow → selling-points directory`.

## Open and run

1. Open `CologneShowcaseDemo.xcodeproj` in Xcode 16 or newer.
2. Select an iPhone simulator or a signed physical iPhone target.
3. Build and run the `CologneShowcaseDemo` scheme.

The Swift sources have passed direct iOS 17 type-checking with Xcode 26.3. The local
CoreSimulator service was unavailable during packaging, so open the project in Xcode
to run the final simulator/device visual check.

## Resources

- The bundled `Resources/Media/BrandLoop.mp4` is the first 10 seconds of the supplied 4K reel.
- See `CologneShowcaseDemo/Resources/Fonts/README.md` for brand font integration.
- The supplied Momcozy mark is bundled as the opaque 1024×1024 iOS App Icon.

All static runtime screens are exact Figma exports stored under
`CologneShowcaseDemo/Resources/FigmaScreens`. They do not depend on Figma URLs at runtime.

## Optional live AI Agent

See `OPENAI_AGENT_SETUP.md` for the recommended server-side OpenAI connection. The app
must not contain a production API key.
