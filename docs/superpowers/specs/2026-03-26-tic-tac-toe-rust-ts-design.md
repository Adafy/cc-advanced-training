# Tic-Tac-Toe: Rust Backend + TypeScript Frontend

## Overview

A tic-tac-toe game with a server-authoritative Rust backend (Axum) and a vanilla TypeScript frontend (Vite). Two players alternate turns locally. The Rust server owns all game state and logic; the frontend is a thin rendering layer that sends user actions and paints the response. Styled with the Catppuccin Mocha color palette.

**Goal:** Learning exercise demonstrating clean Rust + TypeScript full-stack patterns — architecture, separation of concerns, and error handling over feature complexity.

## Project Structure

```
tic-tac-toe/
├── server/
│   ├── Cargo.toml
│   ├── src/
│   │   ├── main.rs          # Entry point, server setup, static file serving
│   │   ├── game.rs          # Game state, move validation, win/draw detection
│   │   └── routes.rs        # API route handlers
│   └── static/              # Vite build output (gitignored)
├── client/
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── index.html
│   └── src/
│       ├── main.ts           # Entry point, initializes board and event listeners
│       ├── api.ts            # HTTP client for talking to Rust API
│       └── style.css         # Catppuccin Mocha theme
```

`server/static/` is gitignored — populated by `vite build` before running the Rust server in production. During development, Vite's dev server proxies `/api/*` to the Rust backend.

## API Design

All endpoints return JSON. Content-Type: `application/json`.

### Endpoints

| Method | Path | Request Body | Response | Purpose |
|---|---|---|---|---|
| `POST` | `/api/games` | — | `GameState` | Create a new game |
| `GET` | `/api/games/:id` | — | `GameState` | Get current game state |
| `POST` | `/api/games/:id/moves` | `{ "position": 0-8 }` | `GameState` | Make a move |
| `POST` | `/api/games/:id/reset` | — | `GameState` | Reset game to initial state |

### GameState Response

```json
{
  "id": "uuid-string",
  "board": ["X", null, "O", null, null, null, null, null, null],
  "current_player": "X",
  "status": { "type": "in_progress" }
}
```

### Status Variants

- `{ "type": "in_progress" }` — game ongoing
- `{ "type": "won", "winner": "X", "winning_cells": [0, 1, 2] }` — includes cells to highlight
- `{ "type": "draw" }` — board full, no winner

### Error Responses

- `400 Bad Request` — invalid move (cell taken, game over, position out of range). Body: `{ "error": "description" }`
- `404 Not Found` — unknown game ID

## Server-Side Game Logic (Rust)

### `game.rs` — Core Types and Logic

**Types:**

- `Player` enum: `X`, `O`
- `GameStatus` enum: `InProgress`, `Won { winner: Player, winning_cells: [usize; 3] }`, `Draw`
- `GameError` enum: `InvalidPosition`, `CellOccupied`, `GameOver`
- `Game` struct: `id: Uuid`, `board: [Option<Player>; 9]`, `current_player: Player`, `status: GameStatus`

**Methods:**

- `Game::new()` — empty board, X goes first, status InProgress
- `Game::make_move(position: usize) -> Result<(), GameError>` — validates move (in range, cell empty, game active), places mark, checks for win/draw, updates status, switches player
- `Game::check_winner() -> Option<[usize; 3]>` — tests all 8 winning combinations, returns winning cell indices if found
- `Game::reset()` — clears board, resets to X's turn, status InProgress

**Winning combinations:**

```
[0,1,2], [3,4,5], [6,7,8]  // rows
[0,3,6], [1,4,7], [2,5,8]  // columns
[0,4,8], [2,4,6]            // diagonals
```

### `routes.rs` — Handler Layer

- Each handler extracts path/body parameters, locks the game store, calls `Game` methods, serializes the response
- Shared state: `AppState { games: Arc<Mutex<HashMap<Uuid, Game>>> }`
- `GameError` maps to HTTP status codes: `InvalidPosition`/`CellOccupied`/`GameOver` → 400, missing game → 404

### `main.rs` — Wiring

- Creates `AppState`, builds Axum router with `/api/*` routes
- Static file fallback via `tower_http::services::ServeDir` serving from `./static/`
- Listens on `127.0.0.1:3000`

## Frontend (TypeScript)

### `api.ts` — HTTP Client

- `createGame(): Promise<GameState>` → POST `/api/games`
- `getGame(id: string): Promise<GameState>` → GET `/api/games/:id`
- `makeMove(id: string, position: number): Promise<GameState>` → POST `/api/games/:id/moves`
- `resetGame(id: string): Promise<GameState>` → POST `/api/games/:id/reset`
- All functions return typed `GameState` interface matching the server response
- Error responses parsed and surfaced to the UI

### `main.ts` — UI Logic

- On load: calls `createGame()`, stores the game ID, renders the board
- Click handler on each cell: calls `makeMove()`, re-renders board from server response
- Reset button: calls `resetGame()`, re-renders
- `renderBoard(state: GameState)` — updates cell contents, applies CSS classes (`x`, `o`, `winner`, `disabled`) based on server state
- `renderStatus(state: GameState)` — shows turn indicator, winner announcement, or draw message
- All rendering driven by server state — no local game logic

### `style.css` — Catppuccin Mocha Theme

Color palette matching the existing `tic-tac-toe-improved.html`:

- Background: `#1e1e2e`
- Surface/board: `#313244`, borders `#45475a`
- Text: `#cdd6f4`, secondary `#bac2de`
- X marks: `#f38ba8` (red)
- O marks: `#89b4fa` (blue)
- Winner highlight: `#a6e3a1` (green) with box-shadow
- Disabled cells: reduced opacity
- Reset button: `#cba6f7` (mauve)

Layout: centered on page, 3x3 CSS grid, hover effects on empty cells, smooth transitions.

### `vite.config.ts`

- Build output directory: `../server/static/`
- Dev server proxy: `/api` → `http://localhost:3000`

## Development Workflow

**Development (two terminals):**

1. `cd server && cargo run` — Rust API on port 3000
2. `cd client && npm run dev` — Vite dev server on port 5173, proxies `/api` to port 3000

**Production build:**

1. `cd client && npm run build` — compiles to `server/static/`
2. `cd server && cargo run` — serves everything from port 3000

## Testing

**Rust unit tests (`game.rs`):**

- Valid moves update board and switch player
- Invalid position (out of range) returns error
- Occupied cell returns error
- Move after game over returns error
- Win detection on all 8 combinations
- Draw detection (full board, no winner)
- Reset clears state

**Rust integration tests (`routes.rs`):**

- POST `/api/games` creates a game and returns valid state
- GET `/api/games/:id` returns current state
- POST `/api/games/:id/moves` with valid position succeeds
- POST `/api/games/:id/moves` with invalid position returns 400
- GET `/api/games/:unknown` returns 404

No frontend tests — the client is a thin rendering layer; server tests cover all game logic.

## Dependencies

### Rust (server/Cargo.toml)

| Crate | Purpose |
|---|---|
| `axum` | Web framework |
| `tokio` | Async runtime |
| `serde` / `serde_json` | JSON serialization |
| `uuid` | Game IDs |
| `tower-http` | Static file serving (ServeDir) |

### TypeScript (client/package.json)

| Package | Purpose |
|---|---|
| `vite` | Build tool and dev server |
| `typescript` | Type checking |
