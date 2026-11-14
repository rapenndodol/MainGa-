---
name: MainGa?
description: A dark, poster-led Android game library where one lime control answers "main apa hari ini?"
colors:
  void-black: "#0B0B0C"
  carbon-card: "#141416"
  raised-carbon: "#1C1C1F"
  carbon-highlight: "#26262B"
  field-carbon: "#141416"
  ash-border: "#2A2A2E"
  lime-border: "#C6F432"
  voltage-lime: "#C6F432"
  lime-dim: "#1F280D"
  lime-filament: "#D4F75A"
  ink-on-lime: "#0B0B0C"
  pure-white: "#FFFFFF"
  ink-on-white: "#0B0B0C"
  secondary-carbon: "#1C1C1F"
  text-white: "#FFFFFF"
  text-ash: "#FFFFFFA6"
  text-faint: "#FFFFFF61"
  text-off: "#FFFFFF61"
  universal-white: "#FFFFFF"
  universal-black: "#000000"
  transparent: "#00000000"
  signal-gold: "#E5B842"
  fault-red: "#E05353"
  confirm-green: "#4DA87D"
  status-playing: "#D9736C"
  status-completed: "#4DA87D"
  status-backlog: "#D1C7B7"
  status-wishlist: "#D9A55B"
  status-dropped: "#8E8E93"
  chart-completed: "#C6F432"
  chart-price: "#C6F432"
  chart-slice-1: "#C6F432"
  chart-slice-2: "#FFFFFF"
  chart-slice-3: "#A1A1A6"
  chart-slice-4: "#6B6B70"
  chart-slice-5: "#3A3A3F"
typography:
  display-large:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "32px"
    fontWeight: 800
    lineHeight: 1.15
    letterSpacing: "-0.8px"
  display-medium:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "26px"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "-0.5px"
  title-large:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "-0.2px"
  title-medium:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.1px"
  title-small:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.35
  body-large:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.55
  body-medium:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  body-small:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.45
  label-large:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "14px"
    fontWeight: 700
    letterSpacing: "0.1px"
  label-medium:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "12px"
    fontWeight: 600
    letterSpacing: "0.1px"
  label-small:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "11px"
    fontWeight: 500
    letterSpacing: "0.1px"
  overline:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "11px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "1.4px"
  metric-large:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "28px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-0.6px"
  metric-medium:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.3px"
rounded:
  sm: "8px"
  md: "14px"
  lg: "20px"
  xl: "24px"
  full: "999px"
  control: "8px"
  control-large: "14px"
  card: "20px"
  sheet: "24px"
  pill: "999px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  xxl: "28px"
  huge: "36px"
  section: "32px"
  screen: "20px"
components:
  button-primary:
    backgroundColor: "{colors.voltage-lime}"
    textColor: "{colors.ink-on-lime}"
    typography: "{typography.label-large}"
    rounded: "{rounded.full}"
    height: "50px"
    padding: "0 20px"
  button-secondary:
    backgroundColor: "{colors.raised-carbon}"
    textColor: "{colors.text-white}"
    typography: "{typography.label-large}"
    rounded: "{rounded.full}"
    height: "50px"
    padding: "0 20px"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.text-white}"
    typography: "{typography.label-large}"
    rounded: "{rounded.full}"
    height: "50px"
    padding: "0 20px"
  button-destructive:
    backgroundColor: "rgba(224, 83, 83, 0.15)"
    textColor: "{colors.fault-red}"
    typography: "{typography.label-large}"
    rounded: "{rounded.full}"
    height: "50px"
    padding: "0 20px"
  chip-filter-active:
    backgroundColor: "{colors.pure-white}"
    textColor: "{colors.ink-on-white}"
    typography: "{typography.label-medium}"
    rounded: "{rounded.pill}"
    padding: "4px 12px"
  chip-status:
    backgroundColor: "rgba(217, 115, 108, 0.12)"
    textColor: "{colors.status-playing}"
    typography: "{typography.label-small}"
    rounded: "{rounded.pill}"
    padding: "7px 12px"
  input-field:
    backgroundColor: "{colors.field-carbon}"
    textColor: "{colors.text-white}"
    typography: "{typography.body-large}"
    rounded: "{rounded.control-large}"
    padding: "18px 16px"
  card-library:
    backgroundColor: "{colors.carbon-card}"
    textColor: "{colors.text-white}"
    rounded: "{rounded.card}"
    padding: "12px"
  navigation-dock:
    backgroundColor: "rgba(28, 28, 31, 0.98)"
    textColor: "{colors.text-faint}"
    typography: "{typography.label-small}"
    rounded: "{rounded.pill}"
    height: "72px"
  badge-neutral:
    backgroundColor: "{colors.raised-carbon}"
    textColor: "{colors.text-ash}"
    typography: "{typography.label-small}"
    rounded: "{rounded.pill}"
    padding: "6px 12px"
