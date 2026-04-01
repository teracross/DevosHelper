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
    code "$FILE_PATH" >/dev/null 2>&1 &
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

