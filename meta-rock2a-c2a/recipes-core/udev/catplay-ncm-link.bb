SUMMARY = "Pin the CatPlay NCM interface name against udev's MAC-based rename"
DESCRIPTION = "Keeps the CarPlay NCM data link named usb0. udev's MAC-based naming \
policy renames it to enu1i1 ~20 ms after it registers, but catplay_c2a reads the \
name from configfs and then keeps using it, so the later is_mdns_v6_stable() \
call fails with ENODEV and the daemon never leaves \
WaitingForStableMulticast. Same remedy as catplay-ap0-link, which pins ap0."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://10-catplay-ncm.link"
S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${S}/10-catplay-ncm.link ${D}${sysconfdir}/systemd/network/
}

FILES:${PN} += "${sysconfdir}/systemd/network/10-catplay-ncm.link"
