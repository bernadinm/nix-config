#!/usr/bin/env bash
# Hetzner Server Auction Watcher
# Polls the auction API every 5 minutes, notifies via Gotify when a deal matches criteria.
# State file tracks seen servers so you only get notified once per listing.

set -euo pipefail

GOTIFY_URL="${GOTIFY_URL:-http://10.43.16.5:80}"
GOTIFY_TOKEN="${GOTIFY_TOKEN:-A8Ap3TmrZr94MTJ}"
STATE_FILE="${STATE_FILE:-/var/lib/hetzner-watcher/seen.json}"
AUCTION_URL="https://www.hetzner.com/_resources/app/data/app/live_data_sb_EUR.json"

# Filter criteria - targeting server-grade hardware for database workloads
MIN_RAM=128         # GB - need enough for TimescaleDB shared_buffers
MAX_PRICE=200       # EUR/mo
REQUIRE_ECC=true    # ECC required for database integrity
REQUIRE_NVME=true   # NVMe required for database IO
PREFERRED_DC=""     # e.g. "HEL1" or "" for any

mkdir -p "$(dirname "$STATE_FILE")"
[ -f "$STATE_FILE" ] || echo '{}' > "$STATE_FILE"

notify() {
  local title="$1" message="$2" priority="${3:-7}"
  curl -sf -X POST "${GOTIFY_URL}/message" \
    -H "Content-Type: application/json" \
    -H "X-Gotify-Key: ${GOTIFY_TOKEN}" \
    -d "$(jq -n --arg t "$title" --arg m "$message" --argjson p "$priority" \
      '{title: $t, message: $m, priority: $p}')" > /dev/null 2>&1 || true
}

check_auction() {
  local data
  data=$(curl -sf --max-time 30 "$AUCTION_URL" 2>/dev/null) || {
    echo "$(date): Failed to fetch auction data"
    return 1
  }

  local matches
  matches=$(echo "$data" | jq --argjson min_ram "$MIN_RAM" \
    --argjson max_price "$MAX_PRICE" \
    --arg pref_dc "$PREFERRED_DC" \
    --argjson req_ecc "$REQUIRE_ECC" \
    --argjson req_nvme "$REQUIRE_NVME" '
    [.server[] | select(
      .ram_size >= $min_ram and
      .price <= $max_price and
      (if $req_ecc then .is_ecc else true end) and
      (if $req_nvme then (.serverDiskData.nvme | length) > 0 else true end) and
      (if $pref_dc != "" then .datacenter | startswith($pref_dc) else true end)
    ) | {
      id: .key,
      cpu: .cpu,
      cores: .cpu_count,
      ram: .ram_size,
      ecc: .is_ecc,
      price: .price,
      datacenter: .datacenter,
      disks: (.hdd_arr | join(", ")),
      has_nvme: ((.serverDiskData.nvme | length) > 0),
      next_reduce: (.next_reduce_timestamp | todate)
    }]')

  local count
  count=$(echo "$matches" | jq 'length')

  if [ "$count" -eq 0 ]; then
    echo "$(date): No matches found"
    return 0
  fi

  echo "$(date): Found $count matching servers"

  # Check each match against seen state
  local seen
  seen=$(cat "$STATE_FILE")

  echo "$matches" | jq -c '.[]' | while read -r server; do
    local sid price cpu ram disks dc ecc next_reduce cores
    sid=$(echo "$server" | jq -r '.id')
    price=$(echo "$server" | jq -r '.price')
    cpu=$(echo "$server" | jq -r '.cpu')
    cores=$(echo "$server" | jq -r '.cores')
    ram=$(echo "$server" | jq -r '.ram')
    ecc=$(echo "$server" | jq -r '.ecc')
    disks=$(echo "$server" | jq -r '.disks')
    dc=$(echo "$server" | jq -r '.datacenter')
    next_reduce=$(echo "$server" | jq -r '.next_reduce')

    # Check if we already notified about this server at this price
    local seen_price
    seen_price=$(echo "$seen" | jq -r --arg id "$sid" '.[$id] // "0"')

    if [ "$seen_price" = "$price" ]; then
      continue
    fi

    # New server or price dropped - notify
    local title msg priority
    if [ "$seen_price" != "0" ]; then
      title="Price Drop: ${cpu} - now ${price}EUR/mo"
      priority=8
    else
      title="New Deal: ${cpu} - ${price}EUR/mo"
      priority=7
    fi

    msg="Server #${sid} in ${dc}
CPU: ${cpu}
RAM: ${ram}GB $([ "$ecc" = "true" ] && echo "ECC" || echo "non-ECC")
Storage: ${disks}
Price: ${price} EUR/mo
Next price drop: ${next_reduce}

https://www.hetzner.com/sb?search=${sid}"

    echo "$(date): Notifying - $title"
    notify "$title" "$msg" "$priority"

    # Update seen state
    seen=$(echo "$seen" | jq --arg id "$sid" --arg p "$price" '.[$id] = $p')
    echo "$seen" > "$STATE_FILE"
  done
}

echo "Hetzner Auction Watcher started"
echo "Criteria: RAM >= ${MIN_RAM}GB, Price <= ${MAX_PRICE}EUR, ECC=${REQUIRE_ECC}, NVMe=${REQUIRE_NVME}, DC: ${PREFERRED_DC:-any}"

while true; do
  check_auction || true
  sleep 300
done
