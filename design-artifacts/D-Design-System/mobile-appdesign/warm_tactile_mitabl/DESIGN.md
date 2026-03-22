# Design System Strategy: The Culinary Atelier

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Culinary Atelier."** 

Moving away from the sterile, grid-locked nature of standard food apps, this system treats the digital interface like a physical kitchen counter—warm, tactile, and layered. We avoid the "template" look by embracing **Intentional Asymmetry**. Elements should feel "placed" rather than "plugged in." By utilizing overlapping components, varying image aspect ratios, and high-contrast typography scales, we create an editorial experience that feels premium yet approachable. The goal is to make the user feel like they are flipping through a high-end, bespoke cookbook rather than browsing a database.

---

## 2. Color & Surface Philosophy
The palette is rooted in earth tones, designed to evoke the raw ingredients of a kitchen: clay, grain, and herbs.

### The "No-Line" Rule
**Explicit Instruction:** Use of 1px solid borders for sectioning is strictly prohibited. 
Boundaries must be defined through background color shifts. For example, a `surface-container-low` (#f6f3ee) card sits on a `surface` (#fcf9f4) background. If a container needs more prominence, use a tonal transition rather than a structural line. This maintains the "organic and friendly" feel by removing clinical, sharp dividers.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine linen paper.
- **Base:** `surface` (#fcf9f4)
- **Secondary Areas:** `surface-container-low` (#f6f3ee) for subtle grouping.
- **Active Cards:** `surface-container-lowest` (#ffffff) to provide a "lifted" feel.
- **Interactive Modals:** Use `surface-bright` (#fcf9f4) to maintain the warmth even in high-focus states.

### The "Glass & Soul" Rule
To prevent the flat look of standard Material Design, use **Glassmorphism** for floating navigation bars or sticky headers.
- **Token:** `surface` at 80% opacity with a `20px` backdrop-blur.
- **Signature Textures:** Apply a subtle linear gradient to Hero CTA buttons, transitioning from `primary` (#9c3e20) to `primary-container` (#bc5636) at a 135-degree angle. This adds "visual soul" and depth.

---

## 3. Typography: Editorial Authority
The typography pairing balances the "playful" nature of a home cook with the "authority" of a professional chef.

*   **Headings (Nunito, 800 Weight):** Use for `display` and `headline` levels. The rounded terminals of Nunito mirror the 20px card radii, creating a cohesive "rounded" visual language. 
    *   *Strategic Use:* Large `display-lg` (3.5rem) should be used for recipe titles to dominate the screen and provide an editorial focal point.
*   **Body (DM Sans):** Use for `title`, `body`, and `label` levels. DM Sans provides a clean, geometric counterpoint to the soft headings, ensuring high legibility for long-form recipe instructions.
*   **Contrast Hierarchy:** Always pair a `headline-lg` in `on-surface` (#1c1c19) with a `body-md` in `on-surface-variant` (#56423c) to create a sophisticated, low-fatigue reading experience.

---

## 4. Elevation & Depth: Tonal Layering
We move away from traditional shadows in favor of **Tonal Layering**.

*   **The Layering Principle:** Place a `surface-container-lowest` (#ffffff) card on a `surface-container-low` (#f6f3ee) background. The delta in brightness creates a natural, soft lift without the "heaviness" of a shadow.
*   **Ambient Shadows:** When a floating element (like a FAB or Popover) requires a shadow, use the following:
    *   **Blur:** 24px - 40px
    *   **Opacity:** 6%
    *   **Color:** Use a tinted version of `on-surface` (#1c1c19) to mimic natural light filtered through a kitchen window.
*   **The "Ghost Border":** If accessibility requires a border, use `outline-variant` (#ddc0b8) at **15% opacity**. Never use 100% opaque borders.

---

## 5. Components: Tactile Primitives

### Buttons & Chips
- **Primary Button:** 100px pill shape (`full` roundedness). Background: `primary` (#9c3e20). Text: `on-primary` (#ffffff).
- **Secondary Button:** 100px pill shape. Background: `secondary-container` (#cce7c3). Text: `on-secondary-container` (#51694c).
- **Interactive Chips:** Use for "Dietary Prefs" or "Cook Time." Use `tertiary-fixed-dim` (#d9c2b6) for unselected states and `primary` for selected.

### Cards & Lists
- **The "No-Divider" Rule:** Forbid 1px horizontal lines between list items. Instead, use a `1.4rem` (Spacing 4) vertical gap or alternating `surface-container` background tints.
- **Card Radius:** Strictly `1.25rem` (20px) for all content cards.
- **Nesting:** Small "Quick Info" chips inside cards should use `sm` (0.5rem) radius to create a nested hierarchy of shapes.

### Input Fields
- **Styling:** Use `surface-container-low` as the fill. No bottom line. Use a `1rem` (DEFAULT) corner radius.
- **Focus State:** Transition the background to `surface-container-lowest` and add a `2px` ghost border of `primary` at 20% opacity.

---

## 6. Do’s and Don'ts

### Do:
- **Do** embrace white space. Use the Spacing Scale (especially `8` and `12`) to let high-quality food photography breathe.
- **Do** use "Warm Oat" (#F7F4EF) as your primary canvas color to keep the app feeling tactile and soft.
- **Do** allow images to break the container. A "floating" herb leaf or a partially cropped plate adds to the "Atelier" aesthetic.

### Don't:
- **Don't** use pure black (#000000) for text. Use "Roasted Espresso" (`on-surface`) for all high-contrast needs.
- **Don't** use standard 4px or 8px radii. This system relies on the "Oversized Softness" of 20px and Pill shapes.
- **Don't** use "Drop Shadows" on cards. Use Tonal Layering (Surface Shifts) instead.