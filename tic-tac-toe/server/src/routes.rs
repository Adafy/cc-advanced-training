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
