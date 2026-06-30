# Peregrino PoC — PRD

## What we're building

Three milestones that prove the core loop:

**location → narrative → audio → movement → repeat**.

- **Phase 1** — User presses Start, grants location, hears the app speak about
  where they are
- **Phase 2** — Moving 200m+ triggers a new segment automatically
- **Phase 3** — When a segment ends with no movement, user picks a topic
  (History / Nature / Industry) and the next segment reflects it

---

## Success criteria

- User on a real device presses Start and hears audio within 5 seconds
- Movement of 200m+ triggers a new segment without touching the screen
- Selecting a topic shapes the next segment's content
- All behaviour is covered by passing feature specs before implementation ships

---

## Phase 1 — The Presence

**User journey**

1. User opens `/` — sees the Peregrino wordmark and a single Start button
2. Taps Start — browser asks for location permission
3. On grant, coordinates POST to the server
4. Server reverse-geocodes the position (Nominatim), fetches the Wikipedia
   summary for that place, assembles a short paragraph
5. Server returns the text; browser reads it aloud via `SpeechSynthesis`
6. User hears: _"You're near Fitzroy. Originally settled by the Wurundjeri people…"_

**Feature specs**

- `spec/features/journey/starting_a_journey_spec.rb`
  - `it "shows a start screen with a single call to action"`
  - `it "requests location permission on start"`
  - `it "begins speaking after location is granted"`
- `spec/features/journey/hearing_location_narrative_spec.rb`
  - `it "fetches a narrative for the current coordinates"`
  - `it "audio element is present and active during playback"`
  - `it "falls back gracefully when Wikipedia returns no result"`

**Page objects**

- `Pages::StartScreen` — wordmark, start button
- `Pages::Journey` — audio state, status text

---

## Phase 2 — The Movement

**User journey**

1. While audio plays, a Stimulus controller polls `watchPosition` every 10 seconds
2. When Haversine distance from last known position exceeds 200m, POST new coordinates
3. Server assembles a segment for the new location
4. Segment queues; plays when the current one ends
5. User never touches the screen — the narrative shifts as they move

**Feature specs**

- `spec/features/journey/continuing_a_journey_spec.rb`
  - `it "detects a significant position change during playback"`
  - `it "queues a new segment on location change"`
  - `it "transitions to next segment without user interaction"`
- `spec/features/journey/ignoring_minor_movement_spec.rb`
  - `it "does not request a new segment for movement under 200m"`

---

## Phase 3 — The Conversation

**User journey**

1. Segment ends with nothing queued and no recent location change
2. Three topic chips appear: History · Nature · Industry (plus silent Skip)
3. User taps a chip or waits 8 seconds (auto-skip)
4. Next segment generated with selected interest as a bias to the narrative pipeline
5. Preference remembered for the rest of the session

**Feature specs**

- `spec/features/journey/choosing_what_to_hear_spec.rb`
  - `it "shows topic chips when a segment ends with no queued segment"`
  - `it "selecting History generates a history-biased next segment"`
  - `it "auto-skips after 8 seconds and resumes neutral narration"`
  - `it "remembers preference for subsequent segments"`

---

## Build order

Write the spec first, watch it fail, implement until it passes.

1. **Route + controller** — `root "journey#start"`, bare view with wordmark and
   Start button
   - drives: `starting_a_journey_spec.rb` — "shows a start screen"

2. **Page objects** — `Pages::StartScreen` and stub `Pages::Journey` in
   `spec/support/pages/`
   - needed before any further specs

3. **Geolocation Stimulus controller** — on Start click, call
   `getCurrentPosition`, POST coordinates, set a data attribute the spec can
   observe. Mock geolocation in specs via `page.execute_script`.
   - drives: `starting_a_journey_spec.rb` — "requests location", "begins speaking"

