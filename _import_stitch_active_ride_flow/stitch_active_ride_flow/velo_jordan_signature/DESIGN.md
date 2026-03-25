# Design System Documentation: The Urban Monolith

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Urban Monolith."** 

This isn't a generic ride-hailing interface; it is an architectural editorial experience tailored for the Jordanian landscape. It draws inspiration from the juxtaposition of Amman’s ancient stone textures and the hyper-modern velocity of its transit. We reject the "template" look of flat boxes. Instead, we embrace **intentional asymmetry**, high-contrast typography, and depth through light rather than lines. The experience must feel like a premium concierge service—reliable, sleek, and authoritative.

### Design Principles
*   **RTL-First Integrity:** Layouts are not "mirrored" as an afterthought; they are composed starting from the right, ensuring the natural optical flow of Arabic typography guides the user’s eye.
*   **Architectural Weight:** Use substantial corner radii (`xl`: 3rem) and generous negative space to give elements a sense of "place" rather than just "placement."
*   **Price Radicalism:** Transparency is the ultimate luxury. Prices and estimate chips are treated as hero elements, never hidden or secondary.

---

## 2. Colors & Surface Philosophy
The palette utilizes the high-energy **Velo Rose (#E11D48)** against a foundation of **Deep Slate (#0F172A)** and **Soft Slate White (#F8FAFC)**.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to define sections. Layout boundaries must be achieved through background color shifts or tonal transitions.
*   Use `surface_container_low` (#f2f4f6) for the main page body.
*   Nest `surface_container_lowest` (#ffffff) cards within that body to create definition.
*   If a visual break is needed, use a `3.5rem` (`spacing.10`) vertical gap instead of a horizontal line.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. 
1.  **Base Layer:** `surface` (#f7f9fb)
2.  **Structural Sections:** `surface_container_low`
3.  **Actionable Cards:** `surface_container_lowest` (Highest prominence/White)
4.  **Overlays/Modals:** Semi-transparent `surface_bright` with a 20px backdrop blur (Glassmorphism).

### Signature Textures
For primary CTAs and Hero sections, do not use flat hex codes. Apply a subtle linear gradient from `primary` (#b80035) to `primary_container` (#e11d48) at a 135-degree angle. This adds "soul" and a sense of forward motion.

---

## 3. Typography
We use a dual-font system to bridge technical precision with editorial elegance.

*   **English/Latin:** **Inter/Outfit**. Use Outfit for `display` and `headline` levels to provide a rounded, premium feel. Use Inter for `body` and `label` for maximum legibility.
*   **Arabic:** **IBM Plex Sans Arabic**. This typeface provides a modern, Kufic-inspired structure that balances perfectly with the weight of the Latin counterparts.

### Typography Scale
*   **Display-LG (3.5rem):** Reserved for price estimates and welcome states.
*   **Headline-MD (1.75rem):** Used for Landmark titles (e.g., "Abdali Boulevard").
*   **Body-MD (0.875rem):** The workhorse for all descriptions and meta-data.
*   **Label-SM (0.6875rem):** Uppercase (Latin) or bold (Arabic) for non-interactive metadata.

---

## 4. Elevation & Depth
Depth is a function of light and layering, not shadows alone.

*   **Tonal Layering:** Achieve "lift" by placing a `surface_container_lowest` card on top of a `surface_dim` background. This creates a natural, soft contrast.
*   **Ambient Shadows:** For floating elements (e.g., the "Confirm Pickup" button), use an extra-diffused shadow: `0px 20px 40px rgba(15, 23, 42, 0.06)`. The shadow must use a tint of the `on_surface` color, never pure black.
*   **The "Ghost Border" Fallback:** If accessibility requires a container edge, use the `outline_variant` (#e5bdbe) at 15% opacity. It should be felt, not seen.
*   **Glassmorphism:** Navigation bars and floating estimate chips must use a semi-transparent `surface_container_lowest` with a `blur(12px)` effect to allow the map or content beneath to bleed through softly.

---

## 5. Components

### Estimate Chips
These are the signature of the system. 
*   **Style:** `surface_container_highest` background with a `primary` text color.
*   **Shape:** `full` (pill) radius.
*   **Behavior:** Place them adjacent to the destination input. They should feel like "live" data tags, providing immediate price transparency.

### Landmark Cards
*   **Structure:** No borders. Use `surface_container_lowest`.
*   **Radius:** `lg` (2rem).
*   **Content:** Large `title-md` for the landmark name, `body-sm` for the "Distance" and "Typical Price." 
*   **Interaction:** On hover/active, the background shifts to `secondary_container` (#dae2fd).

### Buttons
*   **Primary:** Gradient fill (`primary` to `primary_container`), `full` radius, white text. Minimum height `4rem`.
*   **Secondary:** `surface_container_highest` background, no border, `on_surface` text.
*   **Tertiary:** Transparent background with `primary` text. Use for "Change Route" or "Add Stop."

### Input Fields
*   **RTL Layout:** Icons (like the search magnifying glass) are placed on the left, while text aligns to the right.
*   **State:** Use `surface_container_high` for the idle state. On focus, shift to `surface_container_lowest` with a `ghost border` of `primary` at 20% opacity.

---

## 6. Do's and Don'ts

### Do
*   **Do** prioritize the Arabic script's line height. IBM Plex Sans Arabic requires more vertical breathing room than Inter.
*   **Do** use asymmetrical margins. A wider margin on the "start" (right) side of a layout can create a sophisticated, editorial look.
*   **Do** use `primary_fixed_dim` for subtle accents in "Luxury" tier selections.

### Don't
*   **Don't** use 1px dividers between list items. Use `spacing.4` (1.4rem) of vertical space to separate content chunks.
*   **Don't** use pure black (#000000) for text. Use `on_surface` (#191c1e) to maintain a high-end, soft-contrast feel.
*   **Don't** use standard "Drop Shadows." If an element doesn't feel elevated enough, increase the background contrast before adding a shadow.
*   **Don't** center-align text in RTL layouts unless it's a primary headline. Keep the alignment "Start" (Right).