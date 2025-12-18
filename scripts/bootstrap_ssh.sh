#!/usr/bin/env bash
# ============================================================================
# 🔐 Bootstrap Passwordless SSH for Ansible Lab (Docker Containers)
# ============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# Load environment variables safely
# ----------------------------------------------------------------------------
if [[ ! -f .env ]]; then
  echo "[ERROR] .env file not found. Aborting."
  exit 1
fi

source .env

# ----------------------------------------------------------------------------
# SSH key configuration (NON-ROOT ansible-master)
# ----------------------------------------------------------------------------
SSH_KEY_DIR="${HOME}/.ssh"
SSH_KEY="${SSH_KEY_DIR}/id_rsa"
SSH_PUB="${SSH_KEY}.pub"

# ----------------------------------------------------------------------------
# Environment-specific node:user:password mapping
# ----------------------------------------------------------------------------
NODES=(
  "dev-node:devuser:${DEV_NODE_PASSWORD}"
  "sit-node:situser:${SIT_NODE_PASSWORD}"
  "uat-node:uatuser:${UAT_NODE_PASSWORD}"
  "prod-node:produser:${PROD_NODE_PASSWORD}"
)

# ----------------------------------------------------------------------------
# Logging helpers
# ----------------------------------------------------------------------------
log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

# ----------------------------------------------------------------------------
# Ensure sshpass exists
# ----------------------------------------------------------------------------
if ! command -v sshpass >/dev/null 2>&1; then
  log "Installing sshpass..."
  sudo apt-get update -y >/dev/null
  sudo apt-get install -y sshpass >/dev/null
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
# Copy public key to each environment node & user
# ----------------------------------------------------------------------------
for ENTRY in "${NODES[@]}"; do
  IFS=":" read -r HOST USER PASS <<< "${ENTRY}"

  log "Bootstrapping SSH access to ${USER}@${HOST}..."

  sshpass -p "${PASS}" ssh \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "${USER}@${HOST}" bash <<EOF
set -e

SSH_DIR="/home/${USER}/.ssh"

mkdir -p "\${SSH_DIR}"
chmod 700 "\${SSH_DIR}"

touch "\${SSH_DIR}/authorized_keys"
chmod 600 "\${SSH_DIR}/authorized_keys"

grep -qxF '${PUBKEY_CONTENT}' "\${SSH_DIR}/authorized_keys" || \
  echo '${PUBKEY_CONTENT}' >> "\${SSH_DIR}/authorized_keys"

chown -R ${USER}:${USER} "\${SSH_DIR}"
EOF

  log "Passwordless SSH configured for ${USER}@${HOST}"
done

# ----------------------------------------------------------------------------
# Final validation (key-based only)
# ----------------------------------------------------------------------------
log "Validating passwordless SSH connectivity..."

for ENTRY in "${NODES[@]}"; do
  IFS=":" read -r HOST USER _ <<< "${ENTRY}"

  ssh -o BatchMode=yes \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      "${USER}@${HOST}" "echo SSH OK from \$(hostname) as \$(whoami)" \
    || err "SSH validation failed for ${USER}@${HOST}"
done

log "🎉 SSH bootstrap completed successfully for all environment nodes!"