4. **Narrative endpoint** — `POST /journey/narrate` accepts `lat`/`lon`, returns
   JSON. Stub the Wikipedia call for now, return a hardcoded paragraph. Use
   WebMock in specs.
   - drives: `hearing_location_narrative_spec.rb` — "fetches a narrative"

5. **Wikipedia + Nominatim** — wire real APIs. `LocationNarrative.for(lat:,
lon:)` does reverse-geocode → place name → Wikipedia summary. Wrap in VCR
   cassettes for specs.
   - drives: `hearing_location_narrative_spec.rb` — VCR cassettes

6. **Browser speech playback** — on narrative response, call
   `speechSynthesis.speak(...)`. Dispatch `journey:speaking` and
   `journey:finished` DOM events so Capybara can observe state without touching
   actual audio.
   - drives: `starting_a_journey_spec.rb` — "audio element is present and active"

7. **Movement detection** — `watchPosition` in the controller, Haversine check,
   POST when >200m. Spec injects two sequential mock positions via script.
   - drives: `continuing_a_journey_spec.rb`, `ignoring_minor_movement_spec.rb`

8. **Segment queue** — controller holds an array of pending narrative strings.
   `journey:finished` dequeues and speaks next. Empty queue + no pending
   location → emit `journey:idle`.
   - drives: `continuing_a_journey_spec.rb` — "transitions to next segment"

9. **Topic chips UI** — on `journey:idle`, reveal chips via Stimulus target.
   8-second countdown in controller, on expiry emit `journey:skip` and hide.
   Spec clicks chip, asserts POST includes `interest: "history"`.
   - drives: `choosing_what_to_hear_spec.rb`

10. **Interest-biased narrative** — pass `interest` through to
    `LocationNarrative.for(lat:, lon:, interest:)`. History → Wikipedia history
    section. Nature → nearest reserve via Nominatim categories. Industry →
    Wikipedia economy section. Store last choice in session.
    - drives: `choosing_what_to_hear_spec.rb` — "history-biased next segment"

---

## Phase 4 — The Discovery

User moves through a landscape that has layers — maritime history, radio
infrastructure, ecology. Phase 4 surfaces those layers as opt-in interest
channels that announce themselves with a chime when the user is close enough to
matter.

**User journey**

1. Before tapping Start, the user sees a row of small toggle chips:
   **All · Ports · Radio Towers** (expandable in future: Heritage · Nature)
2. Selection persists in `localStorage` and defaults to **All** on first visit
3. After the main narrative plays, the app scans for POIs of the selected types
   within a category-specific radius
4. If a POI is found, a short chime plays — different tone per category — then
   a one-sentence fact is spoken
5. The chime + fact can interrupt a moving journey or follow a stationary
   segment; it never blocks the main narrative

**Interest categories and data sources**

| Category     | Radius | Source                         | Notes                                             |
| ------------ | ------ | ------------------------------ | ------------------------------------------------- |
| Ports        | 20 km  | OpenStreetMap Overpass API     | `amenity=port` or `harbour=*` query, no DB needed |
| Radio towers | 5 km   | ACMA RRL seed import (PostGIS) | One-time import of ACMA CSV; fast radius queries  |
| General POI  | 10 km  | Wikipedia Geosearch API        | Catches lighthouses, heritage sites, landmarks    |

NOTE: found these sources:
- https://en.wikipedia.org/wiki/List_of_ports_in_Australia
- eg https://www.acma.gov.au/register-radiocommunication-licences-rrl#/sites/10007619/map

**Chime signatures (Web Audio API — no audio files)**

| Category    | Tone                                          |
| ----------- | --------------------------------------------- |
| Port        | Three descending sine pulses (~foghorn shape) |
| Radio tower | Brief AM carrier burst (noise + 1 kHz sine)   |
| General POI | Single soft bell (sine with fast decay)       |

**Feature specs**

