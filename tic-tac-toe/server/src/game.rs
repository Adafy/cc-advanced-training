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
