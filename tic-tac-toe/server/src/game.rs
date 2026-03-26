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

const WIN_COMBOS: [[usize; 3]; 8] = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6],             // diagonals
];

impl Game {
    pub fn new() -> Self {
        Game {
            id: Uuid::new_v4(),
            board: [None; 9],
            current_player: Player::X,
            status: GameStatus::InProgress,
        }
    }

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
}