- `spec/features/journey/discovering_special_interests_spec.rb`
  - `it "shows interest toggle chips before starting"`
  - `it "persists interest selection across page loads"`
  - `it "plays a port chime and fact when a port is within 20 km"`
  - `it "plays a radio tower chime when a tower is within 5 km"`
  - `it "skips POI announcement when no interest matches"`
  - `it "skips POI announcement when All is deselected"`

**Page objects**

- `Pages::StartScreen` — extend with `interest_chips`, `toggle_interest(name)`
- `Pages::Journey` — extend with `has_chime_played?`, `poi_announcement_text`

---

## Phase 4 — Build order

11. **Interest chip UI** — toggle chips above Start button; read/write
    `localStorage`; pass selected interests as query params on every narrate and
    POI request.
    - drives: `discovering_special_interests_spec.rb` — "shows chips",
      "persists selection"

12. **POI scan endpoint** — `GET /journey/nearby_pois?lat=&lng=&interests[]=`
    returns an array of `{ category:, name:, distance_m:, fact: }`. Stub in
    specs; real implementation wired in next step.
    - drives: `discovering_special_interests_spec.rb` — "skips when no match"

13. **Wikipedia Geosearch layer** — query
    `en.wikipedia.org/w/api.php?action=query&list=geosearch` within radius,
    filter results by category keyword, return top hit with one-sentence extract.
    - drives: `discovering_special_interests_spec.rb` — general POI assertion

14. **Overpass ports layer** — query Overpass API for `amenity=port` within 20
    km. Parse result, return nearest. No DB required.
    - drives: `discovering_special_interests_spec.rb` — "port chime and fact"

15. **ACMA tower seed import** — rake task downloads ACMA RRL CSV, upserts into
    `points_of_interest` table (`category`, `name`, `lat`, `lng`). PostGIS
    `ST_DWithin` for radius queries. Migration adds PostGIS extension.
    - drives: `discovering_special_interests_spec.rb` — "radio tower chime"

16. **Web Audio chimes** — `ChimeController` (Stimulus) exposes
    `play(category)`; generates tone programmatically via `AudioContext`. Spec
    stubs `AudioContext` and asserts correct frequency/duration called.
    - drives: all chime assertions

17. **POI narration queue** — after main narrative ends, JS calls
    `/journey/nearby_pois`, plays chime for first result, speaks the fact,
    repeats for next result. Empty result → silence.
    - drives: full end-to-end flow in `discovering_special_interests_spec.rb`

---

## Technical decisions

| Concern                | PoC choice                     | Why                                                                          |
| ---------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| Text to speech         | Browser `SpeechSynthesis`      | Zero infra, zero cost, replace with Polly pre-beta                           |
| Reverse geocoding      | Nominatim (OpenStreetMap)      | Free, no API key, fine for PoC volumes                                       |
| Knowledge source       | Wikipedia REST API             | Free, structured summaries per place name                                    |
| HTTP streaming         | Plain JSON POST/response       | SpeechSynthesis needs full text anyway; add SSE when switching to server TTS |
| External HTTP in specs | VCR cassettes                  | Record once, replay forever                                                  |
| Geolocation in specs   | `page.execute_script` override | Override `navigator.geolocation` before page loads, no browser flags needed  |
| POI general layer      | Wikipedia Geosearch API        | Free, global, already integrated; catches ports/towers that have articles    |
| POI ports layer        | OpenStreetMap Overpass API     | `amenity=port` query, no DB, works globally                                  |
| POI towers layer       | ACMA RRL CSV seed → PostGIS    | One-time import; fast ST_DWithin radius queries; Australia-specific          |
| Interest persistence   | `localStorage`                 | No auth required; resets cleanly on clear; survives page reload              |
| Chime audio            | Web Audio API (synthesised)    | No audio files to serve; works offline; unique tone per category             |

---

## Out of scope

- Auth / user accounts
- Hotwire Native iOS/Android
- Server-side TTS or audio file generation
- Social media, local voices, specialist channels
- AWS Lambda, CDK, S3/CloudFront
- Any paid API
- Offline / service worker support
