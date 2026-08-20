# Type system

A single modular scale governs every asset in this profile. Nothing is sized by eye.

## Scale

Ratio **1.333** (perfect fourth), base 16 px. Steps rounded to whole pixels.

| Step | Size | Family | Weight | Tracking | Role |
|---|---|---|---|---|---|
| Display | 92 | serif | 700 | −3.5 | Name. One per page. |
| Title | 34 | serif | 700 | −0.8 | Card headings. |
| Subtitle | 25 | serif | 600 | −0.4 | Secondary headings. |
| Lead | 19 | sans | 400 | 0 | Opening statement of a block. |
| Body | 16 | sans | 400 | 0 | Running text. |
| Caption | 14 | serif italic | 0 | Notes, attribution. |
| Micro | 12 | sans | 700 | +6 | Uppercase eyebrows and labels. |

## Rules

**Tracking scales inversely with size.** Display type at 92 px needs −3.5 to close the
gaps that grow with the glyphs; micro type at 12 px needs +6 or the uppercase letters
collide. This is not decoration — it is optical correction.

**Contrast comes from the jump, not the gradient.** The step from 92 to 12 is
deliberate. Two extremes carry a page more cleanly than five middling sizes.

**Serif for statement, sans for information.** The name, the headings and the
epigraphs are serif — they are read once, slowly. Body, labels and data are sans —
they are scanned.

**Line length stays between 45 and 75 characters.** Beyond that the eye loses the
return sweep.

## Legibility over animation

No text sits directly on a moving background. Every text block rests on a **scrim**: a
translucent plate at 78–86% opacity with a hairline border, drawn between the animated
layer and the type.

The contract is that the reading is never at the mercy of the frame. Whatever moves
behind, the measured contrast against the scrim stays above 7:1 for body text and
above 4.5:1 for captions — the WCAG AAA and AA thresholds respectively.

Animation therefore lives in three places only: **behind the scrim**, **outside the
text column**, and **in the ornament** (the neon, the data pulses). Never under a word.
