# AI Agents Sandbox - Secure DevContainer
# Claude Code, Codex CLI, Antigravity CLI

# Pinned to a patch version + digest for reproducible builds.
# To update: bump the tag and re-resolve the digest for node:<tag>.
FROM node:24.18.0-bookworm-slim@sha256:b31e7a42fdf8b8aa5f5ed477c72d694301273f1069c5a2f71d53c6482e99a2fc

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    sudo \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Rename existing node user to vscode (node image already has UID/GID 1000)
ARG USERNAME=vscode

RUN usermod -l $USERNAME -d /home/$USERNAME -m node \
    && groupmod -n $USERNAME node \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set npm global directory for non-root user
ENV NPM_CONFIG_PREFIX=/home/$USERNAME/.npm-global
ENV PATH=/home/$USERNAME/.local/bin:$NPM_CONFIG_PREFIX/bin:$PATH

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Create necessary directories
RUN mkdir -p /home/$USERNAME/.npm-global \
    && mkdir -p /home/$USERNAME/.local/bin \
    && mkdir -p /home/$USERNAME/.claude \
    && mkdir -p /home/$USERNAME/.codex \
    && mkdir -p /home/$USERNAME/.gemini/antigravity-cli \
    && mkdir -p /home/$USERNAME/.ssh \
    && mkdir -p /home/$USERNAME/.config/git/hooks

# Install Claude Code, Codex CLI, and dev tools via npm (pinned versions)
RUN npm install -g @anthropic-ai/claude-code@2.1.195 \
    && npm install -g @openai/codex@0.142.3 \
    && npm install -g lefthook \
    && npm install -g secretlint @secretlint/secretlint-rule-preset-recommend

# Install Antigravity CLI via official script.
# NOTE: the official installer always fetches the latest release and offers
# no version-pin option, so this step is intentionally unpinned. It does
# verify a sha512 of the download against the release manifest.
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

# Set working directory
WORKDIR /workspaces

# Default shell
SHELL ["/bin/bash", "-c"]
