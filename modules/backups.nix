{ config, pkgs, ... }:

{
  # Rustic backup configuration for Luna
  # Uses Backblaze B2 with credentials stored in /etc/restic/

  systemd.services.rustic-backup = {
    description = "Rustic backup to Backblaze B2";

    # Don't stop/restart this service during nixos-rebuild if it's running
    restartIfChanged = false;
    stopIfChanged = false;

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      # Load B2 credentials and restic password from /etc/restic/
      EnvironmentFile = [
        "/etc/restic/b2-env"
      ];

      # Repository configuration
      # Note: rustic uses opendal:b2 syntax, not b2: like restic
      # Uses hostname for OPENDAL_ROOT so each machine has its own backup folder
      Environment = [
        "RUSTIC_REPOSITORY=opendal:b2"
        "RUSTIC_PASSWORD_FILE=/etc/restic/password"
        # OpenDAL B2 configuration (will be set via OPENDAL_ env vars from b2-env file)
        "OPENDAL_BUCKET=milky-way-backup"
        "OPENDAL_ROOT=${config.networking.hostName}/"
        "OPENDAL_BUCKET_ID=c369a3ee90f0ab6897cb0d1f"
      ];

      # Backup command with common exclusions
      ExecStart = pkgs.writeShellScript "rustic-backup" ''
        set -e

        # Colors for output
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        RED='\033[0;31m'
        NC='\033[0m' # No Color

        # Check battery level - only run if on AC or battery > 35%
        if [ -f /sys/class/power_supply/BAT1/status ]; then
          STATUS=$(cat /sys/class/power_supply/BAT1/status)
          CAPACITY=$(cat /sys/class/power_supply/BAT1/capacity)

          if [ "$STATUS" = "Discharging" ] && [ "$CAPACITY" -lt 35 ]; then
            echo -e "''${RED}[Rustic Backup]''${NC} Skipping backup: Battery at $CAPACITY% (need >35% or AC power)"
            exit 0
          fi

          echo -e "''${GREEN}[Rustic Backup]''${NC} Battery check passed: $STATUS at $CAPACITY%"
        fi

        # Convert B2 environment variables to OpenDAL format
        export OPENDAL_APPLICATION_KEY_ID="$B2_ACCOUNT_ID"
        export OPENDAL_APPLICATION_KEY="$B2_ACCOUNT_KEY"

        # Get bucket_id (required by OpenDAL B2 backend)
        # Cache it to /var/cache/rustic-bucket-id to avoid API calls every time
        if [ ! -f /var/cache/rustic-bucket-id ]; then
          echo -e "''${BLUE}[Rustic Backup]''${NC} Fetching bucket ID for milky-way-backup..."
          mkdir -p /var/cache

          # Get auth token and API URL
          AUTH_RESPONSE=$(${pkgs.curl}/bin/curl -s -u "$B2_ACCOUNT_ID:$B2_ACCOUNT_KEY" \
            "https://api.backblazeb2.com/b2api/v2/b2_authorize_account")
          AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | ${pkgs.jq}/bin/jq -r '.authorizationToken')
          API_URL=$(echo "$AUTH_RESPONSE" | ${pkgs.jq}/bin/jq -r '.apiUrl')

          # Get bucket ID
          BUCKET_ID=$(${pkgs.curl}/bin/curl -s -H "Authorization: $AUTH_TOKEN" \
            "$API_URL/b2api/v2/b2_list_buckets?accountId=$B2_ACCOUNT_ID" | \
            ${pkgs.jq}/bin/jq -r ".buckets[] | select(.bucketName==\"milky-way-backup\") | .bucketId")

          if [ -z "$BUCKET_ID" ]; then
            echo -e "''${RED}[Rustic Backup]''${NC} ERROR: Could not determine bucket ID for milky-way-backup"
            exit 1
          fi

          echo "$BUCKET_ID" > /var/cache/rustic-bucket-id
          chmod 600 /var/cache/rustic-bucket-id
          echo -e "''${GREEN}[Rustic Backup]''${NC} Found and cached bucket ID: $BUCKET_ID"
        fi

        export OPENDAL_BUCKET_ID=$(cat /var/cache/rustic-bucket-id)

        echo -e "''${BLUE}[Rustic Backup]''${NC} Starting backup at $(date)"

        # Check if repository exists, initialize if not
        if ! ${pkgs.rustic}/bin/rustic snapshots &>/dev/null; then
          echo -e "''${BLUE}[Rustic Backup]''${NC} Repository not found, initializing..."
          ${pkgs.rustic}/bin/rustic init
        fi

        # Perform backup
        echo -e "''${BLUE}[Rustic Backup]''${NC} Creating snapshot..."
        ${pkgs.rustic}/bin/rustic backup \
          --glob-file=/etc/rustic/excludes.txt \
          --tag systemd \
          --tag $(hostname) \
          /home/miguel \
          /etc/nixos \
          /root

        # Cleanup old snapshots
        echo -e "''${BLUE}[Rustic Backup]''${NC} Pruning old snapshots..."
        ${pkgs.rustic}/bin/rustic forget \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6 \
          --keep-yearly 2 \
          --prune

        # Check repository integrity
        echo -e "''${BLUE}[Rustic Backup]''${NC} Checking repository integrity..."
        ${pkgs.rustic}/bin/rustic check --read-data --read-data-subset=5%

        echo -e "''${GREEN}[Rustic Backup]''${NC} Backup completed successfully at $(date)"
      '';

      # Sandboxing
      PrivateTmp = true;
      NoNewPrivileges = true;

      # Timeout and restart settings (allow 24h for large backups)
      TimeoutStartSec = "24h";

      # On failure, send notification
      ExecStartPost = pkgs.writeShellScript "backup-notify" ''
        if [ $SERVICE_RESULT != "success" ]; then
          ${pkgs.libnotify}/bin/notify-send -u critical "Rustic Backup Failed" "Check systemctl status rustic-backup.service"
        fi
      '';
    };

    # Battery check is done in the script itself (allows running on battery >50%)

    # Start after network is online
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    # Stop backup before system suspends to avoid broken network connections
    before = [ "sleep.target" ];
    conflicts = [ "sleep.target" ];
  };

  # Timer for automatic backups
  systemd.timers.rustic-backup = {
    description = "Rustic backup timer";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      # Run daily at 3am
      OnCalendar = "*-*-* 03:00:00";

      # If laptop was off, run 15 minutes after boot
      Persistent = true;

      # Randomize start time by up to 5 minutes to avoid server load spikes
      RandomizedDelaySec = "5m";
    };
  };

  # Create exclusion patterns file (rustic uses ! prefix for exclusions)
  environment.etc."rustic/excludes.txt".text = ''
    # Cache directories
    !**/.cache
    !**/cache
    !**/.cargo/registry
    !**/.npm
    !**/.yarn
    !**/node_modules

    # Build artifacts
    !**/target
    !**/dist
    !**/build
    !**/.next

    # Temporary files
    !**/.tmp
    !**/tmp
    !**/*.tmp

    # Virtual environments
    !**/venv
    !**/.venv
    !**/virtualenv

    # Large media that's backed up elsewhere
    !**/Downloads
    !**/Videos
    !**/Music

    # System files
    !**/.Trash
    !**/.local/share/Trash

    # Git repositories (exclude .git directories but keep working files)
    !**/.git/objects
    !**/.git/index

    # Nix store (managed by NixOS)
    !/nix/store

    # Large VM images (back up separately if needed)
    !/var/lib/libvirt/images
  '';

  # Helper aliases for rustic commands
  # Note: These require sourcing B2 credentials first: source /etc/restic/b2-env
  environment.shellAliases = {
    rustic-backup = "sudo systemctl start rustic-backup.service";
    rustic-status = "systemctl status rustic-backup.service";
    rustic-logs = "journalctl -u rustic-backup.service -f";
    rustic-list = "sudo bash -c 'source /etc/restic/b2-env && export RUSTIC_REPOSITORY=opendal:b2 RUSTIC_PASSWORD_FILE=/etc/restic/password OPENDAL_BUCKET=milky-way-backup OPENDAL_ROOT=$(hostname)/ && rustic snapshots'";
    rustic-restore = "sudo bash -c 'source /etc/restic/b2-env && export RUSTIC_REPOSITORY=opendal:b2 RUSTIC_PASSWORD_FILE=/etc/restic/password OPENDAL_BUCKET=milky-way-backup OPENDAL_ROOT=$(hostname)/ && rustic restore latest --target /tmp/restore'";
  };
}
