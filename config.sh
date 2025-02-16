#!/bin/bash
set -eoux pipefail

CONTAINER_NAME="osiris-hardware-ci"

# If a running container with the same name exists, stop it.
if docker ps -q -f name="^${CONTAINER_NAME}$" | grep -q .; then
  echo "Stopping running container ${CONTAINER_NAME}..."
  docker stop "${CONTAINER_NAME}" || true
fi

# If there's any container with the same name, remove it.
if docker ps -aq -f name="^${CONTAINER_NAME}$" | grep -q .; then
  echo "Removing existing container ${CONTAINER_NAME}..."
  docker rm "${CONTAINER_NAME}" || true
fi

docker run --pull always --name "${CONTAINER_NAME}" -d \
    -v "$(pwd)/chips.yml:/actions-runner/chips.yml:ro" \
    --device /dev/bus/usb --restart unless-stopped \
    ghcr.io/osirisrtos/hardware-ci:latest \
    "$@"
