# Power mode tile (optional)

The control centre's **Power mode** tile switches the ACPI platform profile
(`/sys/firmware/acpi/platform_profile`). Writing it needs root, so Opal calls
this tiny helper through `sudo -n` with a rule that allows only these three
exact commands. Without it the tile simply does nothing.

```sh
sudo install -m 755 -o root -g root set-platform-profile /usr/local/sbin/set-platform-profile
echo "$USER ALL=(root) NOPASSWD: /usr/local/sbin/set-platform-profile performance, /usr/local/sbin/set-platform-profile balanced, /usr/local/sbin/set-platform-profile low-power" \
  | sudo tee /etc/sudoers.d/opal-power-profile >/dev/null
sudo chmod 440 /etc/sudoers.d/opal-power-profile
sudo visudo -c
```

Check what your machine supports with `cat /sys/firmware/acpi/platform_profile_choices`.
If you use power-profiles-daemon or tuned instead, you don't need this.
