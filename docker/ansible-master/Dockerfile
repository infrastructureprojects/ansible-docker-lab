# =============================================================================
# Ansible Master (Control Node)
# -----------------------------------------------------------------------------
# Purpose:
#   - Run Ansible playbooks
#   - Manage SSH keys
#   - Execute automation against Docker container nodes
#   - Support plugins, vault, facts caching, collections
#
# Notes:
#   - NO systemd
#   - CI/CD safe
#   - Production-aligned
# =============================================================================

FROM ubuntu:22.04

LABEL maintainer="ansible-lab"
LABEL role="ansible-master"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# -----------------------------------------------------------------------------
# Install OS packages
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    openssh-client \
    openssh-server \
    sshpass \
    rsync \
    git \
    curl \
    wget \
    vim \
    nano \
    less \
    iputils-ping \
    net-tools \
    ca-certificates \
    tzdata \
    cron \
    unzip \
    jq \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Install Ansible (pip-based for consistency)
# -----------------------------------------------------------------------------
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
      ansible \
      ansible-lint \
      jmespath \
      netaddr \
      passlib \
      cryptography

# -----------------------------------------------------------------------------
# Prepare SSH (client side only)
# -----------------------------------------------------------------------------
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    echo "StrictHostKeyChecking no" > /root/.ssh/config

# -----------------------------------------------------------------------------
# Workspace
# -----------------------------------------------------------------------------
WORKDIR /lab

# -----------------------------------------------------------------------------
# Copy entire lab (playbooks, roles, inventory, plugins, scripts)
# -----------------------------------------------------------------------------
COPY . /lab

# -----------------------------------------------------------------------------
# Ensure script permissions
# -----------------------------------------------------------------------------
RUN chmod +x /lab/scripts/bootstrap_ssh.sh || true

# -----------------------------------------------------------------------------
# Ansible defaults (facts cache directory)
# -----------------------------------------------------------------------------
RUN mkdir -p /lab/.facts && chmod 755 /lab/.facts

# -----------------------------------------------------------------------------
# Verify installation (build-time sanity checks)
# -----------------------------------------------------------------------------
RUN ansible --version && \
    python3 --version && \
    ssh -V

# -----------------------------------------------------------------------------
# Default shell
# -----------------------------------------------------------------------------
CMD ["/bin/bash"]
