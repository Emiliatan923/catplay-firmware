SUMMARY = "Keep the CatPlay Bluetooth adapter discoverable and pairable"
DESCRIPTION = "The iPhone discovers the dongle by scanning for it, so the \
BlueZ adapter must stay discoverable. If it is not, the device never appears \
under Settings -> General -> CarPlay and wireless CarPlay cannot start at all. \
A regression that cleared these flags cost most of the wireless bring-up on \
this board, so they are asserted at boot rather than left to the daemon."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SRC_URI = " \
    file://catplay-bt-discoverable.sh \
    file://catplay-bt-discoverable.service \
"

S = "${WORKDIR}"

RDEPENDS:${PN} = "bluez5"

SYSTEMD_SERVICE:${PN} = "catplay-bt-discoverable.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -d ${D}${libexecdir}/catplay
    install -m 0755 ${S}/catplay-bt-discoverable.sh ${D}${libexecdir}/catplay/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/catplay-bt-discoverable.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${libexecdir}/catplay"
