# that-way

A personalized navigation iOS app that learns your driving habits over time.

## How it works

Navigation apps give everyone the same route. This one learns yours.

**Learning phase** — as you drive to frequented places (home, work, the gym, grocery
store), the system observes your actual path: which roads you take, which turns you make, which side of the parking lot you enter from. Over time it builds a behavioral profile for each origin→destination pair.

**New trips** — when you navigate somewhere new, the system applies your learned
behaviors to influence route generation. If you consistently avoid u-turns (like me), it avoids them. If you always prefer residential streets near your neighborhood, it biases toward those. The route just appears — no upfront choices, no interruptions while you drive.

**Post-trip feedback** — after you arrive, you can optionally review the steps of your
route and flag any you liked or disliked. This is the only explicit input the system asks for. Those flags refine the segment-level preference model for future trips.

---

## Stack

| Layer              | Technology                        |
| ------------------ | --------------------------------- |
| Mobile             | Expo React Native / SwiftUI (TBD) |
| Backend / Pipeline | Python                            |
| Database           | Supabase (Postgres + PostGIS)     |

---

## Project structure

```
that-way/
├── backend/
│   ├── api/          # HTTP handlers (FastAPI or similar)
│   ├── models/       # Pydantic models mirroring DB tables
│   ├── pipeline/     # Route generation, behavior learning, segment scoring
│   └── utils/        # Supabase client, shared helpers
├── database/
│   ├── migrations/   # SQL migration files (run in order)
│   └── seeds/        # Development seed data
├── mobile/           # iOS app (Expo / SwiftUI — TBD)
├── scripts/          # One-off admin / migration scripts
├── docs/             # Architecture notes, ADRs
├── .env.template     # Copy to .env and fill in credentials
└── README.md
```

---

## Database schema

### `users`

Core user record. Linked to Supabase Auth via `auth_uid`.

### `known_places`

Frequented locations the user has labeled ("Home", "Work") or that the system infers from
visit frequency. Each place has an arrival detection radius and a visit count. These are
the anchor points for building behavioral patterns.

### `frequented_routes`

A learned behavioral pattern between two known places. Built up across multiple observed
trips on the same origin→destination pair. The `behavior_profile` JSONB column captures
distilled habits: left-turn avoidance, road type preference, parking lot entry heading,
typical time of day, etc. Unique per `(user, origin_place, dest_place)` — upserted as
more trips arrive.

### `trips`

One row per navigation session. The route is generated automatically from the user's
learned behavior — no upfront options shown. Optionally linked to `known_places` if either
endpoint is a recognized place, and to the `frequented_routes` record whose profile was
used to shape the generated route.

### `route_steps`

Ordered navigation instructions within a trip. Each step corresponds to a road segment or
maneuver (`turn_left`, `merge`, `roundabout`, etc.) and carries the segment ID, geometry,
and an `attributes` JSONB blob for context available at generation time. **This is the
unit that post-trip feedback targets.**

### `step_feedback`

Post-trip feedback on individual steps — `liked` or `disliked`, with an optional note.
Collected after the user arrives, never during. Drives updates to
`road_segment_preferences`.

### `gps_traces`

Raw GPS breadcrumbs recorded during a trip. Spatial index supports map-matching and
behavioral pattern extraction.

### `road_segment_preferences`

Per-user learned signal on road segments, derived from step feedback and observed
traversals. Stores raw tallies (`times_traversed`, `times_liked`, `times_disliked`) so
the scoring algorithm can be tuned independently of stored data. The `context` JSONB
captures behavioral metadata learned from how the user drives each segment.

---

## Data flow

```
GPS traces (during trip)
        │
        ▼
  Post-trip pipeline
        │
        ├─► known_places: increment visit_count, update last_visited
        │
        ├─► frequented_routes: upsert behavior_profile for this place pair
        │
        └─► road_segment_preferences: update traversal counts

Step feedback (user, post-trip)
        │
        ▼
  road_segment_preferences: increment liked/disliked counts, update signal
        │
        ▼
  frequented_routes: refine behavior_profile for affected place pairs

Route generation (next trip to new destination)
        │
        ├─ load road_segment_preferences for user
        ├─ load relevant frequented_routes behavior_profile
        └─► routing engine call with preference weights applied
```

---

## Setup

### 1. Clone and create your environment file

```bash
cp .env.template .env
# Fill in SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_DB_URL
```

### 2. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and create a new project.
2. Enable the **PostGIS** extension under Database → Extensions.
3. Copy your project URL and API keys into `.env`.

### 3. Run migrations

```bash
psql "$SUPABASE_DB_URL" -f database/migrations/001_initial_schema.sql
```

For development seed data:

```bash
psql "$SUPABASE_DB_URL" -f database/seeds/001_dev_seed.sql
```

### 4. Install Python dependencies

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

---

## Development roadmap

- [ ] GPS trace ingestion + map-matching
- [ ] Known place detection (cluster arrival points into labeled places)
- [ ] Behavior profile extraction from frequented routes
- [ ] Route generation pipeline (OSRM / Valhalla + preference weights)
- [ ] Post-trip feedback API endpoint
- [ ] Segment preference scoring algorithm
- [ ] Mobile UI (Expo React Native or SwiftUI)