---

# Design System: MainGa?

## Overview

**Creative North Star: "The Night Arcade"**

MainGa? is a dark room with the games lit and the furniture invisible. The canvas is near-black carbon, the game covers are the only photography, and a single voltage-lime control marks the thing you can press. Everything else — chrome, metadata, dividers, secondary buttons — sits in graphite steps and 65%-white text so it can be scanned without competing with the posters. The metaphor is an arcade at night: many cabinets, one lit coin slot.

The system is deliberately flat and tonal. Depth is expressed by stepping the surface (near-black → graphite → raised graphite), not by shadows, gradients, or glow. Lime is rationed under a 60-30-10 rule: black owns the room, white carries text and selection, lime appears on roughly one tenth of a screen and always means "act here" or "active now". The product's question — *main apa hari ini?* — is answered by hierarchy, not decoration: a bold title, a poster, a status chip, a price.

The interface voice is Indonesian, direct, and non-technical. The visual register follows: no gamified badges, no RGB, no storefront merchandising. This is a personal ledger presented like a curated shelf.

**Key Characteristics:**
- Near-black canvas with three graphite surface steps as the only depth system.
- One accent: voltage lime at ≤10% of the view, always paired with near-black ink.
- Poster-led lists: 3:4 game covers carry the imagery; typography stays quiet around them.
- Pill controls against 20px content surfaces; 1px ash hairlines instead of shadows.
- Tabular numerals for every changing value: prices, hours, ratings, counters.
- Motion is short (150–300 ms), cubic ease-out, and disabled under reduce-motion.
- Indonesian copy in sentence case; status names are fixed terms, never synonyms.

## Colors

Carbon, white, and one voltage lime, distributed 60-30-10; functional colors are desaturated so they never rival the accent.

### Primary
- **Voltage Lime** (`#C6F432`, `primary`): the only accent. Filled primary buttons, the active tab pill in the floating dock, focused input borders (1.5px), active switch and slider tracks, the 6px section-header dot, and chart accents. Never a page background and never paragraph text.
- **Dim Lime** (`#1F280D`, `primaryContainer`): the quiet container behind lime icons and price highlights; used as fill, not as a text color.
- **Lime Filament** (`#D4F75A`, `primaryLight`): the lighter lime used for chart dots, discount percentages, and price emphasis where the base lime needs a second step.
- **Lime Border** (`#C6F432`, `borderFocused`): the focus ring on inputs, at 1.5px.
- **Ink on Lime** (`#0B0B0C`, `onPrimary`): all text, icons, and spinners that sit on lime.

### Secondary
- **Pure White** (`#FFFFFF`, `secondary`): the selected filter-chip fill (with near-black label), the second donut slice, and the 30% layer that carries text, icons, and outlines. White is a material, not an alternative accent.
- **Secondary Carbon** (`#1C1C1F`, `secondaryContainer`): the dark raised container paired with white; it matches the raised surface so secondary elements sit on the same tone step.

### Neutral
- **Void Black** (`#0B0B0C`, `bg`): scaffold, app bar, and the ink placed on lime.
- **Carbon Card** (`#141416`, `surface`): the standard card and input surface — tone step 1.
- **Raised Carbon** (`#1C1C1F`, `surfaceElevated`): sheets, dialogs, the floating dock, badges, and the top of the skeleton pulse — tone step 2.
- **Carbon Highlight** (`#26262B`, `surfaceHighlight`): tooltip and highlight containers — tone step 3.
- **Ash Border** (`#2A2A2E`, `border`): the 1px hairline on cards, inputs, and dividers; 1.2px on the dock and sheet edges.
- **Text White** (`#FFFFFF`, `textPrimary`): titles and primary values.
- **Text Ash** (`#FFFFFFA6`, `textSecondary`): 65% white for descriptions, subtitles, and metadata labels.
- **Text Faint** (`#FFFFFF61`, `textMuted`): 38% white for timestamps, helper text, and inactive icons.
- **Text Off** (`#FFFFFF61`, `textDisabled`): the same 38% white, reserved for disabled states.
- **Universal Black** (`#000000`, `black`): the 60% modal barrier and the dock's shadow color only.

