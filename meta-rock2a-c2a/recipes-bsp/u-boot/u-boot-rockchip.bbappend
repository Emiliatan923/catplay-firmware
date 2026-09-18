# Try a newer Radxa U-Boot for the ROCK 2A.
#
# The SDK pins SRCREV 3c60a711 on branch `next-dev-buildroot`, a Nov-2024 build.
# With it the SD card never initialises on the ROCK 2A:
#
#   MMC error: The cmd index is 17, ret is -110
#   Card did not respond to voltage select!
#   mmc_init: -95
#
# The boot chain itself is fine -- the ROM reads idblock.img and the SPL
# verifies ATF/OP-TEE/U-Boot and hands over -- and U-Boot SPL reads the very
# same card successfully. Only U-Boot proper fails to bring the card up.
#
# Evidence that this is a U-Boot problem rather than the device tree:
#   * Armbian boots from SD on this exact board and card, and its U-Boot
#     (a mid-2026 `2017.09_armbian-...` build) uses an `mmc@ffc30000` node
#     that is otherwise identical to ours.
#   * Its node carries NO vmmc-supply/vqmmc-supply either, so adding those is
#     not the fix. (An earlier revision of this bbappend added them as
#     dangling phandles, which is worse than leaving them out -- U-Boot's MMC
#     driver then fails the regulator lookup. Reverted.)
#   * The one real difference left is the clock phandles on that node
#     (0x57 vs our 0x56), i.e. a different node ordering in the DT.
#
# Radxa publishes a much newer tree; try it before investing further in
# patching the old one. The DT change is reverted: this is a pure SRCREV bump.
SRCREV = "15d04b1553794dedca4b998e293d0aa59f4e03c0"

# The newer revision lives on a different branch than the one the SDK pins, so
# the branch in SRC_URI has to move with it.
SRC_URI:remove = "git://github.com/radxa/u-boot.git;protocol=https;branch=next-dev-buildroot;"
SRC_URI:append = " git://github.com/radxa/u-boot.git;protocol=https;branch=next-dev-v2026.01;"

# meta-rockchip applies three patches that only make sense against the pinned
# Nov-2024 tree; on next-dev-v2026.01 the first already conflicts (it tries to
# create scripts/dtc/README, which the newer tree ships, and python3 dtoc
# support is upstream there). They are dropped rather than force-applied.
# Note: patch 0003 reverts -Werror, so if the newer tree trips on a warning the
# build will surface it -- fix the warning rather than re-adding that patch
# blindly.
# `inherit auto-patch` appends every *.patch found in PATCHPATH to SRC_URI from
# an anonymous python function, so they cannot be removed with SRC_URI:remove.
# Point PATCHPATH at a directory that does not exist: the class then adds
# nothing. (Bump it to a real directory if a patch is ever needed again.)
PATCHPATH = "${THISDIR}/u-boot-rockchip-no-patches"

# Keep the generic rk3528 defconfig -- it is the one that fits -- but switch its
# device tree to the ROCK 2A, which the newer U-Boot finally ships.
#
# Why not UBOOT_MACHINE = "rock-2a-rk3528_defconfig", which the tree provides?
# That config's SPL exceeds the 256 KB loader slot:
#     spl/u-boot-spl.bin exceeds file size limit:
#       limit:  262144 bytes
#       actual: 263737 bytes   (excess: 1593)
# The two defconfigs differ almost entirely in CONFIG_DEFAULT_DEVICE_TREE; the
# board config additionally enables CONFIG_SHA256 and drops
# CONFIG_SPL_SKIP_RELOCATE, which is what pushes it over. The ROCK 2A DT itself
# is what we actually need (its mmc@ffc30000 carries the SD rails and card
# detection), and it fits inside the generic config's budget.
do_configure:append() {
    local cfg="${B}/.config"

    [ -f "$cfg" ] || bbfatal "no .config to adjust at ${cfg}"

    sed -i -e 's/^CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="rk3528-rock-2a"/' "$cfg"
    sed -i -e 's|^CONFIG_OF_LIST=.*|CONFIG_OF_LIST="rk3528-rock-2a"|' "$cfg"

    # Disable the OP-TEE client. The ROCK 2A ships no OP-TEE in this boot chain
    # (BL31 reports "No OPTEE provided by BL2 boot loader"), so U-Boot aborts
    # early with:
    #     optee check api revision fail: -1.0
    #     optee api revision is too low
    #     ### ERROR ### Please RESET the board ###
    # The generic rk3528_defconfig leaves these off; the board defconfig turns
    # them on, which is part of why it also overflows the SPL slot.
    sed -i -e 's/^CONFIG_OPTEE_CLIENT=.*/# CONFIG_OPTEE_CLIENT is not set/' "$cfg"
    sed -i -e 's/^CONFIG_OPTEE_V2=.*/# CONFIG_OPTEE_V2 is not set/' "$cfg"
    sed -i -e 's/^CONFIG_OPTEE_ALWAYS_USE_SECURITY_PARTITION=.*/# CONFIG_OPTEE_ALWAYS_USE_SECURITY_PARTITION is not set/' "$cfg"

    # Re-run olddefconfig so the device tree change is validated and the
    # derived options are regenerated consistently.
    oe_runmake -C "${S}" O="${B}" olddefconfig

    grep -q 'CONFIG_DEFAULT_DEVICE_TREE="rk3528-rock-2a"' "$cfg" \
        || bbfatal "failed to select the ROCK 2A device tree"
}
