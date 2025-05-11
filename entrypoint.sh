#!/bin/sh
set -euo pipefail

echo "[INFO] Setting up SSH key..."
# --- SSH Key Setup ---
if [ -z "${SSH_KEY:-}" ]; then
  echo "Error: SSH_KEY environment variable is not set." >&2
  exit 1
fi

mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$SSH_KEY" | base64 -d > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Extract host from REPO_URL for known_hosts
echo "[INFO] Configuring SSH known_hosts for repo host..."
if [ -z "${REPO_URL:-}" ]; then
  echo "Error: REPO_URL environment variable is not set." >&2
  exit 1
fi
# Extract host for SSH URLs (e.g., git@github.com:user/repo.git)
GIT_HOST=$(echo "$REPO_URL" | sed -E 's#.*@([^:]+):.*#\1#')
echo "[INFO] Adding $GIT_HOST to known_hosts..."
ssh-keyscan "$GIT_HOST" >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

echo "[INFO] Configuring Git user..."
# --- Git Config ---
git config --global user.name "${USERNAME:-user}"
git config --global user.email "${EMAIL:-user@example.com}"

echo "[INFO] Cloning repository $REPO_URL (branch: ${BASE_BRANCH:-main})..."
# --- Clone Repo ---
cd /app
git clone --branch "${BASE_BRANCH:-main}" "$REPO_URL" repo
cd repo

echo "[INFO] Creating new branch for changes..."
# --- Create Branch ---
if [ -z "${TITLE:-}" ]; then
  echo "Error: TITLE environment variable is not set." >&2
  exit 1
fi
KEBAB_TITLE=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '-')
NEW_BRANCH="r4r/$KEBAB_TITLE"
git checkout -b "$NEW_BRANCH"

echo "[INFO] Running ra-aid with provided instructions..."
# --- Run ra-aid ---
if [ -z "${INSTRUCTIONS_TEXT:-}" ]; then
  echo "Error: INSTRUCTIONS_TEXT environment variable is not set." >&2
  exit 1
fi
if [ -z "${RA_AID_PROVIDER:-}" ] || [ -z "${RA_AID_MODEL:-}" ] || [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "Error: RA_AID_PROVIDER, RA_AID_MODEL, or OPENAI_API_KEY environment variable is not set." >&2
  exit 1
fi

ra-aid --provider "$RA_AID_PROVIDER" \
       --model "$RA_AID_MODEL" \
       -m "$INSTRUCTIONS_TEXT" \
       --cowboy-mode


echo "[INFO] Deleting .ra-aid directory..."
rm -rf .ra-aid

echo "[INFO] Committing and pushing changes to $NEW_BRANCH..."
git add .
git commit -m "$TITLE"
git push origin "$NEW_BRANCH"

echo "[INFO] Creating pull request on GitHub..."

# if [ -z "${GITHUB_TOKEN:-}" ]; then
#   echo "Error: GITHUB_TOKEN environment variable is not set." >&2
#   exit 1
# fi

# Parse owner and repo from REPO_URL (assumes SSH URL)
REPO_PATH=$(echo "$REPO_URL" | sed -E 's#.*:([^/]+/[^.]+)(\\.git)?#\\1#')
OWNER=$(echo "$REPO_PATH" | cut -d/ -f1)
REPO=$(echo "$REPO_PATH" | cut -d/ -f2)

# Create the PR
gh pr create --head "$NEW_BRANCH" --base "${BASE_BRANCH}" --title "[R4R] $TITLE" --body ""