### Functional
- **Signal Gold** (`#E5B842`, `ratingStar`): star ratings and the personal-rating slider; 15% tint for the badge fill.
- **Fault Red** (`#E05353`, `error`): validation errors, error snackbars, destructive text and buttons.
- **Confirm Green** (`#4DA87D`, `success`): success feedback, completed dates, and the "target reached" state.
- **Status Playing** (`#D9736C`, `statusPlaying`): muted coral for *Sedang Dimainkan*.
- **Status Completed** (`#4DA87D`, `statusCompleted`): muted forest green for *Tamat*.
- **Status Backlog** (`#D1C7B7`, `statusBacklog`): muted stone beige for *Backlog*.
- **Status Wishlist** (`#D9A55B`, `statusWishlist`): muted warm amber for *Wishlist*.
- **Status Dropped** (`#8E8E93`, `statusDropped`): muted slate for *Dropped*.

### Chart
- **Chart Lime** (`#C6F432`, `chartCompletedBar`, `chartPriceLine`, `chartDonutSlice1`): bars, price line, and first donut slice.
- **Chart Greys** (`#FFFFFF` slice 2, `#A1A1A6` slice 3, `#6B6B70` slice 4, `#3A3A3F` slice 5): a descending neutral ramp for remaining genres.

### Named Rules
**The One Lit Cabinet Rule.** Lime occupies at most about a tenth of any screen. It may fill a button, a tab pill, a focus ring, or a data mark; it may never fill a page, app bar, card, or paragraph.

**The Black-on-Lime Rule.** Everything placed on lime uses `#0B0B0C`. White on lime is forbidden: contrast collapses to roughly 1.2:1.

**The Desaturated Witness Rule.** Status and functional colors appear only as 12–25% tinted chips, badges, and icons. They never become large surfaces, and they never outshine lime.

## Typography

**Display Font:** Plus Jakarta Sans (via `google_fonts`)
**Body Font:** Plus Jakarta Sans, same family across every role
**Label/Mono Font:** Plus Jakarta Sans; numerals are tabular, not a separate face

**Character:** One geometric-humanist family doing all the work. Display and titles are heavy and slightly negative-tracked for a confident, poster-caption voice; body text is regular, airy, and 65% white; labels are small, tight, and used for dense metadata. There is no serif, no display script, and no second family.

### Hierarchy
- **Display Large** (800, 32px, 1.15, −0.8px): screen-defining numbers, hero amounts, the largest single statement on a view.
- **Display Medium** (800, 26px, 1.2, −0.5px): secondary hero values and prominent section leads.
- **Title Large** (700, 20px, 1.3, −0.2px): app-bar titles, empty-state titles, major card titles.
- **Title Medium** (600, 16px, 1.3, −0.1px): list-item game titles, section headers, sheet headings.
- **Title Small** (600, 14px, 1.35): field-group labels inside sheets, compact card headings.
- **Body Large** (400, 16px, 1.55): input text and long descriptions.
- **Body Medium** (400, 14px, 1.5): standard reading text, descriptions, dialog content.
- **Body Small** (400, 12px, 1.45): metadata, timestamps, helper copy, chart axes.
- **Label Large** (700, 14px, +0.1px): all button labels.
- **Label Medium** (600, 12px, +0.1px): chips, small field labels, inline actions.
- **Label Small** (500, 11px, +0.1px): badges, counters, tab labels, dense metadata.
- **Overline** (700, 11px, 1.3, +1.4px): eyebrow labels; the widget must uppercase the string itself.
- **Metric Large** (800, 28px, 1.1, −0.6px, tabular): statistics cards.
- **Metric Medium** (700, 20px, 1.15, −0.3px, tabular): ratings, prices, and inline counters.

### Named Rules
**The Tabular Truth Rule.** Any number that can change while the user watches — price, hours, rating, counters — uses tabular figures (`FontFeature.tabularFigures()`), so digits do not shift width between frames.

**The Two-Tone Text Rule.** Primary copy is `#FFFFFF`; everything secondary is `#FFFFFFA6`. Muted metadata drops to `#FFFFFF61`. Lime is never used for body copy, only for emphasis on a value that is already short.

## Layout

A single phone column, Android-first, from 360dp upward. Screens use 16dp horizontal gutters with 12dp vertical breathing (`AppSpacing.screenPadding`); form and detail pages open up to 20dp/16dp (`screenPaddingWide`). Content is never boxed in a max-width container on phones; empty states cap themselves at 360dp so the message stays readable.

The spacing rhythm is 2 / 4 / 8 / 12 / 16 / 20 / 28 / 36, with 32dp between major sections. Cards pad 12–16dp internally; list rows use 16dp horizontal and 12dp vertical. Game rows are fixed-height compositions: an 88×118 cover (3:4) with a 14dp gap and a 118dp text column; library cards use a 78×106 cover.

