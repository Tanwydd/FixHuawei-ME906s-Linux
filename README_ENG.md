# Huawei ME906s LTE M.2 — Setup on Debian 12

Scripts to configure and manage the **Huawei ME906s** modem (USB ID `12d1:15c1`) on Debian 12 (Bookworm), fixing automatic detection issues by using the `cdc_mbim` driver and MBIM protocol.

---

## Background

The Huawei ME906s modem may not be detected correctly at boot because the Linux kernel competes between several drivers (`cdc_mbim`, `cdc_ether`, `usb-storage`) without knowing which one to use. Additionally, ModemManager needs to be explicitly told that this device should be managed in MBIM mode.

Typical symptoms:

- `mmcli -L` returns `No modems were found`
- The modem appears in `lsusb` but with no driver assigned (`Driver=`)
- NetworkManager shows the modem as unavailable
- The connection is not established automatically at boot

---

## Solution overview

| Component | Configuration |
|---|---|
| Kernel driver | `cdc_mbim` |
| Protocol | MBIM |
| Management | ModemManager + NetworkManager |
| modprobe file | `/etc/modprobe.d/huawei-me906s.conf` |
| udev rule | `/etc/udev/rules.d/99-huawei-me906s.rules` |

---

## Scripts

### `fix_huawei_modem.sh`

Full initial setup of the modem. Run **once** after installing Debian or reinstalling the system.

**What it does:**

1. Installs `modemmanager`, `libmbim-utils`, `usb-modeswitch` and `network-manager-gnome`
2. Creates `/etc/modprobe.d/huawei-me906s.conf` — assigns `cdc_mbim` and blacklists conflicting drivers
3. Updates `initramfs` so changes persist from boot
4. Creates `/etc/udev/rules.d/99-huawei-me906s.rules` — forces MBIM mode in ModemManager
5. Actively waits for ModemManager to detect the modem (up to 60s)
6. Configures the GSM profile in NetworkManager with `autoconnect: yes`
7. Saves the SIM PIN if provided (avoids the PIN dialog on every boot)

**Usage:**

```bash
sudo chmod +x huawei-me906s-setup.sh

# Basic usage
sudo ./huawei-me906s-setup.sh

# With SIM PIN (recommended — avoids PIN dialogs at boot)
sudo ./huawei-me906s-setup.sh -p 1234

# Verbose mode (shows output of all commands)
sudo ./huawei-me906s-setup.sh -v -p 1234

# Skip reboot prompt (useful for automation scripts)
sudo ./huawei-me906s-setup.sh -n -p 1234
```

**Options:**

| Option | Description |
|---|---|
| `-v` | Verbose mode — shows detailed output for each command |
| `-n` | Skip reboot prompt at the end |
| `-p PIN` | SIM PIN — stored encrypted in the NetworkManager profile |
| `-h` | Show help |

---

### `reiniciar_modem.sh`

Restarts the `ModemManager` and `NetworkManager` services. Useful when the modem loses its connection without needing to reboot the system.

**Usage:**

```bash
sudo chmod +x reiniciar_modem.sh

# Basic usage
sudo ./reiniciar_modem.sh

# Verbose mode
sudo ./reiniciar_modem.sh -v
```

**Options:**

| Option | Description |
|---|---|
| `-v` | Verbose mode |
| `-h` | Show help |

---

## Requirements

- Debian 12 (Bookworm) — also compatible with Ubuntu 22.04+
- ModemManager 1.20.4 or higher
- `sudo` privileges
- SIM card inserted in the M.2 module

---

## Boot behaviour after setup

Once `huawei-me906s-setup.sh` has been run and the system rebooted, the automatic sequence on every boot is:

```
Kernel starts
    └─ cdc_mbim loads → /dev/cdc-wdm1 available
         └─ ModemManager detects modem via udev (~20s)
              └─ NetworkManager reads profile (autoconnect: yes)
                   └─ Sends PIN → registers on network → connection established (~30-40s)
```

No manual intervention required. The connection will be available approximately 30-40 seconds after boot.

---

## Troubleshooting

If the modem does not connect, these commands help identify the issue:

```bash
# Is the hardware visible to the kernel?
lsusb | grep -i huawei

# Which driver is assigned?
lsusb -t

# Does ModemManager detect it?
mmcli -L

# Full modem status
mmcli -m 0

# Does the MBIM device respond?
mbimcli -d /dev/cdc-wdm1 --query-device-caps

# ModemManager logs
sudo journalctl -u ModemManager -n 50 --no-pager
```

---

## Tested hardware

| Field | Value |
|---|---|
| Module | Huawei ME906s (`ML1ME906SM`) |
| USB ID | `12d1:15c1` |
| Firmware | `11.617.00.00.11` |
| Networks | GSM / UMTS / LTE (HSPA+) |
| Tested carrier | Vodafone ES |
| System | Debian 12 Bookworm (kernel 6.x) |

---

## License

MIT
