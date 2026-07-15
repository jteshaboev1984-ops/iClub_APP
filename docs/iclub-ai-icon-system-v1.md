# iClub AI icon system v1 — production brief

Status: design specification; final SVG assets are not yet approved or uploaded.

## Why the current icon is temporary

The generic open-book-and-spark mark reads as a stock EdTech symbol. It does not create a distinctive iClub identity and becomes visually weak at 24–32 px. The premium demo therefore uses a restrained `AI` monogram as a temporary placeholder until the final icon family is uploaded.

## Primary direction: Knowledge Lens

The final iClub AI tutor mark should not be a literal open book, robot, chat bubble, mascot, or magic-wand symbol.

Use one distinctive abstract mark built from two curved page-like shapes that form a central lens or diamond. The negative space represents focused understanding. Add one small four-point spark only as a secondary detail.

The mark should communicate:

- academic guidance;
- clarity and verification;
- intelligence;
- progression;
- connection to iClub, not a separate AI brand.

## Geometry

- Base grid: 24 × 24.
- Safe area: 2 px on every side.
- Main stroke: 1.8 px at 24 px size.
- Rounded stroke caps and joins.
- Two mirrored curved shapes; do not draw page lines or book text.
- Central negative-space lens must remain open at 20–24 px.
- Spark: one four-point shape, maximum 5 × 5 px on the 24 px grid.
- No more than three visible components.
- Optical balance must be tested at 20, 24, 32, 40, and 48 px.

## Colour

Primary:

- dark navy `#173B72`;
- iClub blue `#2F6FD6`.

Supporting tile:

- white to pale blue `#FFFFFF → #EAF2FF`;
- border `rgba(47,111,214,0.18)`.

Do not use multicolour gradients inside the glyph. The icon must also work as a single-colour navy SVG.

## Icon family

All icons must share the same grid, stroke, corner language, and optical weight.

1. `iclub-ai-tutor.svg`
   - Primary Knowledge Lens mark.
   - Used in Subject Hub, tutor header, and empty state.

2. `iclub-ai-verified.svg`
   - Small lens or document shape combined with a check.
   - Used only for approved iClub answers.

3. `iclub-ai-live.svg`
   - Primary mark with a subtle active spark.
   - No animation required.

4. `iclub-ai-protected.svg`
   - Shield formed from the same curved geometry.
   - Used for Active Tour protection.

5. `iclub-ai-progress.svg`
   - Three connected nodes or a rising path using the same stroke language.
   - Used in Pro trajectory and diagnostics.

6. `iclub-ai-practice.svg`
   - Circular reinforcement path with one check point.
   - Used for “Закрепить в практике”.

## Required exports

For every icon:

- clean SVG with transparent background;
- `viewBox="0 0 24 24"`;
- no embedded raster image;
- no font dependency;
- no masks unless essential;
- no filters or heavy shadows inside SVG;
- strokes converted consistently or retained as editable strokes;
- one-colour and two-colour variants;
- PNG previews at 48, 96, and 192 px only for review.

## Visual tests before approval

The icon family is approved only if:

- the primary mark is recognisable at 24 px;
- the verified and protected states are distinguishable without text;
- all icons look like one family;
- none resembles a customer-support chat icon;
- none resembles a robot or children’s game mascot;
- the marks work on white, pale blue, and dark blue backgrounds;
- stroke weight remains consistent beside the existing iClub logo;
- the icon does not dominate the title or plan chip.

## Upload map

Final approved files should replace the temporary slots without changing layout:

- Subject Hub / tutor header / empty state → `iclub-ai-tutor.svg`
- verified badge → `iclub-ai-verified.svg`
- live answer → `iclub-ai-live.svg`
- Active Tour card → `iclub-ai-protected.svg`
- Pro trajectory → `iclub-ai-progress.svg`
- practice reinforcement → `iclub-ai-practice.svg`

Until these assets are approved, the demo must show the temporary AI monogram and must not present the current book illustration as final artwork.
