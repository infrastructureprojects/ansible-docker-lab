# =============================================================================
# Ansible Master (Control Node) - Non-Root Runtime
# -----------------------------------------------------------------------------
# Purpose:
#   - Run Ansible playbooks
#   - Manage SSH keys as non-root user
#   - Execute automation against Docker container nodes
#   - Support plugins, vault, facts caching, collections
#
# Notes:
#   - NO systemd
#   - CI/CD safe
#   - Runtime user: ansible (non-root)
# =============================================================================

FROM ubuntu:22.04

LABEL maintainer="ansible-lab"
LABEL role="ansible-master"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# -----------------------------------------------------------------------------
# Install OS packages (root only at build time)
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    openssh-client \
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
    sudo \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Install Ansible (pip-based)
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
# Create ansible user (NON-ROOT runtime user)
# -----------------------------------------------------------------------------
RUN useradd -m -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && \
    chmod 0440 /etc/sudoers.d/ansible

# -----------------------------------------------------------------------------
# Prepare SSH (ansible user)
# -----------------------------------------------------------------------------
RUN mkdir -p /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh && \
    echo "StrictHostKeyChecking no" > /home/ansible/.ssh/config && \
    echo "UserKnownHostsFile=/dev/null" >> /home/ansible/.ssh/config && \
    chown -R ansible:ansible /home/ansible/.ssh

# -----------------------------------------------------------------------------
# Workspace
# -----------------------------------------------------------------------------
WORKDIR /lab

# -----------------------------------------------------------------------------
# Copy entire lab
# -----------------------------------------------------------------------------
COPY . /lab

# -----------------------------------------------------------------------------
# Fix ownership & permissions
# -----------------------------------------------------------------------------
RUN chown -R ansible:ansible /lab && \
    chmod +x /lab/scripts/bootstrap_ssh.sh || true && \
    chmod +x /lab/scripts/generate_vault_password.py || true

# -----------------------------------------------------------------------------
# Ansible defaults (facts cache)
# -----------------------------------------------------------------------------
RUN mkdir -p /lab/.facts && \
    chown -R ansible:ansible /lab/.facts && \
    chmod 755 /lab/.facts

# -----------------------------------------------------------------------------
# Build-time sanity checks
# -----------------------------------------------------------------------------
RUN ansible --version && \
    ansible-lint --version && \
    python3 --version && \
    ssh -V

# -----------------------------------------------------------------------------
# Switch to NON-ROOT user (FINAL)
# -----------------------------------------------------------------------------
USER ansible

# -----------------------------------------------------------------------------
# Default shell
# -----------------------------------------------------------------------------
CMD ["/bin/bash"]
