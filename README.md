### USB Access
Create an udev rule at `/etc/udev/rules.d/99-usb.rules`:

```
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374b", MODE="0666"
```

The run this to reload:

```sh
sudo udevadm control --reload-rules && sudo udevadm trigger
```
