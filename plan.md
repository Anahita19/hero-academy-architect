# Hero Academy Architect — Implementation Plan

## Scope
Remix the initialized Godot 2D generic starter into a single-player academy-planning tactics game. Preserve the initialized runtime, local save/audio/tuning infrastructure, and Web export path. Integrate the complete supplied Hero Academy package under `assets/supplied/` and use its reference captures as the visual source for the academy dashboard language.

## Gameplay
The core loop is: design a training arena → place hero cadets and a defensive module → begin a turn-based ability test → move and pulse-strike against an AI rival → earn accreditation or revise the academy plan. The playable build has a title screen, planning board, tactical test board, turn/action-point rules, cooldown feedback, readable results, replay, and revise-plan recovery.

## Project structure
- `scenes/main.tscn`: small entry scene that loads the remix controller.
- `scripts/academy_main.gd`: authoritative UI, planning state, tactical simulation, AI turn, scoring, and result flow.
- `assets/supplied/`: complete downloaded ZIP, original gallery HTML/README, and all supplied academy captures.
- `web/loading.html`: game-specific loading shell with single-language English copy.
- `config/tuning.json`, autoloads, and runtime scripts: retained as compatible scaffold infrastructure.

## Visual system
- **Design movement:** tactical operations dashboard meets luminous campus blueprint.
- **Core principles:** high-contrast academy HUD, readable cells and unit roles, restrained neon feedback, and direct action hierarchy.
- **Color philosophy:** deep midnight blue supports concentration; cyan/teal communicates planning and safe systems; amber and magenta mark risk, cooldown, and rival pressure; mint confirms accreditation.
- **Layout paradigm:** asymmetric command rail + large tactical canvas, echoing the supplied dashboard captures rather than a centered menu stack.
- **Signature elements:** top telemetry strip, glass command cards, and color-coded cell overlays for terrain, placement, range, and cooldown.
- **Interaction philosophy:** every click either changes the academy plan or spends a visible tactical action point; no hidden mode changes.
- **Animation:** lightweight pulse rings and selection accents only; reduced-motion remains calm and simulation-authoritative.
- **Typography:** existing Sora/Figtree template fonts remain the primary display/body faces.
- **Brand essence:** a compact architect’s desk for designing hero training scenarios; precise, cerebral, optimistic.
- **Brand voice:** concise operational copy such as “Shape the test. Read the rival.” and “Accreditation is earned in the replay.”
- **Wordmark:** live text lockup with an academy seal motif; no text baked into the supplied images.
- **Signature brand color:** electric academy cyan `#55E6D0`.

## Material constraints
Use the supplied source/assets/configuration package as the remix foundation and retain all supplied files. Do not add online multiplayer or unrelated modes. Keep the game English-only and desktop-first. No new external asset sourcing is required.
