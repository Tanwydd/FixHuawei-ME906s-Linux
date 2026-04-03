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
- ModemManager logs show: `could not grab port cdc-wdm1: unhandled port type`

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

### `huawei-me906s-setup.sh`

Full initial setup of the modem. Run **once** after installing Debian or reinstalling the system.

**What it does:**

1. Installs `modemmanager`, `libmbim-utils`, `usb-modeswitch` and `network-manager-gnome`
2. Creates `/etc/modprobe.d/huawei-me906s.conf` — assigns `cdc_mbim` and blacklists conflicting drivers
3. Updates `initramfs` so changes persist from boot
4. Creates `/etc/udev/rules.d/99-huawei-me906s.rules` — forces MBIM mode in ModemManager via `ID_MM_HUAWEI_USE_MBIM`
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

# Verbose mode
sudo ./huawei-me906s-setup.sh -v -p 1234

# Skip reboot prompt (useful for automation)
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

Wakes up the modem when ModemManager fails to detect it after boot or the modem becomes unresponsive. This is the script to run when `mmcli -L` returns `No modems were found` despite the modem being visible in `lsusb`.

**What it does:**

1. Checks the modem is visible at hardware level via `lsusb`
2. Reloads udev rules and triggers USB subsystem (fixes the `unhandled port type` issue)
3. Restarts ModemManager and waits up to 60s for modem detection
4. Restarts NetworkManager
5. Verifies the final connection state

**Usage:**

```bash
sudo chmod +x reiniciar_modem.sh

# Basic usage
sudo ./reiniciar_modem.sh

# Verbose mode (shows waiting progress)
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
         └─ udev applies ID_MM_HUAWEI_USE_MBIM rule
              └─ ModemManager detects modem (~20s)
                   └─ NetworkManager reads profile (autoconnect: yes)
                        └─ Sends PIN → registers on network → connected (~30-40s)
```

No manual intervention required. The connection will be available approximately 30-40 seconds after boot.

If the modem is not detected after ~60s, run `sudo ./reiniciar_modem.sh`.

---

## Key configuration files

### `/etc/modprobe.d/huawei-me906s.conf`

```
# Huawei ME906s (12d1:15c1) — driver cdc_mbim

options usb-storage quirks=12d1:15c1:i
blacklist cdc_ether
```

### `/etc/udev/rules.d/99-huawei-me906s.rules`

```
# Huawei ME906s (12d1:15c1) — force MBIM mode in ModemManager

ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_DEVICE_PROCESS}="1"
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_TTY_BLACKLIST}="1"
SUBSYSTEM=="usb", ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_HUAWEI_USE_MBIM}="1"
```

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

**Most common issue:** ModemManager logs show `could not grab port cdc-wdm1: unhandled port type`. Fix: verify that `/etc/udev/rules.d/99-huawei-me906s.rules` contains the `ID_MM_HUAWEI_USE_MBIM` line, then run `sudo ./reiniciar_modem.sh`.

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
