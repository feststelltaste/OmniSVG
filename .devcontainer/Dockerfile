FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
# Virtual environment path – activated via PATH for every RUN/CMD
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# ── System dependencies ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.10 \
        python3.10-dev \
        python3.10-venv \
        python3-pip \
        # Required by CairoSVG
        libcairo2 \
        libcairo2-dev \
        pkg-config \
        # Common dev tools
        git \
        curl \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# ── Non-root user (matches VS Code devcontainer convention) ──────────────────
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# ── Python virtual environment ───────────────────────────────────────────────
RUN python3.10 -m venv ${VIRTUAL_ENV}

# ── Python packages ──────────────────────────────────────────────────────────
# Copy requirements so layer is cached unless the file changes.
COPY requirements.txt /tmp/requirements.txt

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip \
    # Step 1: everything except torch/torchvision (requirements.txt pins old
    #         CPU-only versions; we override them in Step 2).
    && grep -vE '^torch(vision)?==' /tmp/requirements.txt > /tmp/requirements-notorch.txt \
    && pip install -r /tmp/requirements-notorch.txt \
    && pip install "huggingface-hub>=0.30.0,<1.0" \
    && pip install accelerate \
    # Step 2: PyTorch with CUDA 12.4 — Blackwell (sm_120) support requires 2.6+.
    #         Installed last so it always wins over any stale CPU wheels.
    && pip install \
        torch torchvision \
        --index-url https://download.pytorch.org/whl/cu128 \
    && rm /tmp/requirements.txt /tmp/requirements-notorch.txt \
    && chown -R ${USERNAME}:${USERNAME} ${VIRTUAL_ENV}

# ── Final container setup ────────────────────────────────────────────────────
USER ${USERNAME}
WORKDIR /workspace