Navigation is a floating dock, not a bar: 72dp tall, 16dp side margins, 16dp above the system inset, overhanging content because the scaffold extends the body behind it. The four destinations — Jelajah, Library, Wishlist, Profil — keep labels visible at all times. The top app bar is 60dp, or 76dp when it carries a subtitle.

### Named Rules
**The One Column Rule.** No multi-column grids, no side-by-side content panels, no tablet reflow. Lists are single-column and full-bleed to the gutters; the screen is a shelf, not a dashboard.

**The 16-Gutter Rule.** Every screen edge starts at 16dp. Nested padding may add 8 or 12, but nothing may reduce the gutter below 16dp on a phone.

## Elevation & Depth

Flat by construction. There are no card shadows, no gradients for depth, and no arbitrary blur. Depth comes from tone steps: `#0B0B0C` (page) → `#141416` (card/input) → `#1C1C1F` (sheet, dialog, dock, badge) → `#26262B` (highlight/tooltip). A 1px `#2A2A2E` hairline does the contour work that a shadow would do elsewhere. Material elevation is set to 0 everywhere, and surface tint is transparent.

Exactly one element casts a shadow: the floating navigation dock (`0 10px 24px rgba(0, 0, 0, 0.55)`), because it must detach from scrolling content. The modal barrier is `rgba(0, 0, 0, 0.6)`.

### Shadow Vocabulary
- **Dock only** (`0 10px 24px rgba(0, 0, 0, 0.55)`): the floating tab dock; nothing else.

### Named Rules
**The Tone-Step Rule.** When something must feel closer, raise its surface one step and add or strengthen a 1px border. Do not reach for a shadow.

**The One Shadow Rule.** The dock is the only shadowed object in the product. If a new surface needs a shadow to read, the surface choice is wrong.

## Shapes

Corners split by job. Everything interactive is a pill (999px): buttons, chips, badges, the nav dock, the active-tab indicator, the RAWG attribution. Everything that holds content is a rounded rectangle: 20px for cards and panels, 24px for sheets and dialogs (top corners only on bottom sheets), 14px for media and inner surfaces, 8px for small controls and thumbnails.

Borders are thin and constant: 1px for hairlines, 1.2px for the dock and sheet outlines, 1.5px for focused inputs. There are no double borders, no thick outlines, and no decorative strokes. Recurring gestures: 3:4 portrait covers, circles for avatars and store icons (32–38px), an 80px circle for empty-state icons, and a 6px lime dot before every section header.

### Named Rules
**The Pill-for-Controls Rule.** If the user can press it, it is a pill. If the user reads inside it, it is a 20px rectangle. Never invert the two.

**The Poster Crop Rule.** Game imagery is always a 3:4 portrait crop (88×118, 78×106, 50×66) with a 14px radius or smaller. No landscape banners, no full-bleed hero photography.

## Components

Material 3 supplies the behavior — ripples, switches, sliders, sheets, dialogs, snackbars — and the theme restyles color and shape only. Nothing is ported from iOS.

### Buttons
- **Shape:** pill (999px), 50dp default height, 48dp compact, 52dp for the primary save action in sheets. Horizontal padding 20dp; label in Label Large with 18dp leading icon and 8dp gaps.
- **Primary:** voltage lime fill with near-black ink. One per view; it is the only filled-lime object on the screen.
- **Hover / Focus:** press feedback is a 0.98 scale over 150ms ease-out plus an 8% ink overlay and a light haptic; no color change. Disabled: 45% base alpha, 50% label alpha (theme buttons use 35%/50%).
- **Secondary:** raised carbon fill, 1px ash border, white label. **Outline:** transparent fill, 1.2px ash border, white label. **Destructive:** 15% fault-red fill, 40% red border, red label. **Ghost:** transparent, no border, white label.
- **Motion:** 150ms scale, 220ms state changes, 300ms entrances; all ease-out cubic, all skipped when the OS asks for reduced motion.

### Chips
- **Style:** pill, 12dp horizontal padding, 4dp vertical, icon 12–14dp, label 11–12dp bold.
- **Filter — selected:** pure white fill with near-black label. **Filter — unselected:** raised carbon fill, 1px ash border, 65% white label.
- **Status:** tinted by the five status colors at 12% fill / 35% border (25% / 100% when selected), icon and label in the full status color. The minimum tap target stays 48dp even though the chip is visually smaller.

