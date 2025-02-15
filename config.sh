#!/bin/bash
set -eoux pipefail

CONTAINER_NAME="osiris-hardware-ci"

# If there's any container with the same name, remove it.
if podman ps -aq -f name="^${CONTAINER_NAME}$" | grep -q .; then
  echo "Removing existing container ${CONTAINER_NAME}..."
  podman rm "${CONTAINER_NAME}" || true
fi

podman run --rm --name "${CONTAINER_NAME}" -d \
    -v "$(pwd)/chips.yml:/actions-runner/chips.yml:ro" \
    --device /dev/bus/usb \
    ghcr.io/osirisrtos/hardware-ci:latest \
    "$@"
