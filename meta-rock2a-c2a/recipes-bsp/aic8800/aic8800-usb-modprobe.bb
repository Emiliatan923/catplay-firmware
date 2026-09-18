SUMMARY = "Load the AIC8800 USB WiFi/BT modules at boot"
DESCRIPTION = "The aic8800 USB combo needs aic_load_fw (firmware loader) and \
aic8800_fdrv (cfg80211 driver) before wlan0 appears, and aic_btusb before hci0 \
appears. Nothing auto-loads them, so the AP service would race the interface."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://catplay-aic8800.conf"
S = "${WORKDIR}"

# The modules themselves come from the vendor kernel, so depend on the
# individual kernel-module packages rather than a driver recipe.
RDEPENDS:${PN} = " \
    kernel-module-aic-load-fw \
    kernel-module-aic8800-fdrv \
    kernel-module-aic-btusb \
"

do_install() {
    install -d ${D}${sysconfdir}/modules-load.d
    install -m 0644 ${S}/catplay-aic8800.conf ${D}${sysconfdir}/modules-load.d/
}

FILES:${PN} += "${sysconfdir}/modules-load.d/catplay-aic8800.conf"
