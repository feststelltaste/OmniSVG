#!/usr/bin/env bash
set -euo pipefail

# ── Persistent directories ────────────────────────────────────────────────────
mkdir -p \
    /workspace/.cache/huggingface \
    /workspace/models \
    /workspace/output

# ── Verify PyTorch + CUDA ─────────────────────────────────────────────────────
echo "=== Environment Check ==="
python - <<'EOF'
import sys, torch
print(f"Python  : {sys.version.split()[0]}")
print(f"PyTorch : {torch.__version__}")
print(f"CUDA    : {torch.version.cuda}")
print(f"GPU available : {torch.cuda.is_available()}")
if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        vram_gb = props.total_memory / 1024**3
        print(f"  GPU {i}: {props.name}  ({vram_gb:.1f} GB VRAM)")
EOF

# ── Model pre-download ────────────────────────────────────────────────────────
# HF_HOME=/workspace/.cache/huggingface is mounted from the host, so these
# downloads survive container rebuilds – they only run the very first time.

HF_CACHE="${HF_HOME:-/workspace/.cache/huggingface}/hub"

download_if_missing() {
    local repo_id="$1"           # e.g. OmniSVG/OmniSVG1.1_4B
    local cache_dir_name="$2"    # e.g. models--OmniSVG--OmniSVG1.1_4B
    local description="$3"

    if [ -d "${HF_CACHE}/${cache_dir_name}" ]; then
        echo "  [cached]  ${description}"
    else
        echo "  [downloading]  ${description}"
        python -c "from huggingface_hub import snapshot_download; snapshot_download('${repo_id}')"
        echo "  [done]    ${description}"
    fi
}

echo ""
echo "=== Model cache check (HF_HOME=${HF_HOME:-/workspace/.cache/huggingface}) ==="

# OmniSVG 4B fine-tuned weights (~7.6 GB)
download_if_missing \
    "OmniSVG/OmniSVG1.1_4B" \
    "models--OmniSVG--OmniSVG1.1_4B" \
    "OmniSVG 4B weights"

# Qwen2.5-VL-3B-Instruct backbone (~6 GB)
download_if_missing \
    "Qwen/Qwen2.5-VL-3B-Instruct" \
    "models--Qwen--Qwen2.5-VL-3B-Instruct" \
    "Qwen2.5-VL-3B-Instruct base model"

# ── Ready ─────────────────────────────────────────────────────────────────────
cat <<'MSG'

=== OmniSVG devcontainer ready ===

Run the Gradio demo (port 7860):
  python app.py --preload-model 4B

Run inference directly:
  python inference.py \
      --task text-to-svg \
      --input prompts.txt \
      --output ./output \
      --model-size 4B \
      --save-all-candidates

MSG
