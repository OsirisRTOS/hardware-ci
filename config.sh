#!/bin/bash
set -eoux pipefail

CONTAINER_NAME="osiris-hardware-ci"
RUNNER_DIR="$(pwd)/runner"
IMAGE="ghcr.io/osirisrtos/hardware-ci:latest"

mkdir -p "${RUNNER_DIR}"
touch "${RUNNER_DIR}/.env" "${RUNNER_DIR}/.path"
chmod 644 "${RUNNER_DIR}/.env" "${RUNNER_DIR}/.path"

podman pull "${IMAGE}" || true

# If a running container with the same name exists, stop it.
if podman ps -q -f name="^${CONTAINER_NAME}$" | grep -q .; then
  echo "Stopping running container ${CONTAINER_NAME}..."
  podman stop "${CONTAINER_NAME}" || true
fi

# If there's any container with the same name, remove it.
if podman ps -aq -f name="^${CONTAINER_NAME}$" | grep -q .; then
  echo "Removing existing container ${CONTAINER_NAME}..."
  podman rm "${CONTAINER_NAME}" || true
fi

podman run --name "${CONTAINER_NAME}" -d \
    --pull always \
    --env-file "${RUNNER_DIR}/.env" \
    -v "$(pwd)/chips.yml:/home/runner/actions-runner/chips.yml:ro" \
    -v "${RUNNER_DIR}/.path:/home/runner/actions-runner/.path:Z" \
    --device /dev/bus/usb --restart unless-stopped \
    "${IMAGE}" \
    "$@"
