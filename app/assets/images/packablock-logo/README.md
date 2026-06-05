# Packablock logo kit

One mark, two orientations. The candlestick encodes a package's version story:
**bottom/left node = lowest version, body = recent drift, top/right node = highest semver allowed.**
Read as a commit graph it's just node–line–node, so it sits naturally next to GitHub.

## Colors
- Accent (teal): `#22D3EE`
- Background (navy): `#0E1B2E`
- On light surfaces, use a deeper teal for contrast: `#0E9AA8`

## Files

### `avatars/` — for the GitHub org profile picture
- `packablock-avatar-512.png` … `-32.png` — full-bleed navy square, teal mark. **Upload `-512.png` to GitHub** (it crops/rounds the corners itself).
- `packablock-avatar-rounded-512/256.png` — pre-rounded with transparent corners, for surfaces that don't auto-round.
- `packablock-avatar.svg` — vector source.

### `mark/` — the mark on its own
- `packablock-mark.svg` — teal, transparent background.
- `packablock-mark-currentcolor.svg` — inherits `color`, for theming in CSS/inline use.
- `packablock-mark-teal-512/256/128.png`, `packablock-mark-white-512.png` — raster, transparent.

### `component/` — for the app UI
- `VersionCandle.jsx` — the horizontal indicator. Props: `min`, `max`, `driftFrom`, `driftTo`, `current`, `width`, `height`, `color`, `showNodes`. Map node positions to real versions via the included `versionToNumber` helper (handles `^`, `~`, `<` prefixes).
- `PackablockMark.jsx` — the upright mark as a component (`size`, `color`).
- `version-candle-demo.html` — open in a browser; no build step. Mirrors the JSX logic in vanilla JS so you can see and tweak the math.

## Usage notes
- Avatar / square contexts → upright mark (fills the frame).
- List rows → horizontal `VersionCandle` (reads left→right as version increases).
- Node spacing reflects range width: a tight `~4.18.0` draws narrower than a `^4.0.0`.
- In dense tables you can set `showNodes={false}` and let the printed `min … max` labels carry the endpoints.

## Repo marks (same family)

Two sibling marks for the individual repos, reusing the node / line / body vocabulary:

### `cli/` — command-line tool
Prompt chevron `>` plus a cursor block (the cursor is the org mark's candle body).
- `packablock-cli-avatar-512.png` … `-32.png` (upload 512 to the repo), rounded variants, vector source `packablock-cli-avatar.svg`.
- `packablock-cli.svg` (teal), `packablock-cli-currentcolor.svg` (themeable), transparent PNGs.
- Component: `component/PackablockCliMark.jsx` (`size`, `color`).

### `registry/` — hosted registry
An indexed spine: three nodes, each with a version bar of a different length — the package list compressed into a glyph.
- `packablock-registry-avatar-512.png` … `-32.png`, rounded variants, `packablock-registry-avatar.svg`.
- `packablock-registry.svg` (teal), `packablock-registry-currentcolor.svg`, transparent PNGs.
- Component: `component/PackablockRegistryMark.jsx` (`size`, `color`).

All three avatars share stroke weight, node radius, and the navy rounded-square frame, so the org / cli / registry repos read as one set.
