# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Primary: Indonesian gamers aged 17–30, mostly students and young adults who play on PC and console, have large backlogs, and are price-sensitive. The PRD persona is Dimas, 21, a student with roughly 60 Steam games who buys on sale and forgets what he already owns; he wants to know which game to play next and when the game he is watching gets cheap.

The job: keep one trustworthy record of what they own and how far they got, decide what to play next from the backlog, and catch a discount at or below their target price.

## Product Purpose

MainGa? ("main apa hari ini?") is an Android app for managing a personal game collection and backlog while watching wishlist prices. It replaces the usual split between a catalogue app, a price tracker, and a notes file with one place to record play status, personal rating, hours, and notes, and to be told when a wishlisted game reaches the target price.

Success for the current horizon is a complete, demoable UAS deliverable: every Must-Have feature works end to end, black-box test cases pass, the SUS score reaches at least 68 with 15–30 respondents, price notifications fire exactly when the lowest price is at or below target, and cached search responds in under 3 seconds. The automated suites exist; SUS and black-box results are still pending (see Evidence on Hand).

## Positioning

The library and the price watch share the same game record, so a game already owned and a game being waited on do not live in separate applications. The backend owns the catalogue and price integrations (RAWG for game data, CheapShark for store prices), layers response and database caching over them, and exposes one authenticated API to the app; the client never calls an external game or price service directly.

A catalogue app cannot truthfully copy this without also holding the user's private play state, and a price tracker cannot copy it without holding the library.

## Operating Context

- Solo final project for the Mobile Application Programming course, S1 Information Systems, Universitas Negeri Surabaya; built on a 6–7 week timeline and judged through a live demo, a black-box test table, a SUS questionnaire, a written article draft, a YouTube demo, and the GitHub repository.
- Repository layout: `mobile/` Flutter app, `backend/` Laravel REST API + MySQL, `rules/` PRD and project rules, `README.md` as the running implementation record.
- The demo depends on a local Laravel backend reachable from the Android device over the LAN, MySQL running locally, and the scheduler started with `php artisan schedule:work` (or a manual artisan price-check command) so price drops and notifications can be shown live.
- Prices come from CheapShark in USD; the Rupiah figure is a fixed-rate estimate and must always be labelled as an estimate.
- Demo and test data can be produced by the backend seeders and simulated price commands rather than real purchases.

## Capabilities and Constraints

Implemented and verified by code reading (README stages 2–6): Sanctum authentication (register, login, logout); game search and browse with genre, platform, and minimum-rating filters, pagination, and two-layer caching; game detail with description, genres, platforms, rating, release date, and library status; personal library CRUD with the five statuses `Wishlist`, `Backlog`, `Sedang Dimainkan`, `Tamat`, `Dropped`, personal rating 1–10, non-negative play hours, notes, and automatic completion date; wishlist with a USD target price and active flag; multi-store price tracking with history chart; in-app price-drop notifications with unread count; play statistics (totals, completed per month, favourite genres); random backlog pick; similar-game recommendations from library genres; required "Data by RAWG" attribution linking to rawg.io on Explore and game detail.

Durable constraints:

- Android only, minimum Android 8.0. iOS and web are explicitly out of scope even though Flutter scaffolding folders exist.
- Stack is fixed: Flutter frontend, Laravel + Sanctum REST API, MySQL. Supabase and Firebase are forbidden, including Firebase push notifications; push is at most optional local notifications.
- Flutter talks only to its own backend; RAWG and CheapShark are called only by the backend. API keys live only in `.env` and must never reach the client, logs, README, or `.env.example` (placeholders only).
- No placeholder screens, dead controls, or empty stubs: anything shipped must run, because the demo and black-box tests are the proof.
- Currency: prices and target prices are stored and compared in USD; Rupiah is an estimate at a fixed configured rate.
- Interface copy is Bahasa Indonesia only; no localization layer is planned.
- Status terminology is fixed by the PRD and must stay consistent across API, filters, chips, and validation.
- Optional scope not built: release calendar (F-12), public shareable profile (F-13), local push notifications (F-14). Do not imply they exist.

## Brand Commitments

- Name is written `MainGa?`, with the question mark as part of the wordmark; it comes from the everyday gamer question "main apa hari ini?".
- A dark theme is a binding project rule from `rules_mainga.md`, together with the required, clickable "Data by RAWG" attribution. The incumbent black/white/lime visual identity is implemented in `lib/core/theme/` and is treated as current identity, not as a new direction.
- Voice is Indonesian, direct, and non-technical, addressing the user as "kamu"; product copy avoids stage/version language and developer phrasing.

## Evidence on Hand

- Full PRD at `rules/PRD_MainGA.md` (personas, user stories, MoSCoW priorities, data model, endpoints, risks, timeline) and binding project rules at `rules/rules_mainga.md`.
- Detailed implementation record in `README.md`, including design-system decisions and colour-token tables.
- Automated tests only: Laravel feature tests under `backend/tests/Feature/` and Flutter unit/widget tests under `mobile/test/`, recorded in the README as passing.
- Missing and must not be fabricated: SUS results, black-box result tables, real user quotes or testimonials, usage analytics, published article, or demo video. The PRD targets (SUS ≥ 68, 15–30 respondents, search < 3 s) are plans, not evidence.

## Product Principles

1. One place, not four: library state, price watch, and play history stay attached to the same game record; never push a core step into another app.
2. Answer "main apa hari ini?" quickly: the next game to play and the buy-or-wait decision should be reachable in a few taps from the main tabs.
3. The student budget is the point: discount and target-price clarity outrank catalogue breadth, and USD versus Rupiah estimates are never ambiguous.
4. The backend is the trust boundary: secrets, external APIs, caching, and business rules stay server-side; the client only sees its own authenticated API.
5. Everything shown must run: prefer a smaller working feature over a polished placeholder, because the demo and black-box tests are the deliverable.
6. Extend the incumbent app, not a new product: Indonesian copy, the five statuses, and the existing navigation survive redesigns unless the owner explicitly changes them.

## Accessibility & Inclusion

- WCAG AA contrast is a self-imposed requirement in the current implementation, including black text on lime accents and secondary text on dark surfaces; status colours are deliberately desaturated so they do not compete with the accent.
- Touch targets of at least 48dp, layouts that survive text scale 1.3, and animations that honour the platform reduce-motion setting.
- Android 8.0+ is the compatibility floor; the app is designed for phone-sized screens, not tablets or desktop.
