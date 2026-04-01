#!/usr/bin/env bash
set -euo pipefail

# Hardcoded remote/branch as requested
REMOTE="origin"
BRANCH="main"
FILE="current.md"
BACKUP="previous.md"

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

# Determine whether system time has passed 03:00 today
NOW_TS=$(date +%s)
THREE_AM_TS=$(date -d 'today 03:00' +%s)

if [ "$NOW_TS" -lt "$THREE_AM_TS" ]; then
  # It's not yet 03:00 today — allow more time
  echo "No edits made, there is still time before the deadline. Keep working at it!"
  exit 0
fi

# It's past 03:00 today — check filesystem modification time (mtime) of the file
FILE_MTIME=$(stat -c %Y -- "$FILE_PATH")
if [ "$FILE_MTIME" -gt "$THREE_AM_TS" ]; then
  echo "No edits made, current day progress detected."
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
    code "$FILE_PATH" &
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

