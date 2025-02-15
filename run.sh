#!/bin/bash
set -eoux pipefail
podman run --pull always --cap-add=SYS_RAWIO --cap-add=CAP_MKNOD --device /dev/bus/usb -it ghcr.io/osirisrtos/hardware-ci
