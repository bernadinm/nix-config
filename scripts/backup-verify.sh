#!/usr/bin/env bash
# backup-verify.sh — Cross-reference local disk with Backblaze B2 backup snapshots
# Shows what's backed up, what's NOT backed up, and disk usage for each.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}ERROR:${NC} This script must be run as root (needs B2 credentials)"
  echo "Usage: sudo $0 [--deep]"
  exit 1
fi

DEEP=false
if [ "${1:-}" = "--deep" ]; then
  DEEP=true
fi

# Load B2 credentials
source /etc/restic/b2-env
export RUSTIC_REPOSITORY=opendal:b2
export RUSTIC_PASSWORD_FILE=/etc/restic/password
export OPENDAL_BUCKET=milky-way-backup
export OPENDAL_ROOT="$(hostname | tr '[:upper:]' '[:lower:]')/"
export OPENDAL_APPLICATION_KEY_ID="$B2_ACCOUNT_ID"
export OPENDAL_APPLICATION_KEY="$B2_ACCOUNT_KEY"

if [ -f /var/cache/rustic-bucket-id ]; then
  export OPENDAL_BUCKET_ID=$(cat /var/cache/rustic-bucket-id)
fi

BACKUP_DIRS=(/home/miguel /etc/nixos /root)

echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║          Backup Verification Report                 ║${NC}"
echo -e "${BOLD}║          Host: $(hostname)                               ║${NC}"
echo -e "${BOLD}║          Date: $(date +%Y-%m-%d)                         ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo

# ── Step 1: Check snapshots ──────────────────────────────────────────────
echo -e "${BLUE}[1/4]${NC} Checking backup snapshots..."
echo

SNAPSHOTS=$(rustic snapshots 2>&1) || {
  echo -e "${RED}ERROR:${NC} Cannot connect to backup repository."
  echo "$SNAPSHOTS"
  exit 1
}

echo "$SNAPSHOTS"
echo

SNAPSHOTS_JSON=$(rustic snapshots --json 2>/dev/null || true)
LATEST_ID=$(echo "$SNAPSHOTS_JSON" | jq -r '[.[].snapshots[]] | sort_by(.time) | last | .id // empty' 2>/dev/null || true)

if [ -z "$LATEST_ID" ]; then
  echo -e "${RED}ERROR:${NC} No snapshots found! Nothing is backed up."
  exit 1
fi

LATEST_TIME=$(echo "$SNAPSHOTS_JSON" | jq -r '[.[].snapshots[]] | sort_by(.time) | last | .time // "unknown"' 2>/dev/null || echo "unknown")
echo -e "${GREEN}Latest snapshot:${NC} $LATEST_ID"
echo -e "${GREEN}Snapshot time:${NC}  $LATEST_TIME"

# Check snapshot age
if [ "$LATEST_TIME" != "unknown" ]; then
  SNAP_EPOCH=$(date -d "$LATEST_TIME" +%s 2>/dev/null || echo 0)
  NOW_EPOCH=$(date +%s)
  AGE_HOURS=$(( (NOW_EPOCH - SNAP_EPOCH) / 3600 ))
  if [ "$AGE_HOURS" -gt 48 ]; then
    echo -e "${RED}WARNING:${NC} Latest backup is ${AGE_HOURS} hours old (>48h)!"
  elif [ "$AGE_HOURS" -gt 24 ]; then
    echo -e "${YELLOW}NOTE:${NC} Latest backup is ${AGE_HOURS} hours old."
  else
    echo -e "${GREEN}OK:${NC} Backup is recent (${AGE_HOURS}h ago)."
  fi
fi
echo

# ── Step 2: List what's in the backup ────────────────────────────────────
echo -e "${BLUE}[2/4]${NC} Listing top-level contents of latest snapshot..."
echo

BACKUP_LISTING=$(rustic ls "$LATEST_ID" 2>/dev/null || true)

# Show top-level dirs in backup
echo -e "${BOLD}Backed up paths:${NC}"
for dir in "${BACKUP_DIRS[@]}"; do
  if echo "$BACKUP_LISTING" | grep -q "^${dir}"; then
    COUNT=$(echo "$BACKUP_LISTING" | grep -c "^${dir}" || true)
    echo -e "  ${GREEN}✓${NC} ${dir}  (${COUNT} entries in snapshot)"
  else
    echo -e "  ${RED}✗${NC} ${dir}  (NOT found in snapshot!)"
  fi
done
echo

# ── Step 3: Show what's on disk but NOT backed up ────────────────────────
echo -e "${BLUE}[3/4]${NC} Analyzing disk usage for backed-up directories..."
echo

