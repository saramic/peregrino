# Peregrino

[![CI](
  https://github.com/saramic/peregrino/actions/workflows/ci.yml/badge.svg)](
  https://github.com/saramic/peregrino/actions/workflows/ci.yml)

> Every road is a pilgrimage. We just forgot how to listen.

Peregrino is a mobile-first audio experience for people in motion. The word
means pilgrim — the person who travels not just to arrive, but to be changed by
the journey itself. That is what Peregrino is for.

As you drive, cycle, or walk through a landscape, Peregrino assembles a living,
location-aware audio companion from the world around you — drawing on
historical records, natural features, community voices, local business, and the
live pulse of social media — and speaks it to you, hands-free, in real time.

The road you are on has been walked before. By drovers and explorers, by
immigrants and gold seekers, by the people who were here long before any of
them. Peregrino remembers on their behalf.

No playlists to curate. No episodes to download. Just press play, start moving,
and let the country tell you where you are.

---

## What it does

Peregrino continuously monitors your position as you travel. When you enter a
new area, cross a boundary of geographic interest, or approach a point of
significance, it composes a new audio segment and streams it to you immediately
— like a podcast episode that only exists for this road, at this moment, for
this particular stretch of your journey.

Every segment is assembled on the fly from multiple layers of local
intelligence:

**Historical layer**

Drawing on Wikipedia, heritage registers, and curated historical databases,
Peregrino surfaces the events, people, and decisions that shaped the land you
are passing through. The gold rush town that became a suburb. The river
crossing that determined a colony's fate. The hill that three different armies
used as a vantage point across three different centuries.

**Places and landmarks**

Recognised points of interest — natural wonders, architectural landmarks,
holiday destinations, scenic lookouts — are woven into the narrative as you
approach them, giving you context before you arrive and reflection after you
leave.

**Nature and environment**

Parks, reserves, wildlife corridors, geological formations, and protected
ecosystems are described as you pass through or near them. Peregrino knows
whether you are crossing a volcanic plain, entering a rainforest, or skirting a
migratory bird route.

**Current local pulse**

Geo-tagged posts from Instagram, X, and Facebook give Peregrino a live signal
of what people in this area are experiencing right now — a festival happening
two kilometres ahead, a road closure, a remarkable sunrise that locals are
sharing this morning. The landscape's social layer, spoken aloud.

**Geopolitical and economic context**

Drawing on LinkedIn company data, business registries, local news feeds, and
natural resource maps, Peregrino can tell you about the industries that run
through a region, the companies headquartered in a town you are passing, the
resources extracted from the hills on either side of you, and the policy
decisions that shaped the land use visible through your windscreen.

**Specialist interest channels**

Peregrino supports configurable interest overlays. Enable the channels relevant
to you and they become part of your personalised audio feed:

- **Railways** — historic and active rail infrastructure, abandoned lines,
  engineering achievements, the stories of the people who built them
- **Radio and telecommunications** — transmission towers, antenna farms,
  broadcast history, spectrum allocation, the invisible infrastructure of
  modern communication
- **Fishing** — local waterways, species, seasonal conditions, access points,
  and the regulations that govern them
- **Roadside geology** — what the roadcuts reveal about deep time
- **Aviation** — airspace, historic airfields, flight paths overhead
- *and more, added by the community over time*

**Local voices**

The most distinctive layer. Peregrino lets locals record their own stories and
attach them to a place. The owner of a fish and chips shop explains how the
town's fishing industry changed over fifty years. A third-generation farmer
describes what the drought of 1982 did to this valley. A retired schoolteacher
remembers what the high street looked like before the bypass. These are
interviews, oral histories, and first-person accounts — geolocated, searchable,
and permanently attached to the place they describe. Anyone can contribute.
Everything is moderated for quality and authenticity.

---

## Who it is for

Peregrino is built for anyone whose life involves moving through landscapes
with curiosity — which is more people than they know:

- Road trippers and long-distance drivers who find silence between cities
  wasted
- Travellers visiting a country or region for the first time
- Locals who have driven the same road for twenty years and want to see it
  differently
- Cyclists and bushwalkers who want an audio companion that matches their pace
- Educators leading excursions
- People with a specific passion — railways, ecology, military history,
  industrial archaeology — who want the world filtered through that lens

---

## How it works

Peregrino is a Rails application at its core. The server assembles audio
narratives from a pipeline of geolocation-triggered data sources, synthesises
speech in real time using a TTS engine, and streams the resulting audio to a
native mobile client built with Hotwire Native for iOS and Android.

The mobile app handles the two capabilities that require native platform
access: continuous background geolocation (so the app knows where you are even
when your screen is off) and background audio playback with lock-screen
controls (so you can listen with your phone in your pocket). Everything else —
content browsing, account management, recording local voices, managing interest
channels — is served as HTML from the Rails backend.

Content assembly runs as a combination of background jobs (for pre-computing
segments in areas you are approaching) and AWS Lambda functions (for on-demand
synthesis and social media aggregation). Audio files are streamed from S3 via
CloudFront.

---

## Project structure

```
peregrino/
├── app/                          # Rails application
│   ├── javascript/
│   │   └── controllers/bridge/   # Hotwire Native bridge components
│   └── views/
│       └── mobile/               # Native-specific layouts
├── config/
│   └── hotwire_native/           # Path configuration for native clients
├── lambdas/                      # AWS Lambda functions
│   ├── audio-synthesiser/        # TTS + audio assembly
│   ├── social-aggregator/        # Geo-tagged social media ingestion
│   └── shared/                   # Common AWS clients and types
├── mobile/
│   ├── ios/                      # Hotwire Native iOS (Swift)
│   └── android/                  # Hotwire Native Android (Kotlin)
├── infra/                        # AWS CDK infrastructure
└── docs/
    └── adr/                      # Architecture Decision Records
```

---

## Development setup

See [WORK_LOG.md](./WORK_LOG.md) for the full step-by-step setup guide.

Quick start:

```bash
# Prerequisites: Ruby 4.0+, Node 24, pnpm 10+, Docker, AWS CLI
make setup      # bundle install + pnpm install + db:prepare
bin/dev         # starts Rails + esbuild watcher + Tailwind watcher
make test       # Rails specs + Lambda unit tests
make lint       # ESLint across app/javascript and lambdas/
```

---

## Architecture decisions

Significant technical decisions are recorded as Architecture Decision Records in
[`doc/adr/`](./doc/adr/). Start with:

- [ADR-0001](./doc/adr/0001-architecture-decision-record-template.adoc) — ADR
  process and template
- [ADR-0002](./doc/adr/0002-monorepo-rails-lambda-hotwire-native.adoc) —
  Monorepo structure, deployment strategy, and mobile approach

---

## Contributing local voices

_this is blatantly wrong_

Every pilgrimage route is made by the people who walked it and the people who
lived along it. Peregrino's local voices layer works the same way — it depends
on the people who know a place to speak for it.

If you have a story attached to a place — or know someone who does — see
[CONTRIBUTING.md](./CONTRIBUTING.md) for how to record and submit a
location-tagged audio story.

We are particularly interested in voices that would otherwise go unrecorded:
small business owners, retired tradespeople, Indigenous community members,
farmers, fishermen, and anyone whose knowledge of a place lives in lived
experience rather than written records. The fish and chips shop owner who
watched the harbour change over forty years. The wheat farmer who can read the
sky. The publican who has heard every version of the town's history across the
bar.

These are the voices that make a place real. Peregrino carries them forward.
