#!/usr/bin/env bash
set -euo pipefail

read -r -p "Is this system mac or linux? [mac/linux]: " OS_TYPE
case "$OS_TYPE" in
  mac)
    RC_FILE="$HOME/.zshrc"
    ;;
  linux)
    RC_FILE="$HOME/.bashrc"
    ;;
  *)
    echo "Invalid choice. Please enter: mac or linux" >&2
    exit 1
    ;;
esac

BIN_DIR="$HOME/bin"
BASHRC="$HOME/.bashrc"
PATH_LINE='export PATH="$HOME/bin:$PATH"'

# Directory where this setup script itself is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SELF_NAME="$(basename -- "${BASH_SOURCE[0]}")"

declare -a ADDED_PATH_LINES=()
declare -a CREATED_LINKS=()
declare -a FIXED_LINKS=()
declare -a CHMODDED_FILES=()
declare -a ALREADY_OK=()
declare -a SKIPPED_FILES=()

# 1) Ensure ~/bin exists
mkdir -p "$BIN_DIR"

# 2) Ensure rc file contains ~/bin PATH line
if [[ -f "$RC_FILE" ]]; then
  if grep -Fqx "$PATH_LINE" "$RC_FILE"; then
    :
  else
    echo "$PATH_LINE" >> "$RC_FILE"
    ADDED_PATH_LINES+=("$RC_FILE")
  fi
else
  echo "$PATH_LINE" > "$RC_FILE"
  ADDED_PATH_LINES+=("$RC_FILE")
fi

# 3) Make sure current script process can see ~/bin too
export PATH="$HOME/bin:$PATH"

# Helper: check whether a command is currently runnable
command_works() {
  local cmd_name="$1"
  command -v "$cmd_name" >/dev/null 2>&1
}

# check if file is a shebang
has_shebang() {
  local f="$1"
  local first_line
  first_line="$(head -n 1 "$f" 2>/dev/null || true)"
  [[ "$first_line" == '#!'* ]]
}

# 4) Iterate over all files in the same folder, excluding this setup script itself
shopt -s nullglob
for src_path in "$SCRIPT_DIR"/*; do
  # only regular files
  [[ -f "$src_path" ]] || continue

  file_name="$(basename -- "$src_path")"

  # skip itself
  if [[ "$file_name" == "$SELF_NAME" ]]; then
    continue
  fi

  # process files that either have .sh extension OR have shebang OR are already executable
  if [[ "$file_name" == *.sh ]]; then
    cmd_name="${file_name%.sh}"
  elif has_shebang "$src_path" || [[ -x "$src_path" ]]; then
    cmd_name="$file_name"
  else
    SKIPPED_FILES+=("$src_path (skipped: not .sh, no shebang, not executable)")
    continue
  fi

  link_path="$BIN_DIR/$cmd_name"

  # First check whether command already works
  if command_works "$cmd_name"; then
    ALREADY_OK+=("$cmd_name (already available: $(command -v "$cmd_name"))")
    continue
  fi

  # If symlink exists, verify/fix it
  if [[ -L "$link_path" ]]; then
    current_target="$(readlink "$link_path" || true)"
    if [[ "$current_target" != "$src_path" ]]; then
      ln -sfn "$src_path" "$link_path"
      FIXED_LINKS+=("$link_path -> $src_path")
    fi
  elif [[ -e "$link_path" ]]; then
    # A regular file or directory already exists there, so skip safely
    SKIPPED_FILES+=("$cmd_name (cannot create symlink because $link_path already exists and is not a symlink)")
    continue
  else
    ln -s "$src_path" "$link_path"
    CREATED_LINKS+=("$link_path -> $src_path")
  fi

  # Ensure source file is executable
  if [[ ! -x "$src_path" ]]; then
    chmod +x "$src_path"
    CHMODDED_FILES+=("$src_path")
  fi

  # Re-check if command works now
  if command_works "$cmd_name"; then
    :
  else
    SKIPPED_FILES+=("$cmd_name (linked but still not runnable; check shebang or script content)")
  fi
done
shopt -u nullglob

# 5) Output summary
echo "===== Summary ====="

if (( ${#ADDED_PATH_LINES[@]} > 0 )); then
  echo
  echo "[Updated PATH config]"
  for x in "${ADDED_PATH_LINES[@]}"; do
    echo "  - added PATH line to: $x"
  done
fi

if (( ${#CREATED_LINKS[@]} > 0 )); then
  echo
  echo "[Created symbolic links]"
  for x in "${CREATED_LINKS[@]}"; do
    echo "  - $x"
  done
fi

if (( ${#FIXED_LINKS[@]} > 0 )); then
  echo
  echo "[Fixed symbolic links]"
  for x in "${FIXED_LINKS[@]}"; do
    echo "  - $x"
  done
fi

if (( ${#CHMODDED_FILES[@]} > 0 )); then
  echo
  echo "[Added executable permission]"
  for x in "${CHMODDED_FILES[@]}"; do
    echo "  - chmod +x $x"
  done
fi

if (( ${#ALREADY_OK[@]} > 0 )); then
  echo
  echo "[Already available commands]"
  for x in "${ALREADY_OK[@]}"; do
    echo "  - $x"
  done
fi

if (( ${#SKIPPED_FILES[@]} > 0 )); then
  echo
  echo "[Warnings / skipped]"
  for x in "${SKIPPED_FILES[@]}"; do
    echo "  - $x"
  done
fi

echo
echo "Done."

# 6) Source rc file only if this script is sourced
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  # shellcheck disable=SC1090
  source "$RC_FILE"
  echo "$RC_FILE sourced into current shell."
else
  echo "Run this to apply rc file to your current shell:"
  echo "  source \"$RC_FILE\""
fi