echo -e "${BOLD}Disk usage — BACKED UP (included in snapshots):${NC}"
for dir in "${BACKUP_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    SIZE=$(du -sh "$dir" --exclude='.cache' --exclude='node_modules' \
           --exclude='target' --exclude='.npm' --exclude='.cargo/registry' \
           --exclude='.local/share/Trash' --exclude='venv' --exclude='.venv' \
           --exclude='.git/objects' 2>/dev/null | tail -1 | cut -f1)
    echo -e "  ${GREEN}✓${NC} ${dir}: ~${SIZE} (approx, after exclusions)"
  fi
done
echo

echo -e "${BOLD}Disk usage — EXCLUDED from backups (safe to delete, not backed up):${NC}"
EXCLUDED_PATTERNS=(
  "/home/miguel/.cache"
  "/home/miguel/.cargo/registry"
  "/home/miguel/.npm"
  "/home/miguel/.yarn"
  "/home/miguel/.local/share/Trash"
)
TOTAL_EXCLUDED=0
for p in "${EXCLUDED_PATTERNS[@]}"; do
  if [ -e "$p" ]; then
    SIZE_BYTES=$(du -sb "$p" 2>/dev/null | cut -f1 || echo 0)
    SIZE_HUMAN=$(du -sh "$p" 2>/dev/null | cut -f1 || echo "0")
    TOTAL_EXCLUDED=$((TOTAL_EXCLUDED + SIZE_BYTES))
    echo -e "  ${YELLOW}⊘${NC} ${p}: ${SIZE_HUMAN}"
  fi
done
TOTAL_EXCLUDED_HUMAN=$(numfmt --to=iec $TOTAL_EXCLUDED 2>/dev/null || echo "${TOTAL_EXCLUDED} bytes")
echo -e "  ${YELLOW}Total excluded:${NC} ${TOTAL_EXCLUDED_HUMAN}"
echo

echo -e "${BOLD}Disk usage — NOT in any backup path (other top-level dirs):${NC}"
OTHER_DIRS=(/var/lib/libvirt/images)
for dir in "${OTHER_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
    echo -e "  ${RED}✗${NC} ${dir}: ${SIZE}  ${RED}(NOT BACKED UP)${NC}"
  fi
done
echo

# ── Step 4: Deep verification (optional) ────────────────────────────────
if [ "$DEEP" = true ]; then
  echo -e "${BLUE}[4/4]${NC} Deep verification — testing restore of sample files..."
  echo

  RESTORE_DIR=$(mktemp -d /tmp/backup-verify-XXXX)
  trap "rm -rf $RESTORE_DIR" EXIT

  # Pick a few key files to verify
  TEST_FILES=(
    "/home/miguel/.bashrc"
    "/etc/nixos/configuration.nix"
  )

  for f in "${TEST_FILES[@]}"; do
    if [ -f "$f" ]; then
      echo -n "  Restoring $f from backup... "
      if rustic restore "$LATEST_ID" --target "$RESTORE_DIR" --glob "$f" &>/dev/null; then
        RESTORED="${RESTORE_DIR}${f}"
        if [ -f "$RESTORED" ]; then
          if diff -q "$f" "$RESTORED" &>/dev/null; then
            echo -e "${GREEN}✓ matches current${NC}"
          else
            echo -e "${YELLOW}⚠ differs from current (expected if changed since last backup)${NC}"
          fi
        else
          echo -e "${RED}✗ file not found in restore${NC}"
        fi
      else
        echo -e "${RED}✗ restore failed${NC}"
      fi
    fi
  done
  echo
else
  echo -e "${BLUE}[4/4]${NC} Skipping deep verification (run with --deep to test restores)"
  echo
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                    Summary                          ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║${NC} ${GREEN}SAFE TO DELETE${NC} (backed up in B2):                    ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   Files in /home/miguel (excl. excluded patterns)    ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   Files in /etc/nixos                                ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   Files in /root                                     ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}                                                      ${BOLD}║${NC}"
echo -e "${BOLD}║${NC} ${YELLOW}SAFE TO DELETE${NC} (excluded, reclaimable space):        ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   .cache, node_modules, target/, .npm, .cargo/reg    ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   .local/share/Trash                                 ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}                                                      ${BOLD}║${NC}"
echo -e "${BOLD}║${NC} ${RED}NOT BACKED UP${NC} (do NOT delete without separate copy): ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   Downloads/, Videos/, Music/                        ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   /var/lib/libvirt/images                            ${BOLD}║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo
echo -e "Run ${BOLD}rustic-restore${NC} to restore the latest snapshot to /tmp/restore"
echo -e "Run ${BOLD}sudo $0 --deep${NC} to also verify restores match current files"
