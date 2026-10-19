# Blast Blocks

A complete match-3 puzzle game for iOS — pure Swift + SpriteKit, zero dependencies,
zero binary assets (every tile, icon and effect is rendered procedurally at runtime).

## Features

- Cute animal-head tiles (Kenney Animal Pack, CC0) with distinct silhouettes per color
- Procedural sound effects via AVAudioEngine (zero audio assets)
- Special pieces: rockets (row/column), bombs (3×3), novas (color wipe)
- Special × special combos: cross blasts, 5×5 bombs, triple row+column, board clears
- Cascading gravity engine with crate blockers that segment columns
- 30 procedurally-tuned levels: move limits, collect-goals, crate-clear goals
- Star ratings + progress saved locally
- Level map with serpentine path, locks and star display
- Juice: particle bursts, beam/blast effects, combo labels, haptics, shuffle on dead board

## Build

The project is generated with [XcodeGen](https://github.com/yonsm/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open BlastBlocks.xcodeproj
```

## Unsigned IPA via GitHub Actions

`.github/workflows/build-ipa.yml` builds the app on `macos-latest` with
`CODE_SIGNING_ALLOWED=NO`, packages `Payload/BlastBlocks.app` into
`BlastBlocks-unsigned.ipa` and uploads it as a workflow artifact.

The unsigned IPA can be sideloaded with AltStore, Sideloadly, TrollStore, etc.

## Credits

Tile art: [Kenney Animal Pack](https://kenney.nl/assets/animal-pack) — CC0.
