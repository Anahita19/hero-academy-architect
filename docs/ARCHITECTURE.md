# Architecture Notes

## Runtime

Hero Academy Architect preserves the initialized Godot 4.7 `game-2d` runtime and Web export path. The entry scene is deliberately small: [`scenes/main.tscn`](../scenes/main.tscn) instantiates [`scripts/academy_main.gd`](../scripts/academy_main.gd), which owns the remix’s state machine and rendering.

## State machine

The controller uses four explicit screens:

- `TITLE`: academy identity and supplied dashboard visual reference.
- `PLAN`: loadout selection, cell placement, defensive-module planning, and test entry.
- `BATTLE`: turn/action-point simulation, movement, Pulse Strike, cooldowns, rival AI, and tactical feedback.
- `RESULT`: accreditation, score, replay, revise-plan, and title recovery.

The simulation is data-driven with dictionaries for cadets, modules, and rivals. The UI reads the same state used by the tactical rules, so HP, cooldowns, AP, and position are always visible and authoritative.

## Supplied package integration

The complete downloaded package is preserved at [`source-package.zip`](../source-package.zip). Its visual captures are copied into [`assets/supplied/`](../assets/supplied/) and referenced directly by the controller:

- `v6_game.png` — title-screen academy dashboard reference.
- `v6_grid.png` — planning blueprint reference.
- `v6_adv.png` — accreditation/result reference.
- `v6_facilities.png` and `v6_swim.png` — retained supplied material for future academy expansions.

## Web delivery

[`web/loading.html`](../web/loading.html) is a project-owned shell. It provides a game-specific title, real Godot progress callbacks, an indeterminate fallback when totals are unavailable, a nonfatal stalled-load notice, and a Retry action. The static export copied to [`docs/demo/`](demo/) is suitable for a static host such as GitHub Pages.

## Validation surface

The project retains the existing runtime infrastructure and adapts its finite checks to the remix. The release pack verifier checks the exported identity, supplied reference assets, boot state, planning transition, tactical rival seed, font resources, release exclusions, and silent audio behavior.
