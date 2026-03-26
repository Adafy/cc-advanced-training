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

use crate::game::{Game, GameStatus, Player};

pub type SharedState = Arc<Mutex<HashMap<Uuid, Game>>>;

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
