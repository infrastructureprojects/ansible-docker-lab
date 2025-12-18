#!/bin/bash
set -e

###############################################################################
# 🔧 Configuration
###############################################################################
ANSIBLE_CONTAINER="ansible-master"
TARGET_NODES=("dev" "sit" "uat" "prod")

###############################################################################
# 🔁 Function: map container → SSH user
###############################################################################
get_ssh_user() {
  case "$1" in
    ansible-master) echo "ansible" ;;
    dev)            echo "devusr" ;;
    sit)            echo "situsr" ;;
    uat)            echo "uatusr" ;;
    prod)           echo "produsr" ;;
    *)
      echo "ERROR: Unknown container '$1'" >&2
      exit 1
      ;;
  esac
}

###############################################################################
# 🔐 Bootstrap SSH for Ansible Master
###############################################################################
ANSIBLE_USER=$(get_ssh_user "${ANSIBLE_CONTAINER}")
SSH_DIR="/home/${ANSIBLE_USER}/.ssh"
KEY_PATH="${SSH_DIR}/id_rsa"
PUB_KEY_PATH="${KEY_PATH}.pub"

echo "🔑 Bootstrapping SSH for ${ANSIBLE_CONTAINER} as user '${ANSIBLE_USER}'"

docker exec "${ANSIBLE_CONTAINER}" bash -c "
  mkdir -p ${SSH_DIR} &&
  chmod 700 ${SSH_DIR} &&
  if [ ! -f ${KEY_PATH} ]; then
    ssh-keygen -t rsa -b 4096 -f ${KEY_PATH} -N ''
  fi &&
  chown -R ${ANSIBLE_USER}:${ANSIBLE_USER} ${SSH_DIR}
"

###############################################################################
# 🔑 Copy public key to target nodes
###############################################################################
for NODE in "${TARGET_NODES[@]}"; do
  TARGET_USER=$(get_ssh_user "${NODE}")
  TARGET_SSH_DIR="/home/${TARGET_USER}/.ssh"

  echo "➡️  Configuring SSH access: ${ANSIBLE_CONTAINER} → ${NODE} (${TARGET_USER})"

  # Ensure .ssh exists on target node
  docker exec "${NODE}" bash -c "
    mkdir -p ${TARGET_SSH_DIR} &&
    chmod 700 ${TARGET_SSH_DIR} &&
    touch ${TARGET_SSH_DIR}/authorized_keys &&
    chmod 600 ${TARGET_SSH_DIR}/authorized_keys &&
    chown -R ${TARGET_USER}:${TARGET_USER} ${TARGET_SSH_DIR}
  "

  # Copy public key idempotently (no duplicates)
  PUB_KEY=$(docker exec "${ANSIBLE_CONTAINER}" cat "${PUB_KEY_PATH}")

  docker exec "${NODE}" bash -c "
    grep -qxF '${PUB_KEY}' ${TARGET_SSH_DIR}/authorized_keys || \
    echo '${PUB_KEY}' >> ${TARGET_SSH_DIR}/authorized_keys
  "
done

echo "✅ SSH bootstrap completed successfully"