### Cards / Containers
- **Corner Style:** 20px for library, wishlist, stats, and price cards; 14px for inner media and nested panels.
- **Background:** `#141416` on the `#0B0B0C` page; sheets and dialogs step up to `#1C1C1F`.
- **Shadow Strategy:** none — see Elevation & Depth.
- **Border:** 1px `#2A2A2E`; a success state may promote the border to 50% green.
- **Internal Padding:** 12dp for dense list cards, 16dp for content cards and sheets, 20dp horizontal inside bottom sheets.
- **Game row:** borderless editorial variant (Explore) with an 88×118 poster, title at Title Medium 700, one line of genre, and a footer of rating badge, year, and first platform. The library variant is a bordered card with a 78×106 cover, status chip, personal rating, hours, and a one-line note preview.

### Inputs / Fields
- **Style:** filled `#141416`, 1px `#2A2A2E`, 14px radius in the shared `AppTextField` (the global `InputDecorationTheme` uses 20px), 16dp horizontal and 18dp vertical padding. The label sits above the field at Label Medium; the hint is 65–38% white.
- **Focus:** 1.5px lime border, lime cursor, lime selection at 25%. No glow.
- **Error / Disabled:** 1px fault red (1.5px when focused); disabled border is the ash line at 50%.
- **Password:** visibility toggle keeps a 48dp suffix target.

### Navigation
- **Style:** floating pill dock, 72dp tall, 16dp margins, `rgba(28,28,31,0.98)` fill, 1.2px ash border, the single dock shadow, 16dp above the system inset.
- **Behavior:** the lime active pill slides between destinations over 220ms ease-out; the active icon switches from outlined to filled and turns near-black on lime; labels are always visible at 10.5dp, 800 weight when active, 38% white when idle. Selection emits `HapticFeedback.selectionClick()`.
- **Top bar:** background `#0B0B0C`, 0 elevation, title at 20px/700, 16dp title spacing, back arrow 18dp. It never hides the system Back gesture.

### Badges & Attribution
- **Badge:** pill, 12dp horizontal / 6dp vertical, 15% tint of its semantic color, 35% border, 11–12dp tabular label. Rating badges use signal gold with a star icon.
- **RAWG attribution:** centered pill on `#1C1C1F` with a 70% ash border and a 48dp minimum height; "Data by RAWG.io" in 11dp secondary text with an underlined, clickable `RAWG.io`. It is required on Explore and game detail and must never be hidden, restyled into a footnote, or removed.

### Loading & Charts
- **Skeleton:** `#141416` → `#1C1C1F` pulse over 1100ms ease-in-out, 0.25-alpha border; frozen at 35% blend under reduce-motion.
- **Charts:** lime line or bars on `#141416`, grid at 50% ash, labels 10dp muted, tooltip on `#1C1C1F`, price-line area a 25%→0% lime vertical gradient (the only gradient permitted).

## Do's and Don'ts

### Do:
- **Do** hold lime to roughly a tenth of the screen and reserve it for the primary action, the active tab, focus, and data marks.
- **Do** place near-black `#0B0B0C` ink on every lime surface.
- **Do** build depth with the `#0B0B0C` → `#141416` → `#1C1C1F` → `#26262B` steps and 1px `#2A2A2E` hairlines.
- **Do** use 20px radii for content surfaces and 999px for every pressable control.
- **Do** keep game covers at a 3:4 portrait crop.
- **Do** use Plus Jakarta Sans at the documented role sizes, with tabular figures for prices, hours, ratings, and counters.
- **Do** keep touch targets at 48dp or larger, layouts legible at font scale 1.3, and motion disabled when reduce-motion is on.
- **Do** keep the five status terms exact: `Wishlist`, `Backlog`, `Sedang Dimainkan`, `Tamat`, `Dropped`.

### Don't:
- **Don't** use white text or icons on lime; the contrast is unreadable.
- **Don't** use lime as a page, app-bar, card, or paragraph background.
- **Don't** introduce RGB gamer neon, glow, neon gradients, or a second accent color.
- **Don't** add drop shadows to cards, sheets, buttons, or inputs; the dock is the only shadow.
- **Don't** hardcode colors outside `lib/core/theme/app_colors.dart`, and don't bypass `AppTypography`, `AppSpacing`, `AppRadius`, or `AppMotion` with magic numbers.
- **Don't** turn status colors into large fills, progress bars, or decorative blocks; keep them at 12–25% tint.
- **Don't** use emoji, sticker badges, gamified trophies, or storefront-style promo banners.
- **Don't** port iOS controls, hide the system Back gesture, or replace the floating dock with a stock Material navigation bar.
- **Don't** fabricate numbers, ratings, prices, or SUS/test results to fill a layout; empty and loading states are part of the system.
