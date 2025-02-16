#!/usr/bin/env bash
set -euo pipefail

# --- Prompt for the GitHub email ---
read -rp "Enter your GitHub email: " GITHUB_EMAIL

# --- Prompt for Git global configuration ---
echo "Setup for .gitconfig..."
read -rp "Enter your Git user name: " GIT_USER_NAME
read -rp "Enter your Git user email: " GIT_USER_EMAIL

# --- Configuration ---
SSH_KEY_FILE="$HOME/.ssh/id_ed25519"

# --- Ensure the .ssh directory exists ---
if [ ! -d "$HOME/.ssh" ]; then
  echo "Creating $HOME/.ssh directory..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
fi

# --- Generate the SSH key if it doesn't exist ---
if [ -f "$SSH_KEY_FILE" ]; then
  echo "SSH key already exists at $SSH_KEY_FILE. Skipping key generation."
else
  echo "Generating new SSH key for $GITHUB_EMAIL..."
  ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$SSH_KEY_FILE" -N ""
fi

# --- Start ssh-agent and add the key ---
echo "Starting ssh-agent..."
eval "$(ssh-agent -s)"
echo "Adding SSH key to ssh-agent..."
ssh-add "$SSH_KEY_FILE"

# --- Copy the public key to clipboard if possible ---
echo "Attempting to copy the public key to clipboard..."
if command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "${SSH_KEY_FILE}.pub"
  echo "Public key copied to clipboard. Paste it into GitHub (Settings → SSH and GPG keys)."
elif command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "${SSH_KEY_FILE}.pub"
  echo "Public key copied to clipboard. Paste it into GitHub (Settings → SSH and GPG keys)."
else
  echo "Clipboard tool not found. Here is your public key:"
  cat "${SSH_KEY_FILE}.pub"
  echo "Copy the above key and add it to GitHub (Settings → SSH and GPG keys)."
fi

# --- Pause to allow the user to add their SSH key to GitHub ---
echo ""
read -rp "Press Enter after you have added your SSH key to GitHub..."

# --- Configure Git global user settings ---
echo "Configuring Git global settings..."
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
echo "Git global user.name set to: $(git config --global user.name)"
echo "Git global user.email set to: $(git config --global user.email)"

echo "Testing connection to GitHub..."
output=$(ssh -T git@github.com 2>&1 || true)
if echo "$output" | grep -q "successfully authenticated"; then
  echo "SSH setup for GitHub is complete!"
else
  echo "There was an issue connecting to GitHub. Please verify your SSH key was added correctly."
fi
