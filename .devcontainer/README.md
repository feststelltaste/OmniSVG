# OmniSVG Dev Container

## How model caching works

`HF_HOME` inside the container points to `./cache/huggingface` in your workspace
(a gitignored directory on your host machine).  
`post-install.sh` downloads the models there **once** on first container creation —
every subsequent open, stop, start, or rebuild finds them already on disk and skips the download.

---

## Prerequisites

### Windows / WSL2 host

- Windows 11 or Windows 10 21H2+
- Latest NVIDIA GPU driver (Windows side — do **not** install a Linux driver inside WSL2)
- [NVIDIA Container Toolkit for WSL2](https://docs.nvidia.com/cuda/wsl-user-guide/index.html#ch04-sub02-install-cuda-toolkit)

  ```powershell
  # Quick check: run this inside WSL2 – should print your GPU name
  nvidia-smi
  ```

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with **WSL2 backend** enabled
- [VS Code](https://code.visualstudio.com/) + [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

---

## First-time setup

### Step 1 — Export your Hugging Face token (host shell)

```bash
# Add to ~/.bashrc or ~/.zshrc so it persists across sessions
export HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Get a (free, read-only) token at <https://huggingface.co/settings/tokens>.

### Step 2 — Open the repo in the container

In VS Code: **F1 → Dev Containers: Reopen in Container**

**What happens on first open (one-time only):**

| Stage | What | Duration |
|-------|------|----------|
| Image build | CUDA base image + Python wheels | ~10–15 min |
| Post-create | GPU check | seconds |
| Post-create | Download OmniSVG 4B weights (~7.6 GB) | depends on bandwidth |
| Post-create | Download Qwen2.5-VL-3B base model (~6 GB) | depends on bandwidth |

**On every subsequent open** the container starts in seconds — the models are already on disk.

### Step 3 — Start the app

```bash
python app.py --preload-model 4B
```

Open <http://localhost:7860> in your browser.

---

## Running inference from the command line

**Text → SVG**

```bash
# Put one prompt per line in prompts.txt, then:
python inference.py \
    --task text-to-svg \
    --input prompts.txt \
    --output ./output \
    --model-size 4B \
    --save-all-candidates
```

**Image → SVG**

```bash
python inference.py \
    --task image-to-svg \
    --input ./examples \
    --output ./output_image \
    --model-size 4B \
    --save-all-candidates
```

---

## GPU memory requirements

| Model | Min VRAM | Backbone |
|-------|----------|----------|
| 4B    | ~8 GB    | Qwen2.5-VL-3B-Instruct |
| 8B    | ~16 GB   | Qwen2.5-VL-7B-Instruct |

---

## Updating Python dependencies

If `requirements.txt` changes, rebuild the image:

**F1 → Dev Containers: Rebuild Container**

The model cache is untouched by rebuilds.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `could not select device driver "" with capabilities: [[gpu]]` | NVIDIA Container Toolkit not installed, or Docker Desktop not restarted after install |
| `CUDA out of memory` | Lower `--max-length` or reduce `--num-candidates` |
| `FileNotFoundError: pytorch_model.bin` | Model download was interrupted — delete `./cache/huggingface/hub/models--OmniSVG--OmniSVG1.1_4B` and reopen the container to re-trigger the download |
| `HF_TOKEN` not passed into container | Make sure it is exported in the **host** shell **before** VS Code opens the container |
