SUMMARY = "CatPlay wireless-CarPlay access point"
DESCRIPTION = "Brings up the 5 GHz AP the iPhone joins for wireless CarPlay, \
plus the DHCP/DNS that network needs. The CatPlay daemon does not create the \
AP itself -- it only binds AirPlay/Bonjour to the interface and hands the \
SSID/passphrase to the iPhone over iAP2 -- so the AP is a prerequisite."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SRC_URI = " \
    file://catplay-ap-prepare.sh \
    file://catplay-ap-prepare.service \
    file://catplay-hostapd.service \
    file://catplay-dnsmasq.service \
    file://hostapd.conf \
"

S = "${WORKDIR}"

RDEPENDS:${PN} = " \
    hostapd \
    dnsmasq \
    iw \
    iproute2 \
"

SYSTEMD_SERVICE:${PN} = "catplay-ap-prepare.service catplay-hostapd.service catplay-dnsmasq.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -d ${D}${libexecdir}/catplay
    install -m 0755 ${S}/catplay-ap-prepare.sh ${D}${libexecdir}/catplay/

    install -d ${D}${sysconfdir}/catplay
    install -m 0644 ${S}/hostapd.conf ${D}${sysconfdir}/catplay/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/catplay-ap-prepare.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/catplay-hostapd.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/catplay-dnsmasq.service ${D}${systemd_system_unitdir}/

    install -d ${D}${localstatedir}/lib/catplay
}

FILES:${PN} += " \
    ${libexecdir}/catplay \
    ${sysconfdir}/catplay \
    ${localstatedir}/lib/catplay \
"
