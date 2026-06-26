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

## Technical decisions

| Concern                | PoC choice                     | Why                                                                          |
| ---------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| Text to speech         | Browser `SpeechSynthesis`      | Zero infra, zero cost, replace with Polly pre-beta                           |
| Reverse geocoding      | Nominatim (OpenStreetMap)      | Free, no API key, fine for PoC volumes                                       |
| Knowledge source       | Wikipedia REST API             | Free, structured summaries per place name                                    |
| HTTP streaming         | Plain JSON POST/response       | SpeechSynthesis needs full text anyway; add SSE when switching to server TTS |
| External HTTP in specs | VCR cassettes                  | Record once, replay forever                                                  |
| Geolocation in specs   | `page.execute_script` override | Override `navigator.geolocation` before page loads, no browser flags needed  |

---

## Out of scope

- Auth / user accounts
- Hotwire Native iOS/Android
- Server-side TTS or audio file generation
- Social media, local voices, specialist channels
- AWS Lambda, CDK, S3/CloudFront
- Any paid API
- Offline / service worker support
