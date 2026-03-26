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
