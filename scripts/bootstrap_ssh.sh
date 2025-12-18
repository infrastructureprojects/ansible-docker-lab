#!/usr/bin/env bash
# ============================================================================
# 🔐 Bootstrap Passwordless SSH for Ansible Lab (Docker Containers)
# ----------------------------------------------------------------------------
# Purpose:
#   - Generate SSH keypair on ansible-master (if not present)
#   - Copy public key into dev / sit / uat / prod containers
#   - Enable passwordless SSH for Ansible automation
#
# Designed for:
#   - Docker-based target nodes
#   - No systemd
#   - CI/CD safe
# ============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
SSH_USER="${SSH_USER:-ansible}"
SSH_PASSWORD="${SSH_PASSWORD:-ansible}"   # initial bootstrap only
SSH_KEY_DIR="/root/.ssh"
SSH_KEY="${SSH_KEY_DIR}/id_rsa"
SSH_PUB="${SSH_KEY}.pub"

NODES=(
  "dev-node"
  "sit-node"
  "uat-node"
  "prod-node"
)

# ----------------------------------------------------------------------------
# Logging helpers
# ----------------------------------------------------------------------------
log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

# ----------------------------------------------------------------------------
# Ensure sshpass exists (required for first-time password auth)
# ----------------------------------------------------------------------------
if ! command -v sshpass >/dev/null 2>&1; then
  log "Installing sshpass..."
  apt-get update -y >/dev/null
  apt-get install -y sshpass >/dev/null
fi

# ----------------------------------------------------------------------------
# Create SSH keypair (idempotent)
# ----------------------------------------------------------------------------
log "Preparing SSH key directory..."
mkdir -p "${SSH_KEY_DIR}"
chmod 700 "${SSH_KEY_DIR}"

if [[ ! -f "${SSH_KEY}" ]]; then
  log "Generating SSH keypair..."
  ssh-keygen -t rsa -b 4096 -N "" -f "${SSH_KEY}" >/dev/null
else
  log "SSH keypair already exists – skipping generation"
fi

PUBKEY_CONTENT="$(cat "${SSH_PUB}")"

# ----------------------------------------------------------------------------
# Copy public key to all nodes
# ----------------------------------------------------------------------------
for NODE in "${NODES[@]}"; do
  log "Bootstrapping SSH access to ${NODE}..."

  sshpass -p "${SSH_PASSWORD}" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "${SSH_USER}@${NODE}" bash <<EOF
set -e

# Create .ssh directory
mkdir -p /home/${SSH_USER}/.ssh
chmod 700 /home/${SSH_USER}/.ssh

# Create authorized_keys
touch /home/${SSH_USER}/.ssh/authorized_keys
chmod 600 /home/${SSH_USER}/.ssh/authorized_keys

# Add public key if not present
grep -qxF '${PUBKEY_CONTENT}' /home/${SSH_USER}/.ssh/authorized_keys || \
  echo '${PUBKEY_CONTENT}' >> /home/${SSH_USER}/.ssh/authorized_keys

# Fix ownership
chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh
EOF

  log "Passwordless SSH configured for ${NODE}"
done

# ----------------------------------------------------------------------------
# Final validation
# ----------------------------------------------------------------------------
log "Validating passwordless SSH connectivity..."

for NODE in "${NODES[@]}"; do
  ssh -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      "${SSH_USER}@${NODE}" "echo SSH OK from \$(hostname)" \
      || err "SSH validation failed for ${NODE}"
done

log "🎉 SSH bootstrap completed successfully for all nodes!"
