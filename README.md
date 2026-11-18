# OPNsense Auto Power-On & Graceful Shutdown for ThinkPad X61 / X61s

Automated AC power-loss recovery and battery-backed graceful shutdown for an IBM/Lenovo ThinkPad X61s (Intel 82801HEM ICH8M-E chipset) running OPNsense.

## Overview

The stock ThinkPad X61/X61s BIOS lacks a "Power On with AC Attach" option. When repurposing this hardware as a headless OPNsense router, two mechanisms work together to provide full unattended power resilience:

1. **Unattended AC Power Recovery (`10-afterg3`):** An early-boot OPNsense syshook clears **Bit 0 (`AFTERG3_EN`)** of the Intel ICH8M-E `GEN_PMCON_3` register (`pci0:31:0`, offset `0xa4`). Despite the Embedded Controller sitting between the barrel jack and southbridge, clearing this bit causes the X61s to power on automatically whenever AC power returns—both with and without a main battery installed.
2. **Graceful Power-Loss Shutdown (`ac-power-guard`):** A `devd` ACPI rule monitors AC adapter disconnect events (`ACAD`). If AC power stays disconnected for 120 seconds—or if the battery drops to `<= 30%` during that window—it initiates a clean `shutdown -p now` to protect the filesystem before a degraded battery collapses.

## Repository Structure

```text
.
├── README.md
├── install.sh
└── usr/
    └── local/
        ├── etc/
        │   ├── devd/
        │   │   └── ac-power-guard.conf
        │   └── rc.syshook.d/
        │       └── early/
        │           └── 10-afterg3
        └── sbin/
            └── ac-power-guard.sh
```

## Installation

On your OPNsense machine (as `root`), fetch and extract the repository using FreeBSD's built-in `fetch` utility and run `install.sh`:

```sh
fetch -o - https://github.com/gbdrbob/opnsense-thinkpad-x61s-power/archive/refs/heads/main.tar.gz | tar -xz
cd <your-repo>-main
sh install.sh
```

*(Note: Custom files under `/usr/local/etc/rc.syshook.d/`, `/usr/local/etc/devd/`, and `/usr/local/sbin/` persist across OPNsense firmware upgrades, though they are not included in `config.xml` backups.)*

## Configuration

Adjustable parameters at the top of `/usr/local/sbin/ac-power-guard.sh`:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `DELAY` | `120` | Maximum seconds to wait after AC loss before shutting down. |
| `MIN_BAT` | `30` | Battery percentage threshold that triggers an immediate shutdown during `DELAY`. |
| `CHECK_INTERVAL` | `5` | Polling interval in seconds while counting down on battery power. |

## Verification & Troubleshooting

* **Verify `GEN_PMCON_3` bit state:**
  ```sh
  pciconf -r -b pci0:31:0 0xa4
  ```
  An even hex value (such as `38` instead of `39`) confirms Bit 0 (`AFTERG3_EN`) is cleared and auto power-on is active.

* **Check system logs:**
  In the OPNsense Web UI, navigate to **System → Log Files → General** and filter by `afterg3` or `ac-power-guard` (or run `clog /var/log/system/latest.log | grep -E 'afterg3|ac-power-guard'` via SSH).

* **Inspect battery health & AC status:**
  ```sh
  sysctl hw.acpi.acline hw.acpi.battery.life
  acpiconf -i 0
  ```

* **CMOS Coin-Cell Note:**
  `GEN_PMCON_3` resides in the ICH8M-E RTC well. If both AC power and the main battery are removed while the internal CR2032 CMOS battery is dead, offset `0xa4` will revert to `0x39` and require one manual boot to re-apply `10-afterg3`.
