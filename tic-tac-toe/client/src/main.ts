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
