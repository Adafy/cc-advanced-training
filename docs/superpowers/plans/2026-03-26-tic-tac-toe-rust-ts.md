# Tic-Tac-Toe (Rust + TypeScript) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a tic-tac-toe game with a server-authoritative Rust backend (Axum) and vanilla TypeScript frontend (Vite), styled with Catppuccin Mocha.

**Architecture:** Monorepo with `server/` (Rust/Axum) and `client/` (TypeScript/Vite). The Rust server owns all game state and logic, exposing a REST API. The frontend is a thin rendering layer. In production, the Rust binary serves compiled frontend assets as static files.

**Tech Stack:** Rust (Axum, Tokio, Serde, Uuid, tower-http), TypeScript (Vite, vanilla DOM)

**Spec:** `docs/superpowers/specs/2026-03-26-tic-tac-toe-rust-ts-design.md`

---

## File Map

### Server (`tic-tac-toe/server/`)

| File | Responsibility |
|---|---|
| `Cargo.toml` | Dependencies: axum, tokio, serde, serde_json, uuid, tower-http |
| `src/main.rs` | Entry point — creates AppState, builds router, starts server |
| `src/game.rs` | Core game types (Player, GameStatus, GameError, Game) and all game logic |
| `src/routes.rs` | Axum route handlers, AppState definition, JSON request/response types |

### Client (`tic-tac-toe/client/`)

| File | Responsibility |
|---|---|
| `package.json` | Dependencies: vite, typescript |
| `tsconfig.json` | TypeScript compiler config |
| `vite.config.ts` | Build output to `../server/static/`, dev proxy `/api` → localhost:3000 |
| `index.html` | HTML shell: title, status div, board container, reset button |
| `src/api.ts` | HTTP client — createGame, getGame, makeMove, resetGame |
| `src/main.ts` | UI logic — event listeners, renderBoard, renderStatus |
| `src/style.css` | Catppuccin Mocha theme |

---

## Task 1: Scaffold Rust Project

**Files:**
- Create: `tic-tac-toe/server/Cargo.toml`
- Create: `tic-tac-toe/server/src/main.rs`
- Create: `tic-tac-toe/server/src/game.rs`
- Create: `tic-tac-toe/server/src/routes.rs`

- [ ] **Step 1: Create the Cargo project**

```bash
cd tic-tac-toe && cargo init server
```

- [ ] **Step 2: Set up Cargo.toml with dependencies**

Replace `tic-tac-toe/server/Cargo.toml` with:

```toml
[package]
name = "tic-tac-toe-server"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.8"
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
uuid = { version = "1", features = ["v4", "serde"] }
tower-http = { version = "0.6", features = ["fs"] }
```

- [ ] **Step 3: Create empty module files**

Create `tic-tac-toe/server/src/game.rs` and `tic-tac-toe/server/src/routes.rs` as empty files.

Update `tic-tac-toe/server/src/main.rs` to:

```rust
mod game;
mod routes;

fn main() {
    println!("Server placeholder");
}
```

- [ ] **Step 4: Verify it compiles**

```bash
cd tic-tac-toe/server && cargo build
```

