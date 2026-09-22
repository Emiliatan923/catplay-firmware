#!/bin/sh
set -eu

log_root=/var/lib/catplay/logs
run_root=/run/catplay-logs
counter_file="$log_root/boot-counter"

mkdir -p "$log_root" "$run_root"

counter=0
if [ -r "$counter_file" ]; then
    IFS= read -r counter < "$counter_file" || counter=0
fi
case "$counter" in
    ''|*[!0-9]*) counter=0 ;;
esac
counter=$((counter + 1))

boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)
boot_name=$(printf 'boot-%06d-%s' "$counter" "$boot_id")
boot_dir="$log_root/$boot_name"
mkdir -m 0755 "$boot_dir"

counter_tmp="$counter_file.$$"
printf '%s\n' "$counter" > "$counter_tmp"
mv -f "$counter_tmp" "$counter_file"

ln -sfn "$boot_name" "$log_root/current"
ln -sfn "$boot_dir" "$run_root/current"

{
    printf 'boot_sequence=%s\n' "$counter"
    printf 'boot_id=%s\n' "$boot_id"
    printf 'collector_started_utc=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'kernel='; uname -r
    printf 'cmdline='; cat /proc/cmdline
} > "$boot_dir/boot-info.txt"

# Create predictable names before the collectors start. Opening them here also
# makes an incomplete boot visible even if journald or a collector later fails.
: > "$boot_dir/dmesg.log"
: > "$boot_dir/catplay.log"
: > "$boot_dir/bluetooth.log"

