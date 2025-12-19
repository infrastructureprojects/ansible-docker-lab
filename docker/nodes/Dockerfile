# =============================================================================
# Ansible Managed Node (Docker Container)
# -----------------------------------------------------------------------------
# Purpose:
#   - Act as Ansible target node (dev / sit / uat / prod)
#   - Create environment-specific OS user at build time
#   - Provide SSH access
#   - Run services WITHOUT systemd
#
# Design:
#   - Ansible connects as root
#   - Environment user exists for app ownership & isolation
#   - No sudo / no become required
# =============================================================================

FROM ubuntu:22.04

LABEL role="ansible-managed-node"
LABEL maintainer="ansible-lab"

# -----------------------------------------------------------------------------
# Build-time arguments (injected from docker-compose.yml)
# -----------------------------------------------------------------------------
ARG NODE_USER
ARG NODE_PASSWORD

# -----------------------------------------------------------------------------
# Persist ARGs as ENV (important for runtime visibility & debugging)
# -----------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# --------------------------------------------------------------------
# Install base packages (APT-resilient)
# --------------------------------------------------------------------
RUN set -eux; \
    rm -rf /var/lib/apt/lists/*; \
    apt-get clean; \
    \
    apt-get update \
      -o Acquire::Retries=5 \
      -o Acquire::http::Timeout=30 \
      -o Acquire::https::Timeout=30; \
    \
    apt-get install -y --no-install-recommends \
      openssh-server \
      sudo \
      python3 \
      python3-apt \
      python3-distutils \
      ca-certificates \
      curl \
      vim \
      git \
      wget \
      iproute2 \
      procps \
      net-tools \
      iputils-ping \
      cron \
      tzdata \
      nano \
      less \
      passwd; \
    \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------
# SSH runtime directory
# --------------------------------------------------------------------
RUN mkdir -p /var/run/sshd

# --------------------------------------------------------------------
# Create environment-specific user
# --------------------------------------------------------------------
RUN set -eux; \
    test -n "${NODE_USER}"; \
    mkdir -p /etc/sudoers.d; \
    chmod 750 /etc/sudoers.d; \
    getent group "${NODE_USER}" || groupadd "${NODE_USER}"; \
    id -u "${NODE_USER}" >/dev/null 2>&1 || \
    useradd -m -s /bin/bash -g "${NODE_USER}" "${NODE_USER}"; \
    echo "${NODE_USER}:${NODE_PASSWORD}" | chpasswd; \
    echo "${NODE_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${NODE_USER}; \
    chmod 440 /etc/sudoers.d/${NODE_USER}

# --------------------------------------------------------------------
# SSH configuration
# --------------------------------------------------------------------
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# -----------------------------------------------------------------------------
# Prepare SSH directories for NODE_USER (recommended)
# -----------------------------------------------------------------------------
RUN mkdir -p /home/${NODE_USER}/.ssh && \
    chmod 700 /home/${NODE_USER}/.ssh && \
    touch /home/${NODE_USER}/.ssh/authorized_keys && \
    chmod 600 /home/${NODE_USER}/.ssh/authorized_keys && \
    chown -R ${NODE_USER}:${NODE_USER} /home/${NODE_USER}/.ssh

# -----------------------------------------------------------------------------
# Expose SSH
# -----------------------------------------------------------------------------
EXPOSE 22

# -----------------------------------------------------------------------------
# Container entrypoint
# -----------------------------------------------------------------------------
CMD ["/usr/sbin/sshd", "-D"]
