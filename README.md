# ttgo-homelab-display-esphome
ESPHome configuration for the TTGO T-Display (ESP32 + ST7789V 135×240px) showing server hostnames, IPs, disk usage and CPU temps — updated via HTTP POST from bash scripts running on each server.

## Hardware
- LILYGO TTGO T-Display ESP32

## Features
- Support for 2 server
- 3 display states, cycled with the onboard buttons
  - **State 0** — Server overview: hostname, IP, disk usage per mount point
  - **State 1** — Device info: ESPHome hostname, own IP, WiFi RSSI, uptime
  - **State 2** — CPU temperatures for both servers
- Disk entries support color alerts — `YELLOW` and `RED` when usage is high
- All server data is pushed via HTTP POST from bash scripts on each server
- Values persist across reboots and power outages (`restore_value: true`)
- Fully internal entities — nothing exposed to Home Assistant
- Button to cycle screens

## Setup
### ESPHome
See https://esphome.io/ for how to upload yaml to your esp32.

### Server - Install the bash scripts on each server
```bash
# On Debian
chmod +x update-display.sh

# Add to cron — runs every 30 minutes
crontab -e
# add: */30 * * * * /path/to/update-display.sh
```

Change the values in the bash script for your needs :)
