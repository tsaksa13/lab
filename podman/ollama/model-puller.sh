#!/bin/bash
# Download Ollama models optimized for GTX 1050 Ti (4GB VRAM)
# This script downloads models suitable for coding and reasoning tasks

set -e

echo "=========================================="
echo "Ollama Model Download for GTX 1050 Ti"
echo "=========================================="
echo ""
echo "Your GTX 1050 Ti has 4GB VRAM. Downloading models that fit:"
echo "  - 3-4 coding-focused models"
echo "  - 1 reasoning-focused model"
echo ""

# Check if ollama command is available
if ! sudo -u podman-svc podman exec -it ollama ollama --version &>/dev/null; then
    echo "ERROR: Ollama container not running or not accessible"
    echo "Please ensure the ollama service is running:"
    echo "  sudo systemctl start ollama.service"
    exit 1
fi

# Function to pull a model
pull_model() {
    local model=$1
    local description=$2
    echo ""
    echo "=========================================="
    echo "Downloading: $model"
    echo "Purpose: $description"
    echo "=========================================="
    sudo -u podman-svc podman exec -it ollama ollama pull "$model"
    echo "✓ $model downloaded successfully"
}

echo "Starting model downloads..."
echo ""

# Coding Models (3-4 models)
echo "=== CODING MODELS ==="

# 1. CodeLlama 7B - Excellent for code completion and generation
pull_model "codellama:7b" "Code completion, generation, and debugging (fits in 4GB VRAM)"

# 2. DeepSeek Coder 6.7B - Strong coding performance, compact
pull_model "deepseek-coder:6.7b" "Advanced code understanding and generation (optimized for VRAM)"

# 3. Qwen2.5-Coder 7B - Multilingual coding, very efficient
pull_model "qwen2.5-coder:7b" "Multilingual coding support, efficient for constrained VRAM"

# 4. Stable Code 3B - Lightweight, fast responses
pull_model "stable-code:3b" "Lightweight coding assistant, very fast (minimal VRAM usage)"

# Reasoning Model (1 model)
echo ""
echo "=== REASONING MODEL ==="

# DeepSeek R1 Distill Qwen 7B - Reasoning-focused, fits in 4GB
pull_model "deepseek-r1:7b" "Chain-of-thought reasoning, problem solving (fits 4GB VRAM)"

# Optional: Text Embedding Model for semantic search (if VRAM allows)
pull_model "nomic-embed-text" "Text embedding model for semantic search and retrieval"

echo ""
echo "=========================================="
echo "Download Complete!"
echo "=========================================="
echo ""
echo "Models downloaded:"
echo "  CODING:"
echo "    1. codellama:7b - General code tasks"
echo "    2. deepseek-coder:6.7b - Advanced coding"
echo "    3. qwen2.5-coder:7b - Multilingual code"
echo "    4. stable-code:3b - Fast, lightweight"
echo ""
echo "  REASONING:"
echo "    5. deepseek-r1:7b - Problem solving & reasoning"
echo ""
echo "To list all models:"
echo "  sudo -u podman-svc podman exec -it ollama ollama list"
echo ""
echo "To test a model:"
echo "  sudo -u podman-svc podman exec -it ollama ollama run codellama:7b"
echo ""
echo "To use in Open WebUI:"
echo "  Access your Open WebUI interface and select models from the dropdown"
echo ""
echo "VRAM Usage Tips:"
echo "  - Run ONE model at a time on your 1050 Ti"
echo "  - 7B models will use ~3.5-4GB VRAM"
echo "  - 3B models will use ~2GB VRAM"
echo "  - If you get OOM errors, try the 3B model (stable-code:3b)"
echo ""