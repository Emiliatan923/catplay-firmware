SUMMARY = "CatPlay — CarPlay protocol implementation (c2a dongle daemon)"
DESCRIPTION = "The userspace daemon that implements the CarPlay dongle: USB \
gadget against the head unit, iAP2 over Bluetooth to the iPhone, and the \
AirPlay receiver the phone streams to over WiFi."
HOMEPAGE = "https://github.com/catplay-labs/catplay"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

# The source is a plain tree (no upstream git remote is fetched), produced from
# the rock2a-port branch with:
#     git archive --format=tar.gz -o catplay.tar.gz HEAD
# and dropped next to this recipe. This mirrors the reference firmware's
# create-src-bundle.sh mechanism.
# THISDIR is the recipe directory; ${LAYERDIR} is only defined while
# parsing layer.conf and is NOT available inside a recipe.
FILESEXTRAPATHS:prepend := "${THISDIR}/../../files/catplay-src:"

SRC_URI = " \
    file://catplay.tar.gz \
    file://catplay.conf \
    file://catplay-c2a.service \
"
S = "${WORKDIR}"

CARGO_SRC_DIR = "c2a/catplay_c2a"
inherit cargo pkgconfig systemd

# Bitbake 2.8.1 (scarthgap) has no network isolation for tasks -- there is no
# BB_TASK_NETWORK enforcement in the tree -- so cargo can fetch crates during
# do_compile. That lets us skip bitbake's crate vendoring, which would
# otherwise need a generated .inc for this dependency tree. This mirrors what
# the reference firmware does (see meta-carplay's c2a-rust-app.bbclass).
#
# The Cargo.lock is still shipped and respected; --frozen is dropped only
# because vendoring is off.
CARGO_DISABLE_BITBAKE_VENDORING = "1"
CARGO_BUILD_FLAGS:remove = "--frozen"
do_compile[network] = "1"

# Runtime libraries the daemon links against. These all come from
# meta-openembedded rather than the reference firmware's own copies.
DEPENDS = " \
    libyuv \
    x264 \
    pixman \
    dbus \
    openssl \
    libopus \
    libjpeg-turbo \
    alsa-lib \
    libusb1 \
    zlib \
"

# libyuv has no recipe in poky or meta-openembedded, so this layer ships one.
# libopus comes from meta-openembedded/meta-multimedia, which is in BBLAYERS.

# bindgen (used by x264-sys and friends) drives libclang, which does not know
# where the cross toolchain keeps its compiler-provided headers. Without help
# it fails on:
#     x264.h:44:10: fatal error: 'stdarg.h' file not found
# stdarg.h is not a libc header but a GCC builtin one, so pointing clang at the
# native sysroot's GCC include directory is the correct fix -- its contents
# (stdarg/stddef/stdbool) are compiler- and arch-independent by design.
do_compile:prepend() {
    gcc_inc=$(ls -d ${STAGING_LIBDIR_NATIVE}/*/gcc/*/*/include 2>/dev/null | head -1)
    if [ -n "$gcc_inc" ]; then
        export BINDGEN_EXTRA_CLANG_ARGS="-I$gcc_inc"
    fi
}

SYSTEMD_SERVICE:${PN} = "catplay-c2a.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# The daemon is useless without the USB gadget modules, and it drives the AP
# that catplay-ap owns, so those are hard runtime dependencies rather than
# image-level coincidences.
# Firmware comes from meta-rockchip's rkwifibt-firmware-aic8800d80-usb, which
# installs to /lib/firmware/aic8800D80/ -- the path the vendor kernel's in-tree
# aic8800 USB driver actually reads (it is built with CONFIG_PLATFORM_UBUNTU).
RDEPENDS:${PN} = " \
    g-iphone \
    catplay-ap \
    catplay-bt-discoverable \
    aic8800-usb-modprobe \
    rkwifibt-firmware-aic8800d80-usb \
    bluez5 \
    dbus \
"

do_install:append() {
    # Pairing identity and caches live here and must exist before first start.
    install -d ${D}${localstatedir}/lib/catplay

    install -d ${D}${sysconfdir}/catplay
    install -m 0644 ${WORKDIR}/catplay.conf ${D}${sysconfdir}/catplay/catplay.conf

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/catplay-c2a.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${localstatedir}/lib/catplay"

# Keep the release binary: the default cargo class output is what we want.
INSANE_SKIP:${PN} += "already-stripped"
