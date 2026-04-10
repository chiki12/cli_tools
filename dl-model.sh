#!/bin/bash
# Usage: dl-model <hf_repo> [hf_repo2] [hf_repo3] ...
# Examples:
#   dl-model Qwen/Qwen3.5-4B-Base
#   dl-model Qwen/Qwen3-8B Qwen/Qwen3.5-4B-Base meta-llama/Llama-3-8B

DOWNLOAD_DIR="/large/qluo"
MODELS_DIR="$HOME/models"

if [ -z "$1" ]; then
    echo "Usage: dl-model <hf_repo> [hf_repo2] ..."
    echo "  e.g. dl-model Qwen/Qwen3.5-4B-Base Qwen/Qwen3-8B"
    echo ""
    echo "Available models:"
    if [ -d "$MODELS_DIR" ]; then
        ls -1 "$MODELS_DIR" 2>/dev/null | sed 's/^/  /'
    else
        echo "  (none yet)"
    fi
    exit 1
fi

# Activate base conda env for hf cli
eval "$(conda shell.bash hook)"
conda activate base

mkdir -p "$MODELS_DIR"

for REPO in "$@"; do
    MODEL_NAME=$(basename "$REPO")
    TARGET="$DOWNLOAD_DIR/$MODEL_NAME"
    LINK="$MODELS_DIR/$MODEL_NAME"

    echo "=========================================="
    echo "Processing: $REPO"
    echo "=========================================="

    # Download
    if [ -d "$TARGET" ]; then
        echo "Already downloaded: $TARGET"
    else
        echo "Downloading $REPO -> $TARGET"
        hf download "$REPO" --local-dir "$TARGET"
        if [ $? -ne 0 ]; then
            echo "Download failed for $REPO, skipping..."
            continue
        fi
    fi

    # Symlink
    if [ -L "$LINK" ] || [ -e "$LINK" ]; then
        echo "Symlink already exists: $LINK"
    else
        ln -s "$TARGET" "$LINK"
        echo "Created symlink: $LINK -> $TARGET"
    fi

    echo "Ready: vllm serve ~/models/$MODEL_NAME"
    echo ""
done

echo "Done!"
