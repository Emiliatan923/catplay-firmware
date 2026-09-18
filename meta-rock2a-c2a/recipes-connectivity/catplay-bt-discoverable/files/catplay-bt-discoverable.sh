#!/bin/sh
# Put the Bluetooth adapter into discoverable + pairable mode and keep it there.
#
# The iPhone finds the dongle by SCANNING for it. If the adapter is not
# discoverable, the device never shows up under Settings -> General -> CarPlay
# and wireless CarPlay cannot start. The CatPlay daemon sets these itself, but
# they are also asserted here so a daemon restart, a BlueZ restart, or a
# DiscoverableTimeout expiry cannot silently close the pairing window.
set -eu

HCI="${CATPLAY_BT_HCI:-hci0}"
ADAPTER="/org/bluez/$HCI"

log() { echo "catplay-bt: $*"; }

# The USB combo enumerates asynchronously; wait for the adapter.
i=0
while [ ! -e "/sys/class/bluetooth/$HCI" ] && [ "$i" -lt 30 ]; do
    sleep 1
    i=$((i + 1))
done

if [ ! -e "/sys/class/bluetooth/$HCI" ]; then
    log "adapter $HCI never appeared"
    exit 1
fi

# bluetoothd owns the adapter properties; wait until the adapter object is on
# D-Bus. Do not use `bluetoothctl --timeout N` for one-shot commands here:
# bluetoothctl deliberately stays alive for the whole timeout even after the
# command succeeds, so four 20-second calls held catplay-c2a back for ~80 s.
i=0
while ! busctl get-property org.bluez "$ADAPTER" org.bluez.Adapter1 Address >/dev/null 2>&1 \
    && [ "$i" -lt 30 ]; do
    sleep 1
    i=$((i + 1))
done

set_adapter_property() {
    property="$1"
    signature="$2"
    value="$3"
    if ! busctl set-property org.bluez "$ADAPTER" org.bluez.Adapter1 \
        "$property" "$signature" "$value"; then
        log "WARNING: failed to set $property=$value"
    fi
}

set_adapter_property Powered b true

# DiscoverableTimeout=0 means "never time out", so the window stays open.
set_adapter_property DiscoverableTimeout u 0
set_adapter_property Discoverable b true
set_adapter_property Pairable b true

if [ "$(busctl get-property org.bluez "$ADAPTER" org.bluez.Adapter1 Discoverable 2>/dev/null || true)" = "b true" ] \
    && [ "$(busctl get-property org.bluez "$ADAPTER" org.bluez.Adapter1 Pairable 2>/dev/null || true)" = "b true" ]; then
    log "$HCI is discoverable and pairable"
else
    log "WARNING: $HCI did not report discoverable+pairable"
    busctl get-property org.bluez "$ADAPTER" org.bluez.Adapter1 Discoverable 2>/dev/null || true
    busctl get-property org.bluez "$ADAPTER" org.bluez.Adapter1 Pairable 2>/dev/null || true
fi
