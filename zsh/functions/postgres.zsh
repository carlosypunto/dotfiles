# Starts Postgres.app in the background without opening the GUI.
# Usage: pgstart
function pgstart() {
    open -a "Postgres";
}

# Stops all PostgreSQL servers managed by Postgres.app.
# Usage: pgstop
function pgstop() {
    osascript -e 'quit app "Postgres"';
}
