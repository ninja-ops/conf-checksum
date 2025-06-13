#!/bin/bash

# === Save original working directory ===
ORIGINAL_DIR=$(pwd)

# === Parse parameters ===
REPO_PATH=${1:-"."}                              # Default: current directory
BRANCH=${2:-main}                                # Default: main (not used, kept for compatibility)
MESSAGE=${3:-"Forced commit: all changes"}       # Default commit message

# === Check if valid Git repository ===
if [ ! -d "$REPO_PATH/.git" ]; then
    echo "Not a valid Git repository: $REPO_PATH"
    exit 1
fi

# === Change to repository directory ===
cd "$REPO_PATH" || exit 1
echo "Working directory: $(pwd)"

# === Git operations ===
echo "Adding all files..."
git add -A

# === Check for staged changes ===
if git diff --cached --quiet; then
    echo "No changes to commit."
else
    echo "Creating commit..."
    git commit -m "$MESSAGE"
fi

# === Return to original directory ===
cd "$ORIGINAL_DIR" || exit 1
echo "Returned to: $ORIGINAL_DIR"

echo "Done."
