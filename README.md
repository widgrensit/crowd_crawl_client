# Crowd Crawl Client

Flame/Flutter game client for [Crowd Crawl](https://github.com/widgrensit/crowd_crawl) — an audience-driven roguelike dungeon crawler built on [Asobi](https://github.com/widgrensit/asobi).

## Quick Start

### Prerequisites

- Flutter 3.22+ (with Dart 3.4+)
- A running Crowd Crawl backend (see [crowd_crawl](https://github.com/widgrensit/crowd_crawl))

### Run Locally

```bash
git clone https://github.com/widgrensit/crowd_crawl_client.git
cd crowd_crawl_client
flutter pub get

# Desktop
flutter run -d linux    # or macos, windows

# Web (Chrome)
flutter run -d chrome
```

The client connects to `http://localhost:8083` by default.

### Run the Backend

```bash
git clone https://github.com/widgrensit/crowd_crawl.git
cd crowd_crawl
docker compose up -d    # PostgreSQL on port 5433
rebar3 compile
rebar3 shell            # Starts on port 8083
```

## Controls

| Key | Action |
|-----|--------|
| **WASD** / Arrows | Move hero |
| **Space** | Attack targeted enemy |
| **1-5** | Target specific enemy |
| **Tab** | Cycle through targets |
| **E** | Interact (open chests, use fountains) |
| **H** | Use heal potion from inventory |
| **Q** | Dodge (DEF-based chance to avoid damage) |

## Game Features

- **Roguelike dungeon crawl** with procedural rooms and floor progression
- **Turn-based combat** — attack, dodge, heal, use items
- **25 boons** (common/rare/legendary) with equipment slots
- **5 boss types** with unique abilities
- **Room features** — golden chests, hidden traps, healing fountains
- **Tarot card voting** — pick boons, choose paths, modify bosses
- **Permadeath** with score tracking

## Build for Web

```bash
flutter build web
# Output in build/web/ — serve with any static file server
```

## Assets

Pixel art from [Time Fantasy](https://finalbossblues.itch.io/) asset packs:
- Dungeon tilesets
- Character sprites (dwarf hero, animals, military, elves)
- Tarot card deck (22 major arcana)
- Combat effect animations

## License

Apache-2.0
