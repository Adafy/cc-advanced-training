---
description: Prime the agent with the structure and entry points of tic-tac-toe/.
allowed-tools: Bash(git*), Read, Glob, Grep
---

# Prime Tic-Tac-Toe

## Purpose

The `tic-tac-toe/` folder contains a full-stack tic-tac-toe game: a Rust/Axum HTTP API server under `server/` and a TypeScript/Vite single-page client under `client/`. The server holds game state in-memory (`Arc<Mutex<HashMap>>`) and exposes four routes; the client renders the board and drives the game through those routes. The Vite build emits to `server/static/`, so the Rust binary can serve the built frontend in production.

## Codebase Structure

- `tic-tac-toe/server/src/main.rs` — Axum bootstrap; wires `AppState`, mounts routes, serves `static/`, listens on `:3000`
- `tic-tac-toe/server/src/game.rs` — Core game logic: `Player`/`GameStatus` enums, `Game` struct, win detection, 15 unit tests
- `tic-tac-toe/server/src/routes.rs` — Handlers for `POST /api/games`, `GET /api/games/{id}`, `POST /api/games/{id}/moves`, `POST /api/games/{id}/reset` (+ integration tests)
- `tic-tac-toe/server/Cargo.toml` — Rust deps (Axum, Tokio, Serde, Uuid, tower-http)
- `tic-tac-toe/client/index.html` — HTML shell that loads the bundled script
- `tic-tac-toe/client/src/main.ts` — UI logic: board rendering, state handling, event listeners
- `tic-tac-toe/client/src/api.ts` — HTTP client wrapping the four backend routes
- `tic-tac-toe/client/src/style.css` — Catppuccin Mocha theme
- `tic-tac-toe/client/vite.config.ts` — Build emits to `../server/static/`; dev proxy `/api` → `localhost:3000`
- `tic-tac-toe/client/package.json` — Node scripts (`dev`, `build`, `preview`)
- `docs/superpowers/specs/2026-03-26-tic-tac-toe-rust-ts-design.md` — Full system architecture, API spec, styling notes

## Workflow

1. RUN: `git ls-files tic-tac-toe/`
2. READ (minimum upfront): `docs/superpowers/specs/2026-03-26-tic-tac-toe-rust-ts-design.md`, `tic-tac-toe/server/Cargo.toml`, `tic-tac-toe/client/package.json`
3. REPORT: Summarize what lives in `tic-tac-toe/` — the two halves (Rust server, TS client), how they communicate, and the dev/build/test commands a contributor would run. Cite the files you read. If a follow-up question requires detail beyond what you read, consult the Reference Index and Read the relevant file.

## Reference Index

Files NOT read upfront. Read on demand if a follow-up question requires the detail:

- `tic-tac-toe/server/src/main.rs` — Axum bootstrap, app state, static serving
- `tic-tac-toe/server/src/game.rs` — game logic + win detection + unit tests
- `tic-tac-toe/server/src/routes.rs` — route handlers + integration tests
- `tic-tac-toe/client/index.html` — HTML entry point
- `tic-tac-toe/client/src/main.ts` — board rendering and event handling
- `tic-tac-toe/client/src/api.ts` — typed API client
- `tic-tac-toe/client/vite.config.ts` — build target and dev proxy
- `tic-tac-toe/client/src/style.css` — Catppuccin Mocha theme

## Report

Produce a short markdown report with these sections:

### Overview
2–3 sentences describing the folder's purpose and the split between `server/` and `client/`.

### Architecture
- Backend stack and entry point
- Frontend stack and entry point
- How the two communicate (API routes, dev proxy, prod static serving)

### Commands
- `cd tic-tac-toe/server && cargo run` — start the API server on `:3000`
- `cd tic-tac-toe/server && cargo test` — run Rust tests (game logic + route handlers)
- `cd tic-tac-toe/client && npm run dev` — Vite dev server on `:5173` with `/api` proxy
- `cd tic-tac-toe/client && npm run build` — bundle frontend into `server/static/`

### Notes
Anything surprising or worth flagging (e.g., in-memory state, no client test runner configured).
