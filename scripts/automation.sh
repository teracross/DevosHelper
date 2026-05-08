#!/usr/bin/env bash
set -euo pipefail

# Default values (can be overridden by environment variables)
REMOTE="origin"
BRANCH="main"
FILE="current.md"
BACKUP="previous.md"
REPO_ROOT=""
DAILY_URL="https://www.google.com"

# Resolve repo root (require being inside a git worktree)
if ! REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "Error: not inside a git repository (cannot determine repo root)" >&2
  exit 1
fi
cd "$REPO_ROOT"

# Use absolute paths based on repo root to avoid cwd issues
FILE_PATH="$REPO_ROOT/$FILE"
BACKUP_PATH="$REPO_ROOT/$BACKUP"

if [ ! -f "$FILE_PATH" ]; then
  echo "Error: $FILE not found in $REPO_ROOT" >&2
  exit 1
fi

# Function to retrieve URL from current.md file
function get_url_from_third_line() {
  # grabs the third line of $FILE - stores in local variable called "textline"
  textline=$(awk 'NR==3{print; exit}' "$FILE" || true)

  # parses "textline" for text that begins with "https://" and ends with ".html"
  # if exists override variable DAILY_URL with found value
  # else if not exists do nothing (leave DAILY_URL as-is)
  if [ -n "$textline" ]; then
    # extract first https://...*.html token if present
    found=$(printf '%s\n' "$textline" | grep -oE 'https://[^[:space:]]+\.html' | head -n1 || true)
    if [ -n "$found" ]; then
      DAILY_URL="$found"
    fi
  fi

  echo "Using DAILY_URL: $DAILY_URL"
}

# Determine whether system time has passed 03:00 today
NOW_TS=$(date +%s)
THREE_AM_TS=$(date -d 'today 03:00' +%s)

if [ "$NOW_TS" -lt "$THREE_AM_TS" ]; then
  # It's not yet 03:00 today — allow more time
  echo "No edits made, there is still time before the deadline. Keep working at it!"
  get_url_from_third_line()
  TARGET_URL="$DAILY_URL" code "$REPO_ROOT"
  exit 0
fi

# It's past 03:00 today — check filesystem modification time (mtime) of the file
FILE_MTIME=$(stat -c %Y -- "$FILE_PATH")
if [ "$FILE_MTIME" -gt "$THREE_AM_TS" ]; then
  echo "No edits made, current day progress detected."
  get_url_from_third_line()
  TARGET_URL="$DAILY_URL" code "$REPO_ROOT"
  exit 0
fi

# Backup
cp -- "$FILE_PATH" "$BACKUP_PATH"

echo "Fetching $REMOTE/$BRANCH..."
# Fetch just the branch to update remote ref
git fetch "$REMOTE" "$BRANCH" --depth=1

echo "Retrieving $FILE from $REMOTE/$BRANCH..."
# Use git show to extract the file from the remote ref; fail if missing
if git show "$REMOTE/$BRANCH:$FILE" > "$FILE_PATH".new 2>/dev/null; then
  mv -- "$FILE_PATH".new "$FILE_PATH"
  echo "Updated $FILE from $REMOTE/$BRANCH and saved backup to $BACKUP"

  # Try to open the updated file in VS Code if the `code` CLI is available
  if command -v code >/dev/null 2>&1; then
    get_url_from_third_line()
    TARGET_URL="$DAILY_URL" code "$REPO_ROOT" &
    echo "Opened $FILE in VS Code."
  else
    echo "VS Code CLI 'code' not found; skipping open."
  fi

  exit 0
else
  rm -f -- "$FILE_PATH".new
  echo "Error: $FILE not present on $REMOTE/$BRANCH" >&2
  exit 2
fi