Expected: compiles with no errors (may have unused warnings, that's fine).

- [ ] **Step 5: Commit**

```bash
git add tic-tac-toe/server/
git commit -m "feat: scaffold Rust server project with dependencies"
```

---

## Task 2: Game Core Types and `Game::new()`

**Files:**
- Modify: `tic-tac-toe/server/src/game.rs`

- [ ] **Step 1: Write the failing test for Game::new()**

Add to `tic-tac-toe/server/src/game.rs`:

```rust
use serde::Serialize;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum Player {
    X,
    O,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub enum GameStatus {
    InProgress,
    Won {
        winner: Player,
        winning_cells: [usize; 3],
    },
    Draw,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum GameError {
    InvalidPosition,
    CellOccupied,
    GameOver,
}

impl std::fmt::Display for GameError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            GameError::InvalidPosition => write!(f, "Position must be 0-8"),
            GameError::CellOccupied => write!(f, "Cell is already occupied"),
            GameError::GameOver => write!(f, "Game is already over"),
        }
    }
}

pub struct Game {
    pub id: Uuid,
    pub board: [Option<Player>; 9],
    pub current_player: Player,
    pub status: GameStatus,
}

impl Game {
    pub fn new() -> Self {
        Game {
            id: Uuid::new_v4(),
            board: [None; 9],
            current_player: Player::X,
            status: GameStatus::InProgress,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_game_has_empty_board() {
        let game = Game::new();
        assert!(game.board.iter().all(|cell| cell.is_none()));
    }

    #[test]
    fn new_game_starts_with_x() {
        let game = Game::new();
        assert_eq!(game.current_player, Player::X);
    }

    #[test]
    fn new_game_is_in_progress() {
        let game = Game::new();
        assert_eq!(game.status, GameStatus::InProgress);
    }
}
```

- [ ] **Step 2: Run tests to verify they pass**

```bash
cd tic-tac-toe/server && cargo test
```

Expected: 3 tests pass.

- [ ] **Step 3: Commit**

```bash
git add tic-tac-toe/server/src/game.rs
git commit -m "feat: add core game types and Game::new() with tests"
```

---

## Task 3: `Game::make_move()` — Valid Moves

**Files:**
- Modify: `tic-tac-toe/server/src/game.rs`

- [ ] **Step 1: Write the failing test for a valid move**

Add to the `tests` module in `game.rs`:

```rust
#[test]
fn make_move_places_mark_and_switches_player() {
    let mut game = Game::new();
    game.make_move(0).unwrap();
    assert_eq!(game.board[0], Some(Player::X));
    assert_eq!(game.current_player, Player::O);
}

#[test]
fn make_move_alternates_players() {
    let mut game = Game::new();
    game.make_move(0).unwrap(); // X
    game.make_move(1).unwrap(); // O
    assert_eq!(game.board[0], Some(Player::X));
    assert_eq!(game.board[1], Some(Player::O));
    assert_eq!(game.current_player, Player::X);
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd tic-tac-toe/server && cargo test
```

Expected: compilation error — `make_move` not defined.

- [ ] **Step 3: Implement make_move with validation and win/draw detection**

Add to the `impl Game` block in `game.rs`:

```rust
const WIN_COMBOS: [[usize; 3]; 8] = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6],             // diagonals
];

pub fn make_move(&mut self, position: usize) -> Result<(), GameError> {
    if position > 8 {
        return Err(GameError::InvalidPosition);
    }
    if self.status != GameStatus::InProgress {
        return Err(GameError::GameOver);
    }
    if self.board[position].is_some() {
        return Err(GameError::CellOccupied);
    }

    self.board[position] = Some(self.current_player);

    // Check for winner
    if let Some(winning_cells) = self.check_winner() {
        self.status = GameStatus::Won {
            winner: self.current_player,
            winning_cells,
        };
    } else if self.board.iter().all(|c| c.is_some()) {
        self.status = GameStatus::Draw;
    } else {
        self.current_player = match self.current_player {
            Player::X => Player::O,
            Player::O => Player::X,
        };
    }

    Ok(())
}

fn check_winner(&self) -> Option<[usize; 3]> {
    for combo in &WIN_COMBOS {
        let [a, b, c] = *combo;
        if let (Some(pa), Some(pb), Some(pc)) =
            (self.board[a], self.board[b], self.board[c])
        {
            if pa == pb && pb == pc {
                return Some([a, b, c]);
            }
        }
    }
    None
}
```

Note: `WIN_COMBOS` is defined as a constant inside the `impl Game` block or at module level — either works, module level is cleaner.

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd tic-tac-toe/server && cargo test
```

Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add tic-tac-toe/server/src/game.rs
git commit -m "feat: implement make_move with validation and win/draw detection"
```

---

## Task 4: `Game::make_move()` — Error Cases

**Files:**
- Modify: `tic-tac-toe/server/src/game.rs`

- [ ] **Step 1: Write failing tests for error cases**

Add to the `tests` module:

```rust
#[test]
fn make_move_rejects_invalid_position() {
    let mut game = Game::new();
    assert_eq!(game.make_move(9), Err(GameError::InvalidPosition));
}

#[test]
fn make_move_rejects_occupied_cell() {
    let mut game = Game::new();
    game.make_move(0).unwrap();
    assert_eq!(game.make_move(0), Err(GameError::CellOccupied));
}

#[test]
fn make_move_rejects_after_game_over() {
    let mut game = Game::new();
    // X wins: top row
    game.make_move(0).unwrap(); // X
    game.make_move(3).unwrap(); // O
    game.make_move(1).unwrap(); // X
    game.make_move(4).unwrap(); // O
    game.make_move(2).unwrap(); // X wins
    assert_eq!(game.make_move(5), Err(GameError::GameOver));
}
```

- [ ] **Step 2: Run tests to verify they pass**

These should pass immediately since `make_move` already validates. Run to confirm:

```bash
cd tic-tac-toe/server && cargo test
```

Expected: 8 tests pass.

- [ ] **Step 3: Commit**

```bash
git add tic-tac-toe/server/src/game.rs
git commit -m "test: add error case tests for make_move"
```

---

## Task 5: Win Detection and Draw Detection Tests

**Files:**
- Modify: `tic-tac-toe/server/src/game.rs`

- [ ] **Step 1: Write tests for win detection across all combo types**

Add to the `tests` module:

```rust
#[test]
fn detects_row_win() {
    let mut game = Game::new();
    game.make_move(3).unwrap(); // X
    game.make_move(0).unwrap(); // O
    game.make_move(4).unwrap(); // X
    game.make_move(1).unwrap(); // O
    game.make_move(5).unwrap(); // X wins middle row
    assert_eq!(
        game.status,
        GameStatus::Won {
            winner: Player::X,
            winning_cells: [3, 4, 5]
        }
    );
}

#[test]
fn detects_column_win() {
    let mut game = Game::new();
    game.make_move(1).unwrap(); // X
    game.make_move(0).unwrap(); // O
    game.make_move(4).unwrap(); // X
    game.make_move(2).unwrap(); // O
    game.make_move(7).unwrap(); // X wins middle column
    assert_eq!(
        game.status,
        GameStatus::Won {
            winner: Player::X,
            winning_cells: [1, 4, 7]
        }
    );
}

#[test]
fn detects_diagonal_win() {
    let mut game = Game::new();
    game.make_move(0).unwrap(); // X
    game.make_move(1).unwrap(); // O
    game.make_move(4).unwrap(); // X
    game.make_move(2).unwrap(); // O
    game.make_move(8).unwrap(); // X wins diagonal
    assert_eq!(
        game.status,
        GameStatus::Won {
            winner: Player::X,
            winning_cells: [0, 4, 8]
        }
    );
}

#[test]
fn detects_o_win() {
    let mut game = Game::new();
    game.make_move(0).unwrap(); // X
    game.make_move(3).unwrap(); // O
    game.make_move(1).unwrap(); // X
    game.make_move(4).unwrap(); // O
    game.make_move(8).unwrap(); // X
    game.make_move(5).unwrap(); // O wins middle row
    assert_eq!(
        game.status,
        GameStatus::Won {
            winner: Player::O,
            winning_cells: [3, 4, 5]
        }
    );
}

#[test]
fn detects_draw() {
    let mut game = Game::new();
    // X O X
    // X X O
    // O X O
    game.make_move(0).unwrap(); // X
    game.make_move(1).unwrap(); // O
    game.make_move(2).unwrap(); // X
    game.make_move(5).unwrap(); // O
    game.make_move(3).unwrap(); // X
    game.make_move(6).unwrap(); // O
    game.make_move(4).unwrap(); // X
    game.make_move(8).unwrap(); // O
    game.make_move(7).unwrap(); // X — draw
    assert_eq!(game.status, GameStatus::Draw);
}
```

- [ ] **Step 2: Run tests to verify they pass**

```bash
cd tic-tac-toe/server && cargo test
```

Expected: 13 tests pass.

- [ ] **Step 3: Commit**

```bash
git add tic-tac-toe/server/src/game.rs
git commit -m "test: add win detection and draw detection tests"
```

---

## Task 6: `Game::reset()`

**Files:**
- Modify: `tic-tac-toe/server/src/game.rs`

- [ ] **Step 1: Write the failing test**

Add to the `tests` module:

```rust
#[test]
fn reset_clears_board_and_state() {
    let mut game = Game::new();
    let original_id = game.id;
    game.make_move(0).unwrap();
    game.make_move(1).unwrap();
    game.reset();
    assert_eq!(game.id, original_id); // ID preserved
    assert!(game.board.iter().all(|cell| cell.is_none()));
    assert_eq!(game.current_player, Player::X);
    assert_eq!(game.status, GameStatus::InProgress);
}
```

- [ ] **Step 2: Run tests to verify it fails**

```bash
cd tic-tac-toe/server && cargo test
```

Expected: compilation error — `reset` not defined.

- [ ] **Step 3: Implement reset**

Add to the `impl Game` block:

```rust
pub fn reset(&mut self) {
    self.board = [None; 9];
    self.current_player = Player::X;
    self.status = GameStatus::InProgress;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd tic-tac-toe/server && cargo test
```

Expected: 14 tests pass.

- [ ] **Step 5: Commit**

```bash
git add tic-tac-toe/server/src/game.rs
git commit -m "feat: implement Game::reset() with test"
```

---

## Task 7: API Route Handlers and Server Wiring

**Files:**
- Modify: `tic-tac-toe/server/src/routes.rs`
- Modify: `tic-tac-toe/server/src/main.rs`

- [ ] **Step 1: Implement routes.rs**

Write `tic-tac-toe/server/src/routes.rs`:

```rust
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use uuid::Uuid;

use crate::game::{Game, GameError, GameStatus, Player};

pub type SharedState = Arc<Mutex<HashMap<Uuid, Game>>>;

pub struct AppState {
    pub games: SharedState,
}

#[derive(Serialize)]
struct GameResponse {
    id: Uuid,
    board: [Option<&'static str>; 9],
    current_player: &'static str,
    status: StatusResponse,
}

#[derive(Serialize)]
#[serde(tag = "type")]
enum StatusResponse {
    #[serde(rename = "in_progress")]
    InProgress,
    #[serde(rename = "won")]
    Won {
        winner: &'static str,
        winning_cells: [usize; 3],
    },
    #[serde(rename = "draw")]
    Draw,
}

#[derive(Deserialize)]
pub struct MoveRequest {
    position: usize,
}

#[derive(Serialize)]
struct ErrorResponse {
    error: String,
}

fn player_str(p: Player) -> &'static str {
    match p {
        Player::X => "X",
        Player::O => "O",
    }
}

fn game_to_response(game: &Game) -> GameResponse {
    let board = game.board.map(|cell| cell.map(player_str));
    let status = match &game.status {
        GameStatus::InProgress => StatusResponse::InProgress,
        GameStatus::Won {
            winner,
            winning_cells,
        } => StatusResponse::Won {
            winner: player_str(*winner),
            winning_cells: *winning_cells,
        },
        GameStatus::Draw => StatusResponse::Draw,
    };
    GameResponse {
        id: game.id,
        board,
        current_player: player_str(game.current_player),
        status,
    }
}

async fn create_game(State(state): State<SharedState>) -> impl IntoResponse {
    let game = Game::new();
    let response = game_to_response(&game);
    state.lock().unwrap().insert(game.id, game);
    (StatusCode::CREATED, Json(response))
}

async fn get_game(
    State(state): State<SharedState>,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    let games = state.lock().unwrap();
    match games.get(&id) {
        Some(game) => Ok(Json(game_to_response(game))),
        None => Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "Game not found".to_string(),
            }),
        )),
    }
}

async fn make_move(
    State(state): State<SharedState>,
    Path(id): Path<Uuid>,
    Json(body): Json<MoveRequest>,
) -> impl IntoResponse {
    let mut games = state.lock().unwrap();
    match games.get_mut(&id) {
        Some(game) => match game.make_move(body.position) {
            Ok(()) => Ok(Json(game_to_response(game))),
            Err(e) => Err((
                StatusCode::BAD_REQUEST,
                Json(ErrorResponse {
                    error: e.to_string(),
                }),
            )),
        },
        None => Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "Game not found".to_string(),
            }),
        )),
    }
}

async fn reset_game(
    State(state): State<SharedState>,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    let mut games = state.lock().unwrap();
    match games.get_mut(&id) {
        Some(game) => {
            game.reset();
            Ok(Json(game_to_response(game)))
        }
        None => Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "Game not found".to_string(),
            }),
        )),
    }
}

pub fn api_router() -> Router<SharedState> {
    Router::new()
        .route("/api/games", post(create_game))
        .route("/api/games/{id}", get(get_game))
        .route("/api/games/{id}/moves", post(make_move))
        .route("/api/games/{id}/reset", post(reset_game))
}
```

- [ ] **Step 2: Implement main.rs**

Write `tic-tac-toe/server/src/main.rs`:

```rust
mod game;
mod routes;

use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use tower_http::services::ServeDir;

#[tokio::main]
async fn main() {
    let state = Arc::new(Mutex::new(HashMap::new()));

    let app = routes::api_router()
        .fallback_service(ServeDir::new("static"))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();
    println!("Server running on http://127.0.0.1:3000");
    axum::serve(listener, app).await.unwrap();
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd tic-tac-toe/server && cargo build
```

Expected: compiles with no errors.

- [ ] **Step 4: Commit**

```bash
git add tic-tac-toe/server/src/routes.rs tic-tac-toe/server/src/main.rs
git commit -m "feat: implement API route handlers and server wiring"
```

---

## Task 8: API Integration Tests

**Files:**
- Modify: `tic-tac-toe/server/src/routes.rs`

- [ ] **Step 1: Write integration tests**

Add to the bottom of `tic-tac-toe/server/src/routes.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use http_body_util::BodyExt;
    use tower::ServiceExt;

    fn test_app() -> Router {
        let state: SharedState = Arc::new(Mutex::new(HashMap::new()));
        api_router().with_state(state)
    }

    async fn body_json(body: Body) -> serde_json::Value {
        let bytes = body.collect().await.unwrap().to_bytes();
        serde_json::from_slice(&bytes).unwrap()
    }

    #[tokio::test]
    async fn create_game_returns_201() {
        let app = test_app();
        let response = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/api/games")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::CREATED);
        let json = body_json(response.into_body()).await;
        assert_eq!(json["current_player"], "X");
        assert_eq!(json["status"]["type"], "in_progress");
    }

    #[tokio::test]
    async fn get_game_returns_state() {
        let state: SharedState = Arc::new(Mutex::new(HashMap::new()));
        let app = api_router().with_state(state.clone());

        // Create a game first
        let response = app
            .clone()
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/api/games")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let json = body_json(response.into_body()).await;
        let id = json["id"].as_str().unwrap();

        // Get the game
        let response = app
            .oneshot(
                Request::builder()
                    .method("GET")
                    .uri(&format!("/api/games/{}", id))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn make_valid_move() {
        let state: SharedState = Arc::new(Mutex::new(HashMap::new()));
        let app = api_router().with_state(state.clone());

        // Create game
        let response = app
            .clone()
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/api/games")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let json = body_json(response.into_body()).await;
        let id = json["id"].as_str().unwrap();

        // Make a move
        let response = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri(&format!("/api/games/{}/moves", id))
                    .header("Content-Type", "application/json")
                    .body(Body::from(r#"{"position": 4}"#))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        let json = body_json(response.into_body()).await;
        assert_eq!(json["board"][4], "X");
        assert_eq!(json["current_player"], "O");
    }

    #[tokio::test]
    async fn make_invalid_move_returns_400() {
        let state: SharedState = Arc::new(Mutex::new(HashMap::new()));
        let app = api_router().with_state(state.clone());

        // Create game
        let response = app
            .clone()
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/api/games")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let json = body_json(response.into_body()).await;
        let id = json["id"].as_str().unwrap();

        // Invalid position
        let response = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri(&format!("/api/games/{}/moves", id))
                    .header("Content-Type", "application/json")
                    .body(Body::from(r#"{"position": 99}"#))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    }

    #[tokio::test]
    async fn get_unknown_game_returns_404() {
        let app = test_app();
        let fake_id = Uuid::new_v4();
        let response = app
            .oneshot(
                Request::builder()
                    .method("GET")
                    .uri(&format!("/api/games/{}", fake_id))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::NOT_FOUND);
    }
}
```

- [ ] **Step 2: Add test dependencies to Cargo.toml**

Add to `tic-tac-toe/server/Cargo.toml`:

```toml
[dev-dependencies]
http-body-util = "0.1"
tower = { version = "0.5", features = ["util"] }
```

- [ ] **Step 3: Run all tests**

```bash
cd tic-tac-toe/server && cargo test
```

Expected: all tests pass (14 unit + 5 integration).

- [ ] **Step 4: Commit**

```bash
git add tic-tac-toe/server/
git commit -m "test: add API integration tests for all endpoints"
```

---

## Task 9: Scaffold TypeScript Client

**Files:**
- Create: `tic-tac-toe/client/package.json`
- Create: `tic-tac-toe/client/tsconfig.json`
- Create: `tic-tac-toe/client/vite.config.ts`
- Create: `tic-tac-toe/client/index.html`
- Create: `tic-tac-toe/client/src/main.ts`
- Create: `tic-tac-toe/client/src/api.ts`
- Create: `tic-tac-toe/client/src/style.css`

- [ ] **Step 1: Create package.json**

Write `tic-tac-toe/client/package.json`:

```json
{
  "name": "tic-tac-toe-client",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build"
  },
  "devDependencies": {
    "typescript": "^5.7",
    "vite": "^6"
  }
}
```

- [ ] **Step 2: Create tsconfig.json**

Write `tic-tac-toe/client/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

- [ ] **Step 3: Create vite.config.ts**

Write `tic-tac-toe/client/vite.config.ts`:

```typescript
import { defineConfig } from "vite";

export default defineConfig({
  build: {
    outDir: "../server/static",
    emptyOutDir: true,
  },
  server: {
    proxy: {
      "/api": "http://localhost:3000",
    },
  },
});
```

- [ ] **Step 4: Create index.html**

Write `tic-tac-toe/client/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tic-Tac-Toe</title>
</head>
<body>
  <h1>Tic-Tac-Toe</h1>
  <div class="status" id="status">Loading...</div>
  <div class="board" id="board"></div>
  <button class="reset-btn" id="reset">Reset</button>
  <script type="module" src="/src/main.ts"></script>
</body>
</html>
```

- [ ] **Step 5: Create placeholder source files**

Write `tic-tac-toe/client/src/api.ts`:

```typescript
export {};
```

Write `tic-tac-toe/client/src/main.ts`:

```typescript
import "./style.css";
```

Write `tic-tac-toe/client/src/style.css` (empty file for now):

```css
/* Catppuccin Mocha theme — implemented in Task 11 */
```

- [ ] **Step 6: Install dependencies and verify**

```bash
cd tic-tac-toe/client && npm install && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add tic-tac-toe/client/
git commit -m "feat: scaffold TypeScript client with Vite"
```

---

## Task 10: API Client (`api.ts`)

**Files:**
- Modify: `tic-tac-toe/client/src/api.ts`

- [ ] **Step 1: Implement the API client**

Write `tic-tac-toe/client/src/api.ts`:

```typescript
export interface GameState {
  id: string;
  board: (string | null)[];
  current_player: string;
  status:
    | { type: "in_progress" }
    | { type: "won"; winner: string; winning_cells: number[] }
    | { type: "draw" };
}

async function request<T>(url: string, options?: RequestInit): Promise<T> {
  const response = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (!response.ok) {
    const body = await response.json();
    throw new Error(body.error || "Request failed");
  }
  return response.json();
}

export function createGame(): Promise<GameState> {
  return request("/api/games", { method: "POST" });
}

export function getGame(id: string): Promise<GameState> {
  return request(`/api/games/${id}`);
}

export function makeMove(id: string, position: number): Promise<GameState> {
  return request(`/api/games/${id}/moves`, {
    method: "POST",
    body: JSON.stringify({ position }),
  });
}

export function resetGame(id: string): Promise<GameState> {
  return request(`/api/games/${id}/reset`, { method: "POST" });
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd tic-tac-toe/client && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add tic-tac-toe/client/src/api.ts
git commit -m "feat: implement API client with typed GameState interface"
```

---

## Task 11: Frontend UI (`main.ts` and `style.css`)

**Files:**
- Modify: `tic-tac-toe/client/src/main.ts`
- Modify: `tic-tac-toe/client/src/style.css`

- [ ] **Step 1: Implement style.css**

Write `tic-tac-toe/client/src/style.css`:

```css
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  background: #1e1e2e;
  color: #cdd6f4;
  font-family: 'Segoe UI', system-ui, sans-serif;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
}

h1 {
  font-size: 2rem;
  margin-bottom: 0.5rem;
  color: #cdd6f4;
}

.status {
  font-size: 1.25rem;
  margin-bottom: 1rem;
  min-height: 1.5em;
  color: #bac2de;
}

.board {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;
  background: #45475a;
  padding: 6px;
  border-radius: 12px;
}

.cell {
  width: 110px;
  height: 110px;
  background: #313244;
  border: none;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2.5rem;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s, opacity 0.3s;
  user-select: none;
}

.cell:hover:not(.taken):not(.disabled) {
  background: #45475a;
}

.cell.x { color: #f38ba8; }
.cell.o { color: #89b4fa; }

.cell.winner {
  background: rgba(166, 227, 161, 0.25);
  box-shadow: inset 0 0 0 2px #a6e3a1;
}

.cell.disabled {
  opacity: 0.35;
  cursor: default;
}

.reset-btn {
  margin-top: 1.25rem;
  padding: 0.6rem 1.5rem;
  font-size: 1rem;
  font-weight: 600;
  color: #1e1e2e;
  background: #cba6f7;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.15s;
}

.reset-btn:hover {
  background: #b4befe;
}
```

- [ ] **Step 2: Implement main.ts**

Write `tic-tac-toe/client/src/main.ts`:

```typescript
import "./style.css";
import { createGame, makeMove, resetGame, GameState } from "./api";

const boardEl = document.getElementById("board")!;
const statusEl = document.getElementById("status")!;
const resetBtn = document.getElementById("reset")!;

let gameId: string;

function renderBoard(state: GameState): void {
  boardEl.innerHTML = "";
  const isOver = state.status.type !== "in_progress";
  const winningCells = new Set(
    state.status.type === "won" ? state.status.winning_cells : []
  );

  for (let i = 0; i < 9; i++) {
    const cell = document.createElement("div");
    cell.className = "cell";
    const mark = state.board[i];

    if (mark) {
      cell.textContent = mark;
      cell.classList.add(mark.toLowerCase(), "taken");
    }

    if (isOver) {
      if (winningCells.has(i)) {
        cell.classList.add("winner");
      } else {
        cell.classList.add("disabled");
      }
    } else {
      cell.addEventListener("click", () => handleCellClick(i));
    }

    boardEl.appendChild(cell);
  }
}

function renderStatus(state: GameState): void {
  switch (state.status.type) {
    case "in_progress":
      statusEl.textContent = `${state.current_player}'s turn`;
      statusEl.style.color = "#bac2de";
      break;
    case "won":
      statusEl.textContent = `${state.status.winner} wins!`;
      statusEl.style.color =
        state.status.winner === "X" ? "#f38ba8" : "#89b4fa";
      break;
    case "draw":
      statusEl.textContent = "It's a draw!";
      statusEl.style.color = "#a6adc8";
      break;
  }
}

function render(state: GameState): void {
  renderBoard(state);
  renderStatus(state);
}

async function handleCellClick(position: number): Promise<void> {
  try {
    const state = await makeMove(gameId, position);
    render(state);
  } catch (e) {
    // Ignore invalid move errors — UI will stay on current state
  }
}

async function handleReset(): Promise<void> {
  const state = await resetGame(gameId);
  render(state);
}

async function init(): Promise<void> {
  const state = await createGame();
  gameId = state.id;
  render(state);
}

resetBtn.addEventListener("click", handleReset);
init();
```

- [ ] **Step 3: Verify it compiles**

```bash
cd tic-tac-toe/client && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add tic-tac-toe/client/src/
git commit -m "feat: implement frontend UI with Catppuccin Mocha theme"
```

---

## Task 12: End-to-End Smoke Test

**Files:**
- Create: `tic-tac-toe/server/static/.gitkeep`
- Create: `tic-tac-toe/.gitignore`

- [ ] **Step 1: Add .gitignore**

Write `tic-tac-toe/.gitignore`:

```
server/static/*
!server/static/.gitkeep
server/target/
client/node_modules/
client/dist/
```

Create `tic-tac-toe/server/static/.gitkeep` (empty file).

- [ ] **Step 2: Build the frontend**

```bash
cd tic-tac-toe/client && npm run build
```

Expected: output files in `../server/static/` (index.html, assets/).

- [ ] **Step 3: Run all Rust tests**

```bash
cd tic-tac-toe/server && cargo test
```

Expected: all tests pass.

- [ ] **Step 4: Manual smoke test**

```bash
cd tic-tac-toe/server && cargo run &
```

Open `http://127.0.0.1:3000` in a browser. Verify:
- Board renders with Catppuccin Mocha colors
- Clicking a cell places X, then O alternates
- Win highlights the winning cells and disables the rest
- Draw shows the draw message
- Reset clears the board

Stop the server when done.

- [ ] **Step 5: Commit**

```bash
git add tic-tac-toe/.gitignore tic-tac-toe/server/static/.gitkeep
git commit -m "chore: add gitignore and finalize project structure"
```
