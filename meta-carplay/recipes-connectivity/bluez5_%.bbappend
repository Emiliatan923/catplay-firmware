FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PACKAGECONFIG = "tools readline"
PACKAGES:remove = "${PN}-testtools ${PN}-obex"
#SRC_URI:append = " file://0001-src-log-h-disable-logging-macros.patch"
#SRC_URI:append = " file://0002-bluez5-stop-using-debug-section-in-bluetoothd.patch"
#SRC_URI:append = " file://0003-no-op-shared-log-macros.patch"
#SRC_URI:append = " file://0004-no-op-shared-att-verbose.patch"
SRC_URI:append = " file://0005-storage-use-atomic-no-op-writes.patch"
SRC_URI:append = " file://bluetoothd-logged"

#DEPENDS:remove = "glib-2.0"

do_install:append() {
    rm -rf ${D}${libdir}/bluez/test
    rmdir --ignore-fail-on-non-empty ${D}${libdir}/bluez || true

    # BlueZ >= 5.86 creates its state directory from the install-data-hook
    # target: "bluetoothd-fix-permissions" runs "install -dm700
    # $(DESTDIR)$(statedir)" with statedir=$(localstatedir)/lib/bluetooth.
    # ${localstatedir} is part of the default FILES:${PN}, so this empty
    # directory is packaged and ends up in the read-only EROFS rootfs.
    #
    # That breaks Bluetooth storage persistence: carlinkit_otalib calls
    # mount_persist_overlays() on every boot to point /var/lib/bluetooth at
    # /persist/c2a_bluetooth, but its unlink_if_exists() only calls unlink(),
    # which fails with EISDIR on a directory, so ensure_symlink() gives up
    # before creating the symlink.  BlueZ then keeps bonds, link keys and the
    # device cache in the volatile overlayfs upper layer, and a power cut
    # loses the pairing - the phone still holds the old bond, so the dongle
    # has to be forgotten and paired again.
    #
    # Keep the directory out of the image so that the symlink is created on
    # boot and BlueZ storage lands on the writable /persist (jffs2) partition.
    rmdir --ignore-fail-on-non-empty ${D}${localstatedir}/lib/bluetooth || true

    install -m 0755 ${UNPACKDIR}/bluetoothd-logged ${D}${libexecdir}/bluetooth/bluetoothd-logged
    sed -i -e "s#^DAEMON=.*#DAEMON=${libexecdir}/bluetooth/bluetoothd-logged#" ${D}${sysconfdir}/init.d/bluetooth
}
