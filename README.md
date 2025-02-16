# hardware-ci
This repo contains scripts that interact with the [GitHub Actions Runner](https://github.com/actions/runner) to run hardware tests.

## Setup
To set it up, connect a couple of STM32 devices to the runner machine and make sure they are visible when running the following command:

```sh
docker run --rm --entrypoint st-info --device /dev/bus/usb ghcr.io/osirisrtos/hardware-ci:latest --probe
```

Very likely, this will fail. The following steps will help you to make it work.

### USB Access
We need to make sure the devices are accessible from the runner that is inside a container.

To do that, create an udev rule at `/etc/udev/rules.d/99-usb.rules`. This is for STM32 devices, you may need to change the `idVendor` and `idProduct` values for other devices.

```
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374b", MODE="0666"
```

Then reload the rules:

```sh
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Verify that the devices are accessible now:

```sh
docker run --rm --entrypoint st-info --device /dev/bus/usb ghcr.io/osirisrtos/hardware-ci:latest --probe
```
