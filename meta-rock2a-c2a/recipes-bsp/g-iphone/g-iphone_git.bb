SUMMARY = "CatPlay USB gadget modules for the Apple-device CarPlay link"
DESCRIPTION = "Out-of-tree kernel modules implementing the CarPlay dongle USB \
gadget: g_iphone (the composite Apple device that enumerates as 05ac:12a8), \
iap2_char and iap2_scan. The Rockchip vendor kernel does not carry these, so \
the dongle protocol cannot work without them."
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit module

# The modules come from the same source bundle as the daemon, so a module and
# daemon built from one revision can never drift apart.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:${THISDIR}/../../files/catplay-src:"

SRC_URI = " \
    file://catplay.tar.gz \
    file://giphone-kernel61.patch \
    file://catplay-g-iphone.conf \
"
S = "${WORKDIR}/usb/catplay_iap2_usb_host/g_iphone"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# giphone-kernel61.patch carries two things the vendor 6.1 kernel needs:
#
#  1. struct usb_gadget_ops gained func_wakeup() and struct usb_function gained
#     func_wakeup_armed in Linux 6.6. The 6.1 vendor kernel predates both, so
#     the function-suspend remote-wakeup path is compiled out via a
#     IPHONE_HAVE_FUNC_WAKEUP guard in kver_compat.h. On 6.1 usb_func_wakeup()
#     returns -EOPNOTSUPP, which is exactly what the 6.6 code returns when the
#     UDC has no func_wakeup op.
#  2. The Makefile only had an `all:` target and hardcoded KDIR, so
#     `inherit module`'s "No rule to make target 'modules_install'" was
#     unavoidable. The patch makes KDIR follow KERNEL_SRC and adds the
#     `modules` / `modules_install` targets the module class drives.
#
# It also drops a genuinely unused variable that -Werror rejected.
COMPATIBLE_MACHINE = "rockchip-rk3528-rock-2a"

do_install:append() {
    # The dongle protocol needs all three modules; without them catplay_c2a
    # fails its gadget setup and never enumerates as 05ac:12a8. Order is
    # significant -- see the file itself.
    install -d ${D}${sysconfdir}/modules-load.d
    install -m 0644 ${WORKDIR}/catplay-g-iphone.conf ${D}${sysconfdir}/modules-load.d/
}

FILES:${PN} += "${sysconfdir}/modules-load.d/catplay-g-iphone.conf"
