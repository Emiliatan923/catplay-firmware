SUMMARY = "CatPlay wireless CarPlay dongle firmware for the RADXA ROCK 2A"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# The ROCK 2A hardware is covered by meta-rockchip (scarthgap-vendor):
#   machine            rockchip-rk3528-rock-2a
#   kernel             linux-rockchip 6.1 (radxa/kernel, rkr4.1 BSP)
#   bootloader         u-boot-rockchip (rk3528_defconfig + radxa/rkbin)
#   image layout       wic/generic-gptdisk.wks.in
# This image adds the CatPlay dongle payload on top of that BSP.
require recipes-core/images/core-image-minimal.bb

# Match the other CatPlay firmware targets: Dropbear listens on the device's
# LAN addresses and root logs in with an empty password. Host keys are generated
# on the device; no user/client key or build-machine identity is embedded.
IMAGE_FEATURES += "ssh-server-dropbear empty-root-password allow-empty-password allow-root-login"

IMAGE_INSTALL:append = " \
    kernel-modules \
    aic8800-usb-modprobe \
    rkwifibt-firmware-aic8800d80-usb \
    g-iphone \
    catplay \
    catplay-ap \
    catplay-bt-discoverable \
    catplay-ap0-link \
    catplay-ncm-link \
    catplay-persistent-logs \
    bluez5 \
    iw \
    hostapd \
    dnsmasq \
    iproute2 \
    util-linux-sfdisk \
"

# Headroom for the BlueZ pairing database plus hostapd/dnsmasq runtime state.
IMAGE_ROOTFS_EXTRA_SPACE = "131072"
