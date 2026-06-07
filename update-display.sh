#!/bin/bash
# updateHomelab-display.sh
# Run on debian to push hostname, IP and disk usage to the ESPHome display

ESPHOME_IP="homelab-display.local"  # change to your ESP's IP
THRESHOLD_RED=90            # percent used -> RED
THRESHOLD_YELLOW=75         # percent used -> YELLOW

# Check if ESPHome is reachable
if ! curl -sf --max-time 5 "http://${ESPHOME_IP}/" -o /dev/null; then
  echo "ESPHome display is not reachable at ${ESPHOME_IP}, exiting."
  exit 1
fi

# Gather hostname and IP
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')

# Helper: get available space and usage % for a mount point
# Returns "label:sizeG" or "label:sizeG:RED" etc.
disk_entry() {
  local mount="$1"
  local label="$2"

  if ! mountpoint -q "$mount" && [ "$mount" != "/" ] && [ ! -d "$mount" ]; then
    echo "${label}:N/A"
    return
  fi

  local avail_kb=$(df "$mount" 2>/dev/null | awk 'NR==2 {print $4}')
  local used_pct=$(df "$mount" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')

  if [ -z "$avail_kb" ]; then
    echo "${label}:N/A"
    return
  fi

  # Convert to human readable
  local avail_gb=$(awk "BEGIN {printf \"%.0f\", $avail_kb / 1024 / 1024}")

  local flag=""
  if [ "$used_pct" -ge "$THRESHOLD_RED" ] 2>/dev/null; then
    flag=":RED"
  elif [ "$used_pct" -ge "$THRESHOLD_YELLOW" ] 2>/dev/null; then
    flag=":YELLOW"
  fi

  echo "${label}:${avail_gb}G${flag}"
}

# Build disk entries
DISK1=$(disk_entry "/"            "/")
DISK2=$(disk_entry "/mount/usb1"  "/usb")
DISK3=$(disk_entry "/mount/usb2"  "/usb2")

# CPU temp — Package id 0 from coretemp
TEMP=$(sensors -u 2>/dev/null | grep -A4 "Package id 0" | grep "temp1_input" | awk '{printf "%.0f", $2}')
if [ -z "$TEMP" ]; then
  TEMP=$(awk "BEGIN {printf \"%.0f\", $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null) / 1000}")
fi

TEMP_FLAG=""
if [ "$TEMP" -ge 80 ] 2>/dev/null; then TEMP_FLAG=":RED"
elif [ "$TEMP" -ge 65 ] 2>/dev/null; then TEMP_FLAG=":YELLOW"
fi

# Push to ESPHome
BASE="http://${ESPHOME_IP}/text"

#Update for server 1
curl -X POST "${BASE}/server1_hostname/set?value=${HOSTNAME}" -H "Content-Length: 0"
curl -X POST "${BASE}/server1_ip/set?value=${IP}" -H "Content-Length: 0"
curl -X POST "${BASE}/server1_disk1/set?value=${DISK1}" -H "Content-Length: 0"
curl -X POST "${BASE}/server1_disk2/set?value=${DISK2}" -H "Content-Length: 0"
curl -X POST "${BASE}/server1_disk3/set?value=${DISK3}" -H "Content-Length: 0"
curl -X POST "${BASE}/server1_cpu_temp/set?value=${TEMP}C${TEMP_FLAG}" -H "Content-Length: 0"

#Update for server 2
#curl -X POST "${BASE}/server2_hostname/set?value=${HOSTNAME}" -H "Content-Length: 0"
#curl -X POST "${BASE}/server2_ip/set?value=${IP}" -H "Content-Length: 0"
#curl -X POST "${BASE}/server2_disk1/set?value=${DISK1}" -H "Content-Length: 0"
#curl -X POST "${BASE}/server2_disk2/set?value=${DISK2}" -H "Content-Length: 0"
#curl -X POST "${BASE}/server2_disk3/set?value=${DISK3}" -H "Content-Length: 0"
#curl -X POST "${BASE}/server2_cpu_temp/set?value=${TEMP}C${TEMP_FLAG}" -H "Content-Length: 0"

echo "Display updated: ${HOSTNAME} (${IP})"
echo "  ${DISK1}"
echo "  ${DISK2}"
echo "  ${DISK3}"
echo "  ${TEMP}C"
