SUMMARY = "Per-boot persistent logs for ROCK 2A CatPlay diagnostics"
DESCRIPTION = "Archives kernel, CatPlay and Bluetooth journal streams in a separate directory for every boot."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://catplay-log-setup.sh \
    file://catplay-log-setup.service \
    file://catplay-log-dmesg.service \
    file://catplay-log-catplay.service \
    file://catplay-log-bluetooth.service \
    file://10-catplay-persistent-logs.conf \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = " \
    catplay-log-setup.service \
    catplay-log-dmesg.service \
    catplay-log-catplay.service \
    catplay-log-bluetooth.service \
"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = "systemd"

do_install() {
    install -d ${D}${libexecdir}
    install -m 0755 ${WORKDIR}/catplay-log-setup.sh ${D}${libexecdir}/catplay-log-setup

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/catplay-log-setup.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/catplay-log-dmesg.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/catplay-log-catplay.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/catplay-log-bluetooth.service ${D}${systemd_system_unitdir}/

    # Make Bluetooth wait until its per-boot destination and collector exist,
    # so even early adapter/firmware failures are retained.
    install -d ${D}${sysconfdir}/systemd/system/bluetooth.service.d
    install -m 0644 ${WORKDIR}/10-catplay-persistent-logs.conf \
        ${D}${sysconfdir}/systemd/system/bluetooth.service.d/

    # The directory is on the writable root filesystem, unlike /var/log,
    # which Poky redirects into /var/volatile (tmpfs).
    install -d -m 0755 ${D}${localstatedir}/lib/catplay/logs
}

FILES:${PN} += "${localstatedir}/lib/catplay/logs"

