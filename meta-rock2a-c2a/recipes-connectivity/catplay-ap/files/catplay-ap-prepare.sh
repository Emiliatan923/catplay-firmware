#!/bin/sh
# Create and address the wireless-CarPlay access point interface.
#
# Runs before hostapd/dnsmasq. The ROCK 2A has ONE radio and reaches the
# network over it, so the AP gets a second, concurrent interface (the aic8800
# PHY advertises `#{ managed, mesh point } <= 1, #{ AP } <= 1`). Putting the AP
# on the base interface would drop the station link and the admin path with it.
set -eu

IFACE="${CATPLAY_AP_IFACE:-ap0}"
BASE_IFACE="${CATPLAY_AP_BASE_IFACE:-wlan0}"
GATEWAY="${CATPLAY_AP_GATEWAY:-192.168.66.1}"
PREFIX="${CATPLAY_AP_PREFIX:-24}"

log() { echo "catplay-ap-prepare: $*"; }

# The combo radio is USB and probes asynchronously; wait for the base
# interface rather than failing the boot.
i=0
while [ ! -e "/sys/class/net/$BASE_IFACE" ] && [ "$i" -lt 30 ]; do
    sleep 1
    i=$((i + 1))
done

if [ ! -e "/sys/class/net/$BASE_IFACE" ]; then
    log "base interface $BASE_IFACE never appeared"
    exit 1
fi

if [ ! -e "/sys/class/net/$IFACE" ]; then
    log "creating $IFACE (AP) on $BASE_IFACE"
    iw dev "$BASE_IFACE" interface add "$IFACE" type __ap
    sleep 1
fi

ip link set "$IFACE" up
ip addr replace "$GATEWAY/$PREFIX" dev "$IFACE"

log "$IFACE up as $GATEWAY/$PREFIX"
