# List all available commands
default:
    @just --list

# Start the tic-tac-toe game (builds client + runs Rust server on :3000)
start:
    ./scripts/start-rust-ttt.sh start

# Stop the tic-tac-toe game
stop:
    ./scripts/start-rust-ttt.sh stop

# Start the claude CLI and run the /install slash command
install:
    claude "/install"

# Short explanation of whole project
prime:
    claude -p "/prime"
