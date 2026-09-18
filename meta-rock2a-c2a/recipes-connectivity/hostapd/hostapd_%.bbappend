SUMMARY = "Build hostapd with 802.11ax, which the CatPlay AP configuration needs"

# catplay-ap/files/hostapd.conf sets ieee80211ax=1 and he_oper_chwidth=0.
# hostapd only recognises those two items when it is built with
# CONFIG_IEEE80211AX (both live inside #ifdef CONFIG_IEEE80211AX in
# src/ap/ap_config.c), and meta-openembedded's defconfig stops at 11ac. Without
# this the AP will not start at all:
#
#   Line 23: unknown configuration item 'ieee80211ax'
#   Line 25: unknown configuration item 'he_oper_chwidth'
#   2 errors found in configuration file '/etc/catplay/hostapd.conf'
#
# FILESEXTRAPATHS:prepend puts this layer's files/ dir ahead of the recipe's
# own, so the file://defconfig below is the copy shipped here -- the whole
# upstream defconfig with CONFIG_IEEE80211AX=y added -- and the recipe's
# do_configure installs it over hostapd/.config unchanged.

# The shared AP files live beside this recipe directory, not underneath it.
# Keep this path explicit: ${THISDIR}/files would silently fall back to the
# stock meta-openembedded defconfig and produce a hostapd without AX support.
FILESEXTRAPATHS:prepend := "${THISDIR}/../catplay-ap/files:"

SRC_URI:append = " file://defconfig"
